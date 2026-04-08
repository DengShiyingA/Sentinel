import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'transport.dart';
import 'lan_transport.dart';
import '../../shared/models/approval_request.dart';
import '../../shared/models/activity_item.dart';

/// Global connection state
class ConnectionState {
  final ConnectionMode mode;
  final bool isConnected;
  final String? error;
  final String? host;

  const ConnectionState({
    this.mode = ConnectionMode.lan,
    this.isConnected = false,
    this.error,
    this.host,
  });

  ConnectionState copyWith({
    ConnectionMode? mode,
    bool? isConnected,
    String? error,
    String? host,
  }) {
    return ConnectionState(
      mode: mode ?? this.mode,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      host: host ?? this.host,
    );
  }
}

/// Central connection + approval + activity state manager
class ConnectionNotifier extends Notifier<ConnectionState> {
  Transport? _transport;

  // Approval state
  final List<ApprovalRequest> pendingRequests = [];
  final List<ActivityItem> activityFeed = [];
  final List<TerminalLine> terminalLines = [];
  int resolvedCount = 0;
  int newActivityCount = 0;

  @override
  ConnectionState build() {
    _loadMode();
    return const ConnectionState();
  }

  Transport? get transport => _transport;

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('sentinel.connectionMode') ?? 'lan';
    final mode = ConnectionMode.values.firstWhere(
      (m) => m.value == modeStr,
      orElse: () => ConnectionMode.lan,
    );
    state = state.copyWith(mode: mode);
  }

  /// Switch connection mode
  Future<void> switchMode(ConnectionMode mode) async {
    _transport?.disconnect();
    _transport = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sentinel.connectionMode', mode.value);

    state = state.copyWith(mode: mode, isConnected: false, error: null);
  }

  /// Connect via LAN (manual host:port)
  Future<void> connectLan(String host, int port) async {
    _transport?.disconnect();

    final lan = LanTransport();
    _wireCallbacks(lan);
    _transport = lan;

    state = state.copyWith(error: null);

    try {
      await lan.connectTo(host, port);
      state = state.copyWith(isConnected: true, host: host);
    } catch (e) {
      state = state.copyWith(isConnected: false, error: e.toString());
    }
  }

  /// Disconnect
  void disconnect() {
    _transport?.disconnect();
    _transport = null;
    state = state.copyWith(isConnected: false);
  }

  /// Send decision
  void sendDecision(String requestId, Decision decision) {
    _transport?.sendDecision(requestId, decision);
    pendingRequests.removeWhere((r) => r.id == requestId);
    resolvedCount++;
    ref.notifyListeners();
  }

  /// Send user message
  void sendUserMessage(String text) {
    _transport?.sendUserMessage(text);
    activityFeed.insert(
      0,
      ActivityItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ActivityType.userMessage,
        summary: text,
        timestamp: DateTime.now(),
        message: text,
      ),
    );
    ref.notifyListeners();
  }

  void clearNewActivity() {
    newActivityCount = 0;
    ref.notifyListeners();
  }

  void clearTerminal() {
    terminalLines.clear();
    ref.notifyListeners();
  }

  // ==================== Callback Wiring ====================

  void _wireCallbacks(Transport t) {
    t.onRequest = (request) {
      if (!pendingRequests.any((r) => r.id == request.id)) {
        pendingRequests.insert(0, request);
        ref.notifyListeners();
      }
      // TODO: local notification
    };

    t.onActivity = (item) {
      activityFeed.insert(0, item);
      if (activityFeed.length > 50) activityFeed.removeLast();
      newActivityCount++;
      ref.notifyListeners();
    };

    t.onTerminal = (text) {
      terminalLines.add(TerminalLine(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        timestamp: DateTime.now(),
      ));
      if (terminalLines.length > 500) terminalLines.removeAt(0);
      ref.notifyListeners();
    };

    t.onDecisionSync = (requestId) {
      pendingRequests.removeWhere((r) => r.id == requestId);
      resolvedCount++;
      ref.notifyListeners();
    };
  }
}

/// Provider
final connectionProvider =
    NotifierProvider<ConnectionNotifier, ConnectionState>(
  ConnectionNotifier.new,
);
