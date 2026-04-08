import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../shared/models/approval_request.dart';
import '../../../shared/models/activity_item.dart';
import '../widgets/approval_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _listKey = GlobalKey<AnimatedListState>();

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
      appBar: AppBar(
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingTab(
            requests: s.pendingRequests,
            onDecision: _handleDecision,
          ),
          _TerminalTab(lines: s.terminalLines),
          _HistoryTab(feed: s.activityFeed),
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
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: s.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(s.isConnected ? '已连接' : '未连接',
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  /// 处理审批决策 — 显示 toast + 动画移除
  void _handleDecision(String requestId, Decision decision) {
    final notifier = ref.read(connectionProvider.notifier);
    notifier.sendDecision(requestId, decision);

    final isAllow = decision == Decision.allowed;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isAllow ? Icons.check_circle : Icons.cancel,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(isAllow ? '已允许' : '已拒绝'),
      ]),
      backgroundColor: isAllow ? Colors.green : Colors.red,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ==================== 待审批 Tab ====================

class _PendingTab extends StatelessWidget {
  final List<ApprovalRequest> requests;
  final void Function(String id, Decision decision) onDecision;

  const _PendingTab({required this.requests, required this.onDecision});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyState(
        icon: Icons.shield_outlined,
        title: '没有待审批的请求',
        subtitle: 'Claude Code 的工具调用会出现在这里',
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        key: ValueKey(requests.length),
        padding: const EdgeInsets.only(top: 8),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return ApprovalCard(
            request: req,
            onAllow: () => onDecision(req.id, Decision.allowed),
            onBlock: () => onDecision(req.id, Decision.blocked),
          );
        },
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
      return _EmptyState(
        icon: Icons.terminal,
        title: '等待输出',
        subtitle: 'Claude Code 的终端输出会显示在这里',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fmt(line.timestamp),
                style: TextStyle(fontSize: 10, fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(line.text,
                    style: TextStyle(fontSize: 13, fontFamily: 'monospace',
                        color: _lineColor(context, line.text))),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  Color _lineColor(BuildContext ctx, String text) {
    if (text.startsWith('✅')) return Colors.green;
    if (text.startsWith('❌')) return Colors.red;
    if (text.startsWith('📢')) return Colors.orange;
    if (text.startsWith('[')) return Theme.of(ctx).colorScheme.primary;
    return Theme.of(ctx).colorScheme.onSurface;
  }
}

// ==================== 历史 Tab ====================

class _HistoryTab extends StatelessWidget {
  final List<ActivityItem> feed;
  const _HistoryTab({required this.feed});

  @override
  Widget build(BuildContext context) {
    if (feed.isEmpty) {
      return _EmptyState(
        icon: Icons.history,
        title: '暂无活动',
        subtitle: '操作记录会显示在这里',
      );
    }

    return ListView.builder(
      itemCount: feed.length,
      itemBuilder: (context, index) {
        final item = feed[index];
        return ListTile(
          leading: Icon(_iconFor(item.type, item.isError),
              color: _colorFor(item.type, item.isError)),
          title: Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${item.toolName ?? item.type.value} · '
            '${item.timestamp.hour.toString().padLeft(2, '0')}'
            ':${item.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12),
          ),
          dense: true,
        );
      },
    );
  }

  IconData _iconFor(ActivityType t, bool err) {
    if (t == ActivityType.toolCompleted) return Icons.check_circle_outline;
    if (t == ActivityType.notification) return Icons.notifications_outlined;
    if (t == ActivityType.stop) return err ? Icons.error_outline : Icons.flag;
    if (t == ActivityType.userMessage) return Icons.chat_bubble_outline;
    if (t == ActivityType.claudeResponse) return Icons.smart_toy;
    return Icons.circle_outlined;
  }

  Color _colorFor(ActivityType t, bool err) {
    if (t == ActivityType.toolCompleted) return Colors.blue;
    if (t == ActivityType.notification) return Colors.orange;
    if (t == ActivityType.stop) return err ? Colors.red : Colors.green;
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

  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle = '',
  });

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
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
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 72,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleMedium),
              if (widget.subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(widget.subtitle,
                    style: TextStyle(color: Theme.of(context).colorScheme.outline)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
