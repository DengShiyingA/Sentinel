enum RiskLevel {
  requireConfirm('require_confirm'),
  requireFaceID('require_faceid');

  final String value;
  const RiskLevel(this.value);

  static RiskLevel fromString(String? s) {
    if (s == 'require_faceid' || s == 'high') return RiskLevel.requireFaceID;
    return RiskLevel.requireConfirm;
  }

  String get label => this == requireFaceID ? 'Face ID' : '需确认';
}

enum Decision {
  allowed('allowed'),
  blocked('blocked');

  final String value;
  const Decision(this.value);
}

class ApprovalRequest {
  final String id;
  final String toolName;
  final Map<String, dynamic> toolInput;
  final RiskLevel riskLevel;
  final DateTime timestamp;
  final String macDeviceId;
  final DateTime timeoutAt;
  final String? diff;

  const ApprovalRequest({
    required this.id,
    required this.toolName,
    this.toolInput = const {},
    this.riskLevel = RiskLevel.requireConfirm,
    required this.timestamp,
    this.macDeviceId = 'local',
    required this.timeoutAt,
    this.diff,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) => ApprovalRequest(
    id: json['id'] as String? ?? '',
    toolName: json['toolName'] as String? ?? 'unknown',
    toolInput: json['toolInput'] is Map ? Map<String, dynamic>.from(json['toolInput']) : const {},
    riskLevel: RiskLevel.fromString(json['riskLevel'] as String?),
    timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    macDeviceId: json['macDeviceId'] as String? ?? 'local',
    timeoutAt: DateTime.tryParse(json['timeoutAt']?.toString() ?? '') ?? DateTime.now().add(const Duration(seconds: 120)),
    diff: json['diff'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'toolName': toolName,
    'toolInput': toolInput,
    'riskLevel': riskLevel.value,
    'timestamp': timestamp.toIso8601String(),
    'macDeviceId': macDeviceId,
    'timeoutAt': timeoutAt.toIso8601String(),
    if (diff != null) 'diff': diff,
  };

  bool get hasDiff => diff != null && diff!.trim().isNotEmpty;
  Duration get remaining => timeoutAt.difference(DateTime.now());
  bool get isExpired => remaining.isNegative;
}
