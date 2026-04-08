/// 审批请求模型 — 对应 shared-types-protocol.ts ApprovalRequest

enum RiskLevel {
  requireConfirm('require_confirm'),
  requireFaceID('require_faceid');

  final String value;
  const RiskLevel(this.value);

  static RiskLevel fromString(String s) {
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

  /// Git-style diff 文本（Write/Edit 操作时由 CLI 生成）
  /// 为 null 表示无文件变更（如 Bash、Read 等）
  final String? diff;

  ApprovalRequest({
    required this.id,
    required this.toolName,
    required this.toolInput,
    required this.riskLevel,
    required this.timestamp,
    required this.macDeviceId,
    required this.timeoutAt,
    this.diff,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'] as String,
      toolName: json['toolName'] as String,
      toolInput: Map<String, dynamic>.from(json['toolInput'] ?? {}),
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String? ?? 'require_confirm'),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      macDeviceId: json['macDeviceId'] as String? ?? 'local',
      timeoutAt: DateTime.tryParse(json['timeoutAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(seconds: 120)),
      diff: json['diff'] as String?,
    );
  }

  bool get hasDiff => diff != null && diff!.trim().isNotEmpty;
  Duration get remaining => timeoutAt.difference(DateTime.now());
  bool get isExpired => remaining.isNegative;
}
