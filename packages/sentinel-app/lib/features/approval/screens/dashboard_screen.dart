import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../shared/models/approval_request.dart';
import '../../../shared/models/activity_item.dart';
import '../widgets/approval_card.dart';

/// 主仪表板：分段 Tab 切换 待审批 / 终端 / 历史
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    // watch 整个 state，任何变化都会 rebuild
    final s = ref.watch(connectionProvider);
    final notifier = ref.read(connectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentinel'),
        actions: [
          Padding(
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
                Text(
                  s.isConnected ? '已连接' : '未连接',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: '待审批'),
            const Tab(text: '终端'),
            Tab(text: '历史 (${s.activityFeed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPending(s, notifier),
          _buildTerminal(s),
          _buildHistory(s),
        ],
      ),
    );
  }

  // ==================== 待审批 ====================

  Widget _buildPending(SentinelState s, SentinelNotifier notifier) {
    if (s.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 72,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('没有待审批的请求',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Claude Code 的工具调用会出现在这里',
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: s.pendingRequests.length,
      itemBuilder: (context, index) {
        final req = s.pendingRequests[index];
        return ApprovalCard(
          request: req,
          onAllow: () => notifier.sendDecision(req.id, Decision.allowed),
          onBlock: () => notifier.sendDecision(req.id, Decision.blocked),
        );
      },
    );
  }

  // ==================== 终端 ====================

  Widget _buildTerminal(SentinelState s) {
    if (s.terminalLines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 72,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('等待输出', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Claude Code 的终端输出会显示在这里',
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: s.terminalLines.length,
      itemBuilder: (context, index) {
        final line = s.terminalLines[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _fmt(line.timestamp),
                style: TextStyle(
                  fontSize: 10, fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  line.text,
                  style: TextStyle(
                    fontSize: 13, fontFamily: 'monospace',
                    color: _lineColor(context, line.text),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== 历史 ====================

  Widget _buildHistory(SentinelState s) {
    if (s.activityFeed.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 72,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('暂无活动', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: s.activityFeed.length,
      itemBuilder: (context, index) {
        final item = s.activityFeed[index];
        return ListTile(
          leading: Icon(
            _iconFor(item.type, item.isError),
            color: _colorFor(item.type, item.isError),
          ),
          title: Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${item.toolName ?? item.type.value} · ${_fmt(item.timestamp)}',
            style: const TextStyle(fontSize: 12),
          ),
          dense: true,
        );
      },
    );
  }

  // ==================== 工具函数 ====================

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Color _lineColor(BuildContext ctx, String text) {
    if (text.startsWith('✅')) return Colors.green;
    if (text.startsWith('❌')) return Colors.red;
    if (text.startsWith('📢')) return Colors.orange;
    if (text.startsWith('[')) return Theme.of(ctx).colorScheme.primary;
    return Theme.of(ctx).colorScheme.onSurface;
  }

  IconData _iconFor(ActivityType type, bool isError) {
    if (type == ActivityType.toolCompleted) return Icons.check_circle_outline;
    if (type == ActivityType.notification) return Icons.notifications_outlined;
    if (type == ActivityType.stop) return isError ? Icons.error_outline : Icons.flag;
    if (type == ActivityType.userMessage) return Icons.chat_bubble_outline;
    if (type == ActivityType.claudeResponse) return Icons.smart_toy;
    return Icons.circle_outlined;
  }

  Color _colorFor(ActivityType type, bool isError) {
    if (type == ActivityType.toolCompleted) return Colors.blue;
    if (type == ActivityType.notification) return Colors.orange;
    if (type == ActivityType.stop) return isError ? Colors.red : Colors.green;
    if (type == ActivityType.userMessage) return Colors.blue;
    if (type == ActivityType.claudeResponse) return Colors.purple;
    return Colors.grey;
  }
}
