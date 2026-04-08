import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'transport.dart';
import '../../shared/models/approval_request.dart';
import '../../shared/models/activity_item.dart';

/// Server transport — Socket.IO + JWT 远程中继模式
/// 连接到 sentinel-server (:3005)，通过 WebSocket 收发事件
class ServerTransport extends Transport {
  @override
  final ConnectionMode mode = ConnectionMode.server;

  sio.Socket? _socket;
  String? _serverUrl;
  String? _token;
  int _reconnectAttempts = 0;

  @override
  bool get isConnected => _socket?.connected ?? false;

  /// 设置服务器地址和 JWT token
  void configure(String serverUrl, {String? token}) {
    _serverUrl = serverUrl;
    _token = token;
  }

  @override
  Future<void> connect() async {
    if (_serverUrl == null) {
      throw StateError('No server URL. Call configure() first.');
    }

    disconnect();

    _socket = sio.io(
      _serverUrl!,
      sio.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setReconnectionAttempts(10)
          .setAuth(_token != null ? {'token': _token} : {})
          .build(),
    );

    final completer = Completer<void>();

    _socket!.onConnect((_) {
      _reconnectAttempts = 0;
      debugPrint('[Server] Connected to $_serverUrl');
      if (!completer.isCompleted) completer.complete();
    });

    _socket!.onConnectError((err) {
      debugPrint('[Server] Connect error: $err');
      if (!completer.isCompleted) completer.completeError(err);
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[Server] Disconnected: $reason');
    });

    // 事件监听
    _socket!.on('approval_request', (data) {
      try {
        final json = Map<String, dynamic>.from(data as Map);
        onRequest?.call(ApprovalRequest.fromJson(json));
      } catch (e) {
        debugPrint('[Server] Decode approval error: $e');
      }
    });

    _socket!.on('decision', (data) {
      // 服务端确认决策（如超时）
      final json = Map<String, dynamic>.from(data as Map);
      final requestId = json['requestId'] as String?;
      if (requestId != null) onDecisionSync?.call(requestId);
    });

    _socket!.on('decision_sync', (data) {
      final json = Map<String, dynamic>.from(data as Map);
      final requestId = json['requestId'] as String?;
      if (requestId != null) onDecisionSync?.call(requestId);
    });

    _socket!.on('activity', (data) {
      final json = Map<String, dynamic>.from(data as Map);
      onActivity?.call(ActivityItem.fromJson(json));
    });

    _socket!.on('terminal', (data) {
      final json = Map<String, dynamic>.from(data as Map);
      final text = json['text'] as String? ?? '';
      if (text.isNotEmpty) onTerminal?.call(text);
    });

    _socket!.on('heartbeat', (_) {
      _socket?.emit('heartbeat');
    });

    _socket!.connect();

    // 等待连接或超时
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Connection timeout'),
    );
  }

  @override
  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  @override
  void sendDecision(String requestId, Decision decision) {
    _socket?.emit('decision', {
      'requestId': requestId,
      'action': decision.value,
    });
  }

  @override
  void sendUserMessage(String text) {
    _socket?.emit('user_message', {'text': text});
  }
}
