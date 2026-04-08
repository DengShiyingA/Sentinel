import '../../shared/models/approval_request.dart';
import '../../shared/models/activity_item.dart';

/// Connection mode — persisted in SharedPreferences
enum ConnectionMode {
  lan('lan', '局域网', 'LAN Direct'),
  cloudkit('cloudkit', 'CloudKit', 'iCloud Sync'),
  server('server', '自建服务器', 'Self-hosted Server');

  final String value;
  final String labelZh;
  final String labelEn;
  const ConnectionMode(this.value, this.labelZh, this.labelEn);
}

/// Abstract transport interface — all modes implement this
abstract class Transport {
  ConnectionMode get mode;
  bool get isConnected;

  Future<void> connect();
  void disconnect();

  /// Send decision back to CLI
  void sendDecision(String requestId, Decision decision);

  /// Send user message to Claude Code
  void sendUserMessage(String text);

  /// Event callbacks
  void Function(ApprovalRequest)? onRequest;
  void Function(ActivityItem)? onActivity;
  void Function(String text)? onTerminal;
  void Function(String requestId)? onDecisionSync;
}
