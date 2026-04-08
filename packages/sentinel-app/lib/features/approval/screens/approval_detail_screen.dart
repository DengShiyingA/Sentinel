import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../core/auth/biometric_service.dart';
import '../../../shared/models/approval_request.dart';
import '../../../shared/widgets/diff_viewer.dart';

class ApprovalDetailScreen extends ConsumerWidget {
  final String requestId;

  const ApprovalDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(connectionProvider);
    final request = s.pendingRequests.where((r) => r.id == requestId).firstOrNull;

    if (request == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('请求已处理或已过期')),
      );
    }

    final theme = Theme.of(context);
    final isHighRisk = request.riskLevel == RiskLevel.requireFaceID;

    return Scaffold(
      appBar: AppBar(
        title: Text(request.toolName),
        actions: [
          _CountdownChip(timeoutAt: request.timeoutAt),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _RiskBanner(request: request, isHighRisk: isHighRisk),
          _InfoSection(request: request),
          _ParamsSection(request: request),
          if (request.hasDiff) _DiffSection(diff: request.diff!),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        isHighRisk: isHighRisk,
        onAllow: () => _allow(context, ref, request, isHighRisk),
        onBlock: () => _block(context, ref, request),
      ),
    );
  }

  Future<void> _allow(BuildContext ctx, WidgetRef ref, ApprovalRequest req, bool high) async {
    if (high) {
      final ok = await BiometricService.authenticate(reason: '验证身份以允许高风险操作');
      if (!ok) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('验证失败'), backgroundColor: Colors.red));
        }
        return;
      }
    }
    HapticFeedback.mediumImpact();
    ref.read(connectionProvider.notifier).sendDecision(req.id, Decision.allowed);
    if (ctx.mounted) Navigator.of(ctx).pop();
  }

  void _block(BuildContext ctx, WidgetRef ref, ApprovalRequest req) {
    HapticFeedback.heavyImpact();
    ref.read(connectionProvider.notifier).sendDecision(req.id, Decision.blocked);
    if (ctx.mounted) Navigator.of(ctx).pop();
  }
}

class _RiskBanner extends StatelessWidget {
  final ApprovalRequest request;
  final bool isHighRisk;

  const _RiskBanner({required this.request, required this.isHighRisk});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isHighRisk
          ? Theme.of(context).colorScheme.errorContainer
          : Colors.orange.shade50,
      child: Row(
        children: [
          Icon(
            isHighRisk ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isHighRisk ? Theme.of(context).colorScheme.error : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHighRisk ? '高风险操作 · 需要 Face ID' : '中等风险 · 需要确认',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _intent(request),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _intent(ApprovalRequest r) {
    final path = r.toolInput['file_path'] ?? r.toolInput['command'] ?? '';
    final t = r.toolName.toLowerCase();
    if (t.contains('write')) return 'Claude 想写入 $path';
    if (t.contains('edit')) return 'Claude 想编辑 $path';
    if (t.contains('bash')) return 'Claude 想执行 $path';
    return 'Claude 想调用 ${r.toolName}';
  }
}

class _InfoSection extends StatelessWidget {
  final ApprovalRequest request;
  const _InfoSection({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = request.toolInput['file_path'] as String? ??
        request.toolInput['command'] as String? ?? '—';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _row(theme, '工具', request.toolName),
          const Divider(height: 24),
          _row(theme, '目标', path, mono: true),
          const Divider(height: 24),
          _row(theme, '风险', request.riskLevel.label),
          const Divider(height: 24),
          _row(theme, '时间', _fmt(request.timestamp)),
          const Divider(height: 24),
          _row(theme, '来源', request.macDeviceId),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value, {bool mono = false}) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline)),
        ),
        Expanded(
          child: Text(value,
            style: mono
                ? theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace')
                : theme.textTheme.bodyMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}

class _ParamsSection extends StatelessWidget {
  final ApprovalRequest request;
  const _ParamsSection({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final json = const JsonEncoder.withIndent('  ').convert(request.toolInput);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('参数', style: theme.textTheme.titleSmall),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              json,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DiffSection extends StatelessWidget {
  final String diff;
  const _DiffSection({required this.diff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: true,
        title: Text('文件变更', style: Theme.of(context).textTheme.titleSmall),
        children: [
          DiffViewer(diff: diff),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isHighRisk;
  final VoidCallback onAllow;
  final VoidCallback onBlock;

  const _ActionBar({required this.isHighRisk, required this.onAllow, required this.onBlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onBlock,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('拒绝'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onAllow,
              icon: Icon(isHighRisk ? Icons.fingerprint : Icons.check, size: 18),
              label: const Text('允许'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final DateTime timeoutAt;
  const _CountdownChip({required this.timeoutAt});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final secs = timeoutAt.difference(DateTime.now()).inSeconds.clamp(0, 999);
        return Chip(
          label: Text('${secs}s',
              style: TextStyle(fontWeight: FontWeight.bold,
                  color: secs < 30 ? Colors.red : null)),
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
