import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../core/trust/temporary_trust.dart';
import '../../../shared/models/approval_request.dart';
import '../../../shared/utils/snackbar.dart';
import '../widgets/approval_card.dart';

class ApprovalListScreen extends ConsumerStatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  ConsumerState<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends ConsumerState<ApprovalListScreen> {
  bool _batchMode = false;
  final Set<String> _selected = {};
  bool _batchLoading = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(connectionProvider);

    return Scaffold(
      appBar: _batchMode ? _batchAppBar(s) : _normalAppBar(s),
      body: Column(
        children: [
          Expanded(child: _buildList(s)),
          if (_batchMode && _selected.isNotEmpty)
            _BatchBar(
              count: _selected.length,
              hasHighRisk: s.pendingRequests
                  .where((r) => _selected.contains(r.id))
                  .any((r) => r.riskLevel == RiskLevel.requireFaceID),
              loading: _batchLoading,
              onAllowAll: () => _batchDecision(Decision.allowed),
              onBlockAll: () => _batchDecision(Decision.blocked),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _normalAppBar(SentinelState s) {
    return AppBar(
      title: const Text('审批'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
              color: s.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(s.isConnected ? '已连接' : '未连接',
                style: Theme.of(context).textTheme.labelSmall),
          ]),
        ),
      ],
    );
  }

  PreferredSizeWidget _batchAppBar(SentinelState s) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _exitBatch),
      title: Text('已选择 ${_selected.length} 项'),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            if (_selected.length == s.pendingRequests.length) {
              _selected.clear();
            } else {
              _selected.addAll(s.pendingRequests.map((r) => r.id));
            }
          }),
          child: Text(_selected.length == s.pendingRequests.length ? '取消全选' : '全选'),
        ),
      ],
    );
  }

  Widget _buildList(SentinelState s) {
    if (s.pendingRequests.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: _batchMode ? 80 : 8),
      itemCount: s.pendingRequests.length,
      itemBuilder: (context, i) {
        final req = s.pendingRequests[i];
        final selected = _selected.contains(req.id);

        return GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            setState(() { _batchMode = true; _selected.add(req.id); });
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _batchMode ? 48 : 0,
                child: _batchMode
                    ? Checkbox(value: selected, onChanged: (_) => _toggle(req.id))
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: _batchMode
                    ? GestureDetector(
                        onTap: () => _toggle(req.id),
                        child: ApprovalCard(request: req, onAllow: () {}, onBlock: () {},
                            dimmed: !selected),
                      )
                    : ApprovalCard(
                        request: req,
                        onTap: () => context.go('/approval/detail/${req.id}'),
                        onAllow: () => _decide(req.id, Decision.allowed),
                        onBlock: () => _decide(req.id, Decision.blocked),
                        onTrust: (tool, prefix, dur) {
                          ref.read(trustProvider.notifier).addRule(
                              toolName: tool, pathPrefix: prefix, duration: dur);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggle(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    if (_selected.isEmpty) _batchMode = false;
  });

  void _exitBatch() => setState(() { _batchMode = false; _selected.clear(); });

  void _decide(String id, Decision d) {
    ref.read(connectionProvider.notifier).sendDecision(id, d);
    d == Decision.allowed ? showSuccess(context, '已允许') : showError(context, '已拒绝');
  }

  Future<void> _batchDecision(Decision d) async {
    if (_batchLoading) return;
    setState(() => _batchLoading = true);
    final ids = List<String>.from(_selected);
    for (final id in ids) {
      ref.read(connectionProvider.notifier).sendDecision(id, d);
      await Future.delayed(const Duration(milliseconds: 50));
    }
    HapticFeedback.heavyImpact();
    if (mounted) {
      d == Decision.allowed
          ? showSuccess(context, '已允许 ${ids.length} 项')
          : showError(context, '已拒绝 ${ids.length} 项');
    }
    setState(() { _batchLoading = false; _batchMode = false; _selected.clear(); });
  }
}

class _EmptyState extends StatefulWidget {
  const _EmptyState();

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shield_outlined, size: 72,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('没有待审批的请求', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Claude Code 的工具调用会出现在这里',
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ]),
        ),
      ),
    );
  }
}

class _BatchBar extends StatelessWidget {
  final int count;
  final bool hasHighRisk;
  final bool loading;
  final VoidCallback onAllowAll;
  final VoidCallback onBlockAll;

  const _BatchBar({
    required this.count, required this.hasHighRisk, required this.loading,
    required this.onAllowAll, required this.onBlockAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (hasHighRisk)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Text('包含高风险操作', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
            ]),
          ),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: loading ? null : onBlockAll,
            icon: const Icon(Icons.close, size: 18),
            label: Text('全部拒绝 ($count)'),
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12)),
          )),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(
            onPressed: loading ? null : onAllowAll,
            icon: const Icon(Icons.check, size: 18),
            label: Text('全部允许 ($count)'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          )),
        ]),
      ]),
    );
  }
}
