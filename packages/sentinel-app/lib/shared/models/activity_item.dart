/// Activity events from Claude Code (PostToolUse, Notification, Stop, etc.)
enum ActivityType {
  toolCompleted('tool_completed'),
  notification('notification'),
  stop('stop'),
  taskCompleted('task_completed'),
  sessionEnded('session_ended'),
  userMessage('user_message'),
  claudeResponse('claude_response'),
  claudeStatus('claude_status'),
  terminal('terminal');

  final String value;
  const ActivityType(this.value);

  static ActivityType fromString(String s) {
    return ActivityType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => ActivityType.toolCompleted,
    );
  }
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final String summary;
  final String? toolName;
  final DateTime timestamp;
  final String? stopReason;
  final String? message;

  ActivityItem({
    required this.id,
    required this.type,
    required this.summary,
    this.toolName,
    required this.timestamp,
    this.stopReason,
    this.message,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: ActivityType.fromString(json['type'] as String? ?? ''),
      summary: json['summary'] as String? ?? json['message'] as String? ?? '',
      toolName: json['toolName'] as String?,
      timestamp: DateTime.now(),
      stopReason: json['stopReason'] as String?,
      message: json['message'] as String?,
    );
  }

  bool get isError => stopReason == 'error';
}

/// Terminal output line
class TerminalLine {
  final String id;
  final String text;
  final DateTime timestamp;

  TerminalLine({required this.id, required this.text, required this.timestamp});
}
