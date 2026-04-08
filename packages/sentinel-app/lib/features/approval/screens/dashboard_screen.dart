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
    final conn = ref.watch(connectionProvider);
    final notifier = ref.read(connectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentinel'),
        actions: [
          // 连接状态指示器
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: conn.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  conn.isConnected ? '已连接' : '未连接',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '待审批'),
            Tab(text: '终端'),
            Tab(text: '历史'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingTab(notifier: notifier),
          _TerminalTab(notifier: notifier),
          _HistoryTab(notifier: notifier),
        ],
      ),
    );
  }
}

// ==================== 待审批 Tab ====================

class _PendingTab extends StatelessWidget {
  final ConnectionNotifier notifier;
  const _PendingTab({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final requests = notifier.pendingRequests;

    if (requests.isEmpty) {
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
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return ApprovalCard(
          request: request,
          onAllow: () => notifier.sendDecision(request.id, Decision.allowed),
          onBlock: () => notifier.sendDecision(request.id, Decision.blocked),
        );
      },
    );
  }
}

// ==================== 终端 Tab ====================

class _TerminalTab extends StatelessWidget {
  final ConnectionNotifier notifier;
  const _TerminalTab({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final lines = notifier.terminalLines;

    if (lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 72,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('等待输出',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Claude Code 的终端输出会显示在这里',
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
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
              // 时间戳
              Text(
                _formatTime(line.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(width: 6),
              // 内容
              Expanded(
                child: SelectableText(
                  line.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
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

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}'
      ':${t.minute.toString().padLeft(2, '0')}'
      ':${t.second.toString().padLeft(2, '0')}';

  /// 根据前缀返回语义色（适配深色模式）
  Color _lineColor(BuildContext context, String text) {
    if (text.startsWith('✅')) return Colors.green;
    if (text.startsWith('❌')) return Colors.red;
    if (text.startsWith('📢')) return Colors.orange;
    if (text.startsWith('[')) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.onSurface;
  }
}

// ==================== 历史 Tab ====================

class _HistoryTab extends StatelessWidget {
  final ConnectionNotifier notifier;
  const _HistoryTab({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final feed = notifier.activityFeed;

    if (feed.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 72,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('暂无活动',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: feed.length,
      itemBuilder: (context, index) {
        final item = feed[index];
        return ListTile(
          leading: Icon(
            _iconForType(item.type, item.isError),
            color: _colorForType(item.type, item.isError),
          ),
          title: Text(item.summary,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${item.toolName ?? item.type.value} · ${_formatTime(item.timestamp)}',
            style: const TextStyle(fontSize: 12),
          ),
          dense: true,
        );
      },
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}'
      ':${t.minute.toString().padLeft(2, '0')}';

  /// 活动类型 → 图标（普通函数，不是 switch 常量）
  IconData _iconForType(ActivityType type, bool isError) {
    if (type == ActivityType.toolCompleted) return Icons.check_circle_outline;
    if (type == ActivityType.notification) return Icons.notifications_outlined;
    if (type == ActivityType.stop) return isError ? Icons.error_outline : Icons.flag;
    if (type == ActivityType.taskCompleted) return Icons.done_all;
    if (type == ActivityType.sessionEnded) return Icons.logout;
    if (type == ActivityType.userMessage) return Icons.chat_bubble_outline;
    if (type == ActivityType.claudeResponse) return Icons.smart_toy;
    if (type == ActivityType.claudeStatus) return Icons.hourglass_top;
    if (type == ActivityType.terminal) return Icons.terminal;
    return Icons.circle_outlined;
  }

  /// 活动类型 → 颜色
  Color _colorForType(ActivityType type, bool isError) {
    if (type == ActivityType.toolCompleted) return Colors.blue;
    if (type == ActivityType.notification) return Colors.orange;
    if (type == ActivityType.stop) return isError ? Colors.red : Colors.green;
    if (type == ActivityType.taskCompleted) return Colors.green;
    if (type == ActivityType.sessionEnded) return Colors.grey;
    if (type == ActivityType.userMessage) return Colors.blue;
    if (type == ActivityType.claudeResponse) return Colors.purple;
    if (type == ActivityType.claudeStatus) return Colors.grey;
    return Colors.grey;
  }
}
