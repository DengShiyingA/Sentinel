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
  final bool dimmed;
  final void Function(String tool, String? pathPrefix, Duration dur)? onTrust;
  final VoidCallback? onTap;

  const ApprovalCard({
    super.key,
    required this.request,
    required this.onAllow,
    required this.onBlock,
    this.dimmed = false,
    this.onTrust,
    this.onTap,
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
      child: InkWell(
      onTap: onTap,
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
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
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
                const SizedBox(width: 8),
                // 允许
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
          // ========== 信任菜单（非高风险时显示）==========
          if (onTrust != null && !isHighRisk)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _TrustMenu(
                toolName: request.toolName,
                filePath: _filePath,
                onTrust: onTrust!,
                onAllow: onAllow,
              ),
            ),
        ],
      ),
    ))));
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

/// "允许并信任" 下拉菜单
class _TrustMenu extends StatelessWidget {
  final String toolName;
  final String? filePath;
  final void Function(String tool, String? pathPrefix, Duration dur) onTrust;
  final VoidCallback onAllow;

  const _TrustMenu({
    required this.toolName,
    this.filePath,
    required this.onTrust,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    // 提取路径前缀（如 /src/components/ → /src/components/）
    final prefix = _extractPrefix(filePath);

    return PopupMenuButton<_TrustOption>(
      onSelected: (option) {
        // 先允许当前请求
        onAllow();
        // 添加临时信任规则
        onTrust(
          option.matchAll ? '*' : toolName,
          option.matchPath ? prefix : null,
          option.duration,
        );
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('已信任: ${option.label}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _TrustOption('$toolName 5分钟', const Duration(minutes: 5)),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.timer, size: 18),
            title: Text('信任 $toolName 5 分钟'),
          ),
        ),
        PopupMenuItem(
          value: _TrustOption('$toolName 15分钟', const Duration(minutes: 15)),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.timer, size: 18),
            title: Text('信任 $toolName 15 分钟'),
          ),
        ),
        PopupMenuItem(
          value: _TrustOption('$toolName 30分钟', const Duration(minutes: 30)),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.timer, size: 18),
            title: Text('信任 $toolName 30 分钟'),
          ),
        ),
        if (prefix != null)
          PopupMenuItem(
            value: _TrustOption('$toolName $prefix* 15分钟', const Duration(minutes: 15), matchPath: true),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.folder_open, size: 18),
              title: Text('信任 $prefix* 15 分钟'),
              subtitle: Text('仅 $toolName', style: const TextStyle(fontSize: 11)),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _TrustOption('全部工具 5分钟', const Duration(minutes: 5), matchAll: true),
          child: const ListTile(
            dense: true,
            leading: Icon(Icons.security, size: 18),
            title: Text('信任全部工具 5 分钟'),
            subtitle: Text('仅限低风险操作', style: TextStyle(fontSize: 11)),
          ),
        ),
      ],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 14,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text('允许并信任...',
              style: TextStyle(fontSize: 12,
                  color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  /// 提取目录前缀（/src/utils/helper.ts → /src/utils/）
  String? _extractPrefix(String? path) {
    if (path == null || !path.contains('/')) return null;
    final lastSlash = path.lastIndexOf('/');
    return path.substring(0, lastSlash + 1);
  }
}

class _TrustOption {
  final String label;
  final Duration duration;
  final bool matchPath;
  final bool matchAll;

  _TrustOption(this.label, this.duration, {this.matchPath = false, this.matchAll = false});
}
