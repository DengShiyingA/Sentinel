import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../shared/models/approval_request.dart';
import '../../../shared/models/activity_item.dart';
import '../../../core/trust/temporary_trust.dart';
import '../widgets/approval_card.dart';
import '../../../shared/utils/snackbar.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ========== 多选模式状态 ==========
  bool _batchMode = false;
  final Set<String> _selected = {};
  bool _batchLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(connectionProvider);

    return Scaffold(
      appBar: _batchMode ? _batchAppBar(s) : _normalAppBar(s),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPending(s),
                _TerminalTab(lines: s.terminalLines),
                _HistoryTab(feed: s.activityFeed),
              ],
            ),
          ),
          // 底部批量操作栏
          if (_batchMode && _selected.isNotEmpty)
            _BatchActionBar(
              count: _selected.length,
              hasHighRisk: _hasHighRiskSelected(s),
              loading: _batchLoading,
              onAllowAll: () => _batchDecision(Decision.allowed),
              onBlockAll: () => _batchDecision(Decision.blocked),
              onCancel: _exitBatchMode,
            ),
        ],
      ),
    );
  }

  // ==================== AppBar ====================

  PreferredSizeWidget _normalAppBar(SentinelState s) {
    return AppBar(
      title: const Text('Sentinel'),
      actions: [_connectionBadge(s)],
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: '待审批 ${s.pendingRequests.isEmpty ? '' : '(${s.pendingRequests.length})'}'),
          const Tab(text: '终端'),
          Tab(text: '历史 ${s.activityFeed.isEmpty ? '' : '(${s.activityFeed.length})'}'),
        ],
      ),
    );
  }

  /// 多选模式 AppBar — 显示已选数量 + 全选/取消
  PreferredSizeWidget _batchAppBar(SentinelState s) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitBatchMode,
      ),
      title: Text('已选择 ${_selected.length} 项'),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              if (_selected.length == s.pendingRequests.length) {
                _selected.clear();
              } else {
                _selected.addAll(s.pendingRequests.map((r) => r.id));
              }
            });
          },
          child: Text(
            _selected.length == s.pendingRequests.length ? '取消全选' : '全选',
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: '待审批 (${s.pendingRequests.length})'),
          const Tab(text: '终端'),
          const Tab(text: '历史'),
        ],
      ),
    );
  }

  Widget _connectionBadge(SentinelState s) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8,
            decoration: BoxDecoration(
              color: s.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(s.isConnected ? '已连接' : '未连接',
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  // ==================== 待审批列表（支持多选）====================

  Widget _buildPending(SentinelState s) {
    if (s.pendingRequests.isEmpty) {
      return _EmptyState(
        icon: Icons.shield_outlined,
        title: '没有待审批的请求',
        subtitle: 'Claude Code 的工具调用会出现在这里',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: _batchMode ? 80 : 8),
      itemCount: s.pendingRequests.length,
      itemBuilder: (context, index) {
        final req = s.pendingRequests[index];
        final isSelected = _selected.contains(req.id);

        return GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _batchMode = true;
              _selected.add(req.id);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                // 多选 Checkbox（动画滑入）
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _batchMode ? 48 : 0,
                  child: _batchMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(req.id),
                        )
                      : const SizedBox.shrink(),
                ),
                // 卡片
                Expanded(
                  child: _batchMode
                      ? GestureDetector(
                          onTap: () => _toggleSelection(req.id),
                          child: ApprovalCard(
                            request: req,
                            onAllow: () {},
                            onBlock: () {},
                            dimmed: _batchMode && !isSelected,
                          ),
                        )
                      : ApprovalCard(
                          request: req,
                          onAllow: () => _handleDecision(req.id, Decision.allowed),
                          onBlock: () => _handleDecision(req.id, Decision.blocked),
                          onTap: () => context.go('/approval/detail/${req.id}'),
                          onTrust: (tool, prefix, dur) {
                            ref.read(trustProvider.notifier).addRule(
                              toolName: tool,
                              pathPrefix: prefix,
                              duration: dur,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== 操作方法 ====================

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _batchMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _exitBatchMode() {
    setState(() {
      _batchMode = false;
      _selected.clear();
    });
  }

  bool _hasHighRiskSelected(SentinelState s) {
    return s.pendingRequests
        .where((r) => _selected.contains(r.id))
        .any((r) => r.riskLevel == RiskLevel.requireFaceID);
  }

  /// 单个审批决策
  void _handleDecision(String requestId, Decision decision) {
    ref.read(connectionProvider.notifier).sendDecision(requestId, decision);
    if (decision == Decision.allowed) {
      showSuccess(context, '已允许');
    } else {
      showError(context, '已拒绝');
    }
  }

  /// 批量审批决策
  Future<void> _batchDecision(Decision decision) async {
    if (_batchLoading) return;
    setState(() => _batchLoading = true);

    final notifier = ref.read(connectionProvider.notifier);
    final ids = List<String>.from(_selected);
    final isAllow = decision == Decision.allowed;

    // 逐个发送决策（后端暂不支持批量接口）
    for (final id in ids) {
      notifier.sendDecision(id, decision);
      await Future.delayed(const Duration(milliseconds: 50)); // 避免拥塞
    }

    HapticFeedback.heavyImpact();

    if (mounted) {
      if (isAllow) {
        showSuccess(context, '已允许 ${ids.length} 项');
      } else {
        showError(context, '已拒绝 ${ids.length} 项');
      }
    }

    setState(() {
      _batchLoading = false;
      _batchMode = false;
      _selected.clear();
    });
  }
}

// ==================== 底部批量操作栏 ====================

class _BatchActionBar extends StatelessWidget {
  final int count;
  final bool hasHighRisk;
  final bool loading;
  final VoidCallback onAllowAll;
  final VoidCallback onBlockAll;
  final VoidCallback onCancel;

  const _BatchActionBar({
    required this.count,
    required this.hasHighRisk,
    required this.loading,
    required this.onAllowAll,
    required this.onBlockAll,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 高风险提示
          if (hasHighRisk)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text('包含高风险操作，请谨慎审批',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                ],
              ),
            ),
          // 按钮行
          Row(
            children: [
              // 全部拒绝
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onBlockAll,
                  icon: loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.close, size: 18),
                  label: Text('全部拒绝 ($count)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 全部允许
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : onAllowAll,
                  icon: loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: Text('全部允许 ($count)'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== 终端 Tab ====================

class _TerminalTab extends StatelessWidget {
  final List<TerminalLine> lines;
  const _TerminalTab({required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return _EmptyState(icon: Icons.terminal, title: '等待输出',
          subtitle: 'Claude Code 的终端输出会显示在这里');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_fmt(line.timestamp),
                style: TextStyle(fontSize: 10, fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.outline)),
            const SizedBox(width: 6),
            Expanded(child: SelectableText(line.text,
                style: TextStyle(fontSize: 13, fontFamily: 'monospace',
                    color: _lineColor(context, line.text)))),
          ]),
        );
      },
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  Color _lineColor(BuildContext c, String t) {
    if (t.startsWith('✅')) return Colors.green;
    if (t.startsWith('❌')) return Colors.red;
    if (t.startsWith('📢')) return Colors.orange;
    if (t.startsWith('[')) return Theme.of(c).colorScheme.primary;
    return Theme.of(c).colorScheme.onSurface;
  }
}

// ==================== 历史 Tab ====================

class _HistoryTab extends StatelessWidget {
  final List<ActivityItem> feed;
  const _HistoryTab({required this.feed});

  @override
  Widget build(BuildContext context) {
    if (feed.isEmpty) {
      return _EmptyState(icon: Icons.history, title: '暂无活动', subtitle: '操作记录会显示在这里');
    }
    return ListView.builder(
      itemCount: feed.length,
      itemBuilder: (context, index) {
        final item = feed[index];
        return ListTile(
          leading: Icon(_iconFor(item.type, item.isError), color: _colorFor(item.type, item.isError)),
          title: Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('${item.toolName ?? item.type.value} · ${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12)),
          dense: true,
        );
      },
    );
  }

  IconData _iconFor(ActivityType t, bool e) {
    if (t == ActivityType.toolCompleted) return Icons.check_circle_outline;
    if (t == ActivityType.notification) return Icons.notifications_outlined;
    if (t == ActivityType.stop) return e ? Icons.error_outline : Icons.flag;
    if (t == ActivityType.userMessage) return Icons.chat_bubble_outline;
    if (t == ActivityType.claudeResponse) return Icons.smart_toy;
    return Icons.circle_outlined;
  }

  Color _colorFor(ActivityType t, bool e) {
    if (t == ActivityType.toolCompleted) return Colors.blue;
    if (t == ActivityType.notification) return Colors.orange;
    if (t == ActivityType.stop) return e ? Colors.red : Colors.green;
    if (t == ActivityType.userMessage) return Colors.blue;
    if (t == ActivityType.claudeResponse) return Colors.purple;
    return Colors.grey;
  }
}

// ==================== 空状态（带入场动画）====================

class _EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, this.subtitle = ''});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(opacity: _fade,
        child: ScaleTransition(scale: _scale,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            if (widget.subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ],
          ]))),
    );
  }
}
