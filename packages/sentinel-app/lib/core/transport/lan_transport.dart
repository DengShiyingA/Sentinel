import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'transport.dart';
import '../../shared/models/approval_request.dart';
import '../../shared/models/activity_item.dart';

/// LAN transport — TCP direct connection + mDNS discovery.
/// Connects to sentinel-cli on port 7750 via raw TCP.
/// Messages are newline-delimited JSON.
class LanTransport extends Transport {
  @override
  final ConnectionMode mode = ConnectionMode.lan;

  Socket? _socket;
  String _buffer = '';
  String? _host;
  int _port = 7750;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  @override
  bool get isConnected => _socket != null;

  /// Connect to host:port (manual entry or from mDNS discovery)
  Future<void> connectTo(String host, int port) async {
    _host = host;
    _port = port;
    await connect();
  }

  @override
  Future<void> connect() async {
    if (_host == null) {
      throw StateError('No host set. Call connectTo() or discover first.');
    }

    disconnect();

    try {
      _socket = await Socket.connect(_host!, _port,
          timeout: const Duration(seconds: 5));
      _reconnectAttempts = 0;
      _buffer = '';

      debugPrint('[LAN] Connected to $_host:$_port');

      _socket!.listen(
        (data) {
          _buffer += utf8.decode(data);
          _processBuffer();
        },
        onError: (error) {
          debugPrint('[LAN] Socket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('[LAN] Socket closed');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('[LAN] Connect failed: $e');
      _scheduleReconnect();
      rethrow;
    }
  }

  @override
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socket?.destroy();
    _socket = null;
    _buffer = '';
  }

  @override
  void sendDecision(String requestId, Decision decision) {
    _send('decision', {'requestId': requestId, 'action': decision.value});
  }

  @override
  void sendUserMessage(String text) {
    _send('user_message', {'text': text});
  }

  // ==================== Private ====================

  void _send(String event, Map<String, dynamic> data) {
    if (_socket == null) return;
    final msg = jsonEncode({'event': event, 'data': data});
    _socket!.write('$msg\n');
  }

  void _processBuffer() {
    while (_buffer.contains('\n')) {
      final idx = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx);
      _buffer = _buffer.substring(idx + 1);

      if (line.trim().isEmpty) continue;

      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        _handleMessage(json);
      } catch (e) {
        debugPrint('[LAN] Parse error: $e');
      }
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final event = msg['event'] as String?;
    final data = msg['data'] as Map<String, dynamic>? ?? {};

    switch (event) {
      case 'handshake':
        debugPrint('[LAN] Handshake received (v${data['version']})');
        break;

      case 'approval_request':
        try {
          final request = ApprovalRequest.fromJson(data);
          onRequest?.call(request);
        } catch (e) {
          debugPrint('[LAN] Decode approval error: $e');
        }
        break;

      case 'activity':
        final item = ActivityItem.fromJson(data);
        onActivity?.call(item);
        break;

      case 'terminal':
        final text = data['text'] as String? ?? '';
        if (text.isNotEmpty) onTerminal?.call(text);
        break;

      case 'notification':
        final title = data['title'] as String? ?? 'Sentinel';
        final message = data['message'] as String? ?? '';
        debugPrint('[LAN] Notification: $title — $message');
        onActivity?.call(ActivityItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: ActivityType.notification,
          summary: message,
          timestamp: DateTime.now(),
          message: '$title: $message',
        ));
        break;

      case 'decision_sync':
        final requestId = data['requestId'] as String?;
        if (requestId != null) onDecisionSync?.call(requestId);
        break;
    }
  }

  void _handleDisconnect() {
    _socket = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_host == null || _reconnectAttempts >= 10) return;
    _reconnectAttempts++;
    final delay = Duration(
      seconds: [1, 2, 4, 8, 16, 30, 30, 30, 30, 30][_reconnectAttempts - 1],
    );
    debugPrint('[LAN] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      connect().catchError((_) {});
    });
  }
}
