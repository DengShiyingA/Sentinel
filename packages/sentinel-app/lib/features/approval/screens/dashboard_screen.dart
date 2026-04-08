import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../shared/models/approval_request.dart';
import '../widgets/approval_card.dart';

/// Main dashboard: segmented tabs for Pending / Terminal / History
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
          // Connection indicator
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

// ==================== Pending Tab ====================

class _PendingTab extends StatelessWidget {
  final ConnectionNotifier notifier;
  const _PendingTab({required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (notifier.pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('没有待审批的请求', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Claude Code 的工具调用会出现在这里',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifier.pendingRequests.length,
      itemBuilder: (context, index) {
        final request = notifier.pendingRequests[index];
        return ApprovalCard(
          request: request,
          onAllow: () => notifier.sendDecision(request.id, Decision.allowed),
          onBlock: () => notifier.sendDecision(request.id, Decision.blocked),
        );
      },
    );
  }
}

// ==================== Terminal Tab ====================

class _TerminalTab extends StatelessWidget {
  final ConnectionNotifier notifier;
  const _TerminalTab({required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (notifier.terminalLines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('等待输出'),
            SizedBox(height: 8),
            Text('Claude Code 的终端输出会显示在这里',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: false,
      itemCount: notifier.terminalLines.length,
      itemBuilder: (context, index) {
        final line = notifier.terminalLines[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${line.timestamp.hour.toString().padLeft(2, '0')}'
                ':${line.timestamp.minute.toString().padLeft(2, '0')}'
                ':${line.timestamp.second.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  line.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: _lineColor(line.text),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _lineColor(String text) {
    if (text.startsWith('✅')) return Colors.green;
    if (text.startsWith('❌')) return Colors.red;
    if (text.startsWith('📢')) return Colors.orange;
    if (text.startsWith('[')) return Colors.blue;
    return Colors.grey.shade800;
  }
}

// ==================== History Tab ====================

class _HistoryTab extends StatelessWidget {
  final ConnectionNotifier notifier;
  const _HistoryTab({required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (notifier.activityFeed.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无活动'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifier.activityFeed.length,
      itemBuilder: (context, index) {
        final item = notifier.activityFeed[index];
        return ListTile(
          leading: Icon(_activityIcon(item), color: _activityColor(item)),
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

  IconData _activityIcon(dynamic item) {
    switch (item.type) {
      case ActivityType.toolCompleted: return Icons.check_circle_outline;
      case ActivityType.notification: return Icons.notifications_outlined;
      case ActivityType.stop: return item.isError ? Icons.error_outline : Icons.flag;
      case ActivityType.userMessage: return Icons.chat_bubble_outline;
      case ActivityType.claudeResponse: return Icons.smart_toy;
      default: return Icons.circle_outlined;
    }
  }

  Color _activityColor(dynamic item) {
    switch (item.type) {
      case ActivityType.toolCompleted: return Colors.blue;
      case ActivityType.notification: return Colors.orange;
      case ActivityType.stop: return item.isError ? Colors.red : Colors.green;
      case ActivityType.userMessage: return Colors.blue;
      case ActivityType.claudeResponse: return Colors.purple;
      default: return Colors.grey;
    }
  }
}
