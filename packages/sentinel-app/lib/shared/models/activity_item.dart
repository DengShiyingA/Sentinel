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

  static ActivityType fromString(String? s) =>
      ActivityType.values.firstWhere((e) => e.value == s, orElse: () => toolCompleted);
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final String summary;
  final String? toolName;
  final DateTime timestamp;
  final String? stopReason;
  final String? message;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.summary,
    this.toolName,
    required this.timestamp,
    this.stopReason,
    this.message,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    type: ActivityType.fromString(json['type'] as String?),
    summary: json['summary'] as String? ?? json['message'] as String? ?? '',
    toolName: json['toolName'] as String?,
    timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    stopReason: json['stopReason'] as String?,
    message: json['message'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'summary': summary,
    if (toolName != null) 'toolName': toolName,
    'timestamp': timestamp.toIso8601String(),
    if (stopReason != null) 'stopReason': stopReason,
    if (message != null) 'message': message,
  };

  bool get isError => stopReason == 'error';
}

class TerminalLine {
  final String id;
  final String text;
  final DateTime timestamp;

  const TerminalLine({required this.id, required this.text, required this.timestamp});
}
