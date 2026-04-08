import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/approval_request.dart';
import '../../../core/auth/biometric_service.dart';
import '../../../shared/widgets/diff_viewer.dart';

/// 审批请求卡片 — 风险等级、意图摘要、Diff 预览、倒计时、操作按钮
/// 高风险操作点击"允许"自动触发 Face ID / Fingerprint 验证
class ApprovalCard extends StatelessWidget {
  final ApprovalRequest request;
  final VoidCallback onAllow;
  final VoidCallback onBlock;
  /// 多选模式下未选中的卡片半透明
  final bool dimmed;

  const ApprovalCard({
    super.key,
    required this.request,
    required this.onAllow,
    required this.onBlock,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighRisk = request.riskLevel == RiskLevel.requireFaceID;

    return AnimatedOpacity(
      opacity: dimmed ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== 风险横幅 ==========
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isHighRisk
                  ? theme.colorScheme.errorContainer
                  : Colors.orange.shade50,
            ),
            child: Row(
              children: [
                // 风险图标
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isHighRisk
                        ? theme.colorScheme.error.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _toolIcon(request.toolName),
                    color: isHighRisk ? theme.colorScheme.error : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),

                // 工具名 + 路径
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(request.toolName,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          // 风险标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isHighRisk
                                  ? theme.colorScheme.error
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isHighRisk ? 'Face ID' : '需确认',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (_filePath != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _filePath!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // 倒计时
                _CountdownRing(timeoutAt: request.timeoutAt),
              ],
            ),
          ),

          // ========== AI 意图摘要 ==========
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              _intentSummary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // ========== Diff 预览（仅 Write/Edit 有 diff 时显示）==========
          CollapsibleDiff(diff: request.diff),

          // ========== 操作按钮 ==========
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 拒绝
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      onBlock();
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('拒绝'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 允许（高风险需生物识别）
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _handleAllow(context, isHighRisk),
                    icon: Icon(isHighRisk ? Icons.fingerprint : Icons.check, size: 18),
                    label: const Text('允许'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  /// 允许操作 — 高风险自动触发生物识别
  Future<void> _handleAllow(BuildContext context, bool isHighRisk) async {
    HapticFeedback.mediumImpact();
    if (isHighRisk) {
      final ok = await BiometricService.authenticate(
        reason: '验证身份以允许高风险操作: ${request.toolName}',
      );
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('生物识别验证失败'), duration: Duration(seconds: 2)),
          );
        }
        return;
      }
    }
    onAllow();
  }

  /// 工具名 → 文件路径
  String? get _filePath =>
      request.toolInput['file_path'] as String? ??
      request.toolInput['command'] as String? ??
      request.toolInput['path'] as String?;

  /// 生成 AI 意图摘要
  String get _intentSummary {
    final tool = request.toolName.toLowerCase();
    final path = _filePath ?? '';
    if (tool.contains('write')) return 'Claude 想写入文件 $path';
    if (tool.contains('edit')) return 'Claude 想编辑文件 $path';
    if (tool.contains('bash')) return 'Claude 想执行命令: $path';
    if (tool.contains('read')) return 'Claude 想读取文件 $path';
    if (tool.contains('delete')) return 'Claude 想删除 $path';
    return 'Claude 想调用 ${request.toolName}';
  }

  /// 工具名 → 图标
  IconData _toolIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('write') || n.contains('edit')) return Icons.edit_document;
    if (n.contains('bash') || n.contains('terminal')) return Icons.terminal;
    if (n.contains('read')) return Icons.description;
    if (n.contains('delete') || n.contains('rm')) return Icons.delete_outline;
    if (n.contains('grep') || n.contains('glob')) return Icons.search;
    return Icons.build_outlined;
  }
}

/// 倒计时圆环 — 120s → 0
class _CountdownRing extends StatefulWidget {
  final DateTime timeoutAt;
  const _CountdownRing({required this.timeoutAt});

  @override
  State<_CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<_CountdownRing> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.timeoutAt.difference(DateTime.now()).inSeconds;
    final secs = remaining.clamp(0, 120);
    final progress = secs / 120.0;
    final color = secs > 60
        ? Colors.green
        : secs > 30
            ? Colors.orange
            : Colors.red;

    return SizedBox(
      width: 48, height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '$secs',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
