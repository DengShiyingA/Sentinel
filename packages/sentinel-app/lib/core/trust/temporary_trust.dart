import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/approval_request.dart';

/// 临时信任规则 — "在 X 分钟内自动允许同类操作"
class TrustRule {
  final String id;
  final String toolName;         // 匹配的工具名（如 "Write", "*" 表示全部）
  final String? pathPrefix;      // 路径前缀匹配（如 "/src/"），null 表示全部路径
  final DateTime expiresAt;      // 过期时间
  final String label;            // 显示文本："Write /src/* 15分钟"

  TrustRule({
    required this.id,
    required this.toolName,
    this.pathPrefix,
    required this.expiresAt,
    required this.label,
  });

  /// 是否已过期
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 剩余秒数
  int get remainingSeconds => expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 999999);

  /// 检查是否匹配给定的审批请求
  bool matches(ApprovalRequest request) {
    if (isExpired) return false;

    // 工具名匹配
    if (toolName != '*' && toolName != request.toolName) return false;

    // 路径匹配
    if (pathPrefix != null) {
      final filePath = request.toolInput['file_path'] as String? ??
          request.toolInput['path'] as String? ?? '';
      if (!filePath.startsWith(pathPrefix!)) return false;
    }

    return true;
  }
}

/// 临时信任状态
class TrustState {
  final List<TrustRule> rules;
  /// 最近一次自动允许的请求数
  final int autoAllowedCount;

  const TrustState({this.rules = const [], this.autoAllowedCount = 0});

  TrustState copyWith({List<TrustRule>? rules, int? autoAllowedCount}) {
    return TrustState(
      rules: rules ?? this.rules,
      autoAllowedCount: autoAllowedCount ?? this.autoAllowedCount,
    );
  }

  /// 当前生效（未过期）的规则
  List<TrustRule> get activeRules => rules.where((r) => !r.isExpired).toList();
}

/// 临时信任 Notifier — 管理临时信任规则的增删、自动过期清理、匹配检查
class TrustNotifier extends Notifier<TrustState> {
  Timer? _cleanupTimer;

  @override
  TrustState build() {
    // 每 10 秒清理过期规则
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) => _cleanup());
    ref.onDispose(() => _cleanupTimer?.cancel());
    return const TrustState();
  }

  /// 添加临时信任规则
  void addRule({
    required String toolName,
    String? pathPrefix,
    required Duration duration,
  }) {
    final label = _buildLabel(toolName, pathPrefix, duration);
    final rule = TrustRule(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      toolName: toolName,
      pathPrefix: pathPrefix,
      expiresAt: DateTime.now().add(duration),
      label: label,
    );

    state = state.copyWith(rules: [...state.rules, rule]);
    debugPrint('[Trust] Added: $label');
  }

  /// 移除指定规则
  void removeRule(String id) {
    state = state.copyWith(
      rules: state.rules.where((r) => r.id != id).toList(),
    );
  }

  /// 清除所有规则
  void clearAll() {
    state = const TrustState();
  }

  /// 检查请求是否命中临时信任 — 如果命中返回 true
  bool checkAndAutoAllow(ApprovalRequest request) {
    // 高风险操作不走临时信任（secrets、rm -rf 等必须每次验证）
    if (_isDangerousPath(request)) return false;

    for (final rule in state.activeRules) {
      if (rule.matches(request)) {
        state = state.copyWith(autoAllowedCount: state.autoAllowedCount + 1);
        debugPrint('[Trust] Auto-allowed: ${request.toolName} by rule "${rule.label}"');
        return true;
      }
    }
    return false;
  }

  /// 清理过期规则
  void _cleanup() {
    final active = state.rules.where((r) => !r.isExpired).toList();
    if (active.length != state.rules.length) {
      state = state.copyWith(rules: active);
    }
  }

  /// 检查是否为绝对危险路径（不允许临时信任）
  bool _isDangerousPath(ApprovalRequest request) {
    final path = (request.toolInput['file_path'] as String? ?? '').toLowerCase();
    final cmd = (request.toolInput['command'] as String? ?? '').toLowerCase();

    if (path.contains('.env') || path.contains('secret') || path.contains('credential')) {
      return true;
    }
    if (cmd.contains('rm -rf') || cmd.contains('sudo') || cmd.contains('chmod')) {
      return true;
    }
    return false;
  }

  String _buildLabel(String tool, String? prefix, Duration dur) {
    final toolLabel = tool == '*' ? '全部工具' : tool;
    final pathLabel = prefix != null ? ' $prefix*' : '';
    final durLabel = dur.inMinutes >= 60
        ? '${dur.inHours}小时'
        : '${dur.inMinutes}分钟';
    return '$toolLabel$pathLabel $durLabel';
  }
}

/// Provider
final trustProvider = NotifierProvider<TrustNotifier, TrustState>(TrustNotifier.new);
