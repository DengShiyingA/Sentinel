enum RuleType {
  path('path', '路径规则'),
  tool('tool', '工具规则'),
  risk('risk', '风险等级');

  final String value;
  final String label;
  const RuleType(this.value, this.label);
}

enum RuleAction {
  autoAllow('auto_allow', '自动允许'),
  requireConfirm('require_confirm', '需要确认'),
  requireFaceID('require_faceid', '需要 Face ID'),
  block('block', '始终拒绝');

  final String value;
  final String label;
  const RuleAction(this.value, this.label);

  static RuleAction fromString(String s) =>
      RuleAction.values.firstWhere((e) => e.value == s, orElse: () => requireConfirm);
}

class Rule {
  final String id;
  final String? toolPattern;
  final String? pathPattern;
  final RuleAction action;
  final int priority;
  final String description;
  final bool isBuiltin;

  const Rule({
    required this.id,
    this.toolPattern,
    this.pathPattern,
    required this.action,
    this.priority = 100,
    required this.description,
    this.isBuiltin = false,
  });

  RuleType get type {
    if (toolPattern != null && pathPattern != null) return RuleType.path;
    if (pathPattern != null) return RuleType.path;
    return RuleType.tool;
  }

  Rule copyWith({
    String? toolPattern,
    String? pathPattern,
    RuleAction? action,
    int? priority,
    String? description,
  }) =>
      Rule(
        id: id,
        toolPattern: toolPattern ?? this.toolPattern,
        pathPattern: pathPattern ?? this.pathPattern,
        action: action ?? this.action,
        priority: priority ?? this.priority,
        description: description ?? this.description,
        isBuiltin: isBuiltin,
      );

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
        id: json['id'] as String? ?? '',
        toolPattern: json['toolPattern'] as String?,
        pathPattern: json['pathPattern'] as String?,
        action: RuleAction.fromString(json['risk'] as String? ?? json['action'] as String? ?? 'require_confirm'),
        priority: json['priority'] as int? ?? 100,
        description: json['description'] as String? ?? '',
        isBuiltin: json['isBuiltin'] as bool? ?? (json['id'] as String? ?? '').startsWith('builtin'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolPattern': toolPattern,
        'pathPattern': pathPattern,
        'risk': action.value,
        'priority': priority,
        'description': description,
      };
}
