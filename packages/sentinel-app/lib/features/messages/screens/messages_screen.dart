import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../shared/models/activity_item.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(connectionProvider);
    final notifier = ref.read(connectionProvider.notifier);
    final conn = ref.read(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: conn.isConnected ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  conn.isConnected ? 'Claude Code 运行中' : '等待中',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: notifier.activityFeed.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无消息'),
                        SizedBox(height: 8),
                        Text('Claude Code 的活动和你的消息会显示在这里',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: false,
                    itemCount: notifier.activityFeed.length,
                    itemBuilder: (context, index) {
                      // Show newest at bottom
                      final item = notifier.activityFeed[
                          notifier.activityFeed.length - 1 - index];
                      return _MessageBubble(item: item);
                    },
                  ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '发送消息给 Claude Code...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(notifier),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _controller.text.trim().isEmpty
                        ? null
                        : () => _send(notifier),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(ConnectionNotifier notifier) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    notifier.sendUserMessage(text);
    _controller.clear();
    setState(() {});
  }
}

class _MessageBubble extends StatelessWidget {
  final ActivityItem item;
  const _MessageBubble({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUser = item.type == ActivityType.userMessage;
    final isClaude = item.type == ActivityType.claudeResponse;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : isClaude
                  ? Colors.purple.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && item.toolName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  item.toolName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser ? Colors.white70 : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Text(
              item.summary,
              style: TextStyle(
                color: isUser ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.timestamp.hour.toString().padLeft(2, '0')}'
              ':${item.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
