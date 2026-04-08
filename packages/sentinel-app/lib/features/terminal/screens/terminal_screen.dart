import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../shared/models/activity_item.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(connectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(
            color: s.isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('终端'),
        ]),
        actions: [
          if (s.terminalLines.isNotEmpty || s.activityFeed.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                ref.read(connectionProvider.notifier).clearTerminal();
                ref.read(connectionProvider.notifier).clearNewActivity();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildFeed(s)),
          _buildInput(s),
        ],
      ),
    );
  }

  Widget _buildFeed(SentinelState s) {
    final items = _merge(s);

    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.terminal, size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('等待输出', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Claude Code 的实时输出和对话会显示在这里',
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ]),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildLine(items[i]),
    );
  }

  Widget _buildLine(_FeedItem item) {
    if (item.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(item.text, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    if (item.isClaude) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (item.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(item.label!, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary)),
              ),
            SelectableText(item.text, style: const TextStyle(fontSize: 13)),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '${item.time.hour.toString().padLeft(2, '0')}'
          ':${item.time.minute.toString().padLeft(2, '0')}'
          ':${item.time.second.toString().padLeft(2, '0')}',
          style: TextStyle(fontSize: 10, fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(item.text,
              style: TextStyle(fontSize: 13, fontFamily: 'monospace',
                  color: _color(context, item.text))),
        ),
      ]),
    );
  }

  Widget _buildInput(SentinelState s) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              decoration: InputDecoration(
                hintText: s.isConnected ? '发送消息给 Claude Code...' : '未连接',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true,
              ),
              enabled: s.isConnected,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: s.isConnected && _inputCtrl.text.trim().isNotEmpty ? _send : null,
            icon: const Icon(Icons.arrow_upward, size: 20),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(connectionProvider.notifier).sendUserMessage(text);
    _inputCtrl.clear();
    setState(() {});
  }

  List<_FeedItem> _merge(SentinelState s) {
    final items = <_FeedItem>[];

    for (final line in s.terminalLines) {
      items.add(_FeedItem(text: line.text, time: line.timestamp));
    }

    for (final a in s.activityFeed.reversed) {
      if (a.type == ActivityType.userMessage) {
        items.add(_FeedItem(text: a.summary, time: a.timestamp, isUser: true));
      } else if (a.type == ActivityType.claudeResponse) {
        items.add(_FeedItem(text: a.summary, time: a.timestamp, isClaude: true, label: 'Claude'));
      } else if (a.type == ActivityType.notification) {
        items.add(_FeedItem(text: '📢 ${a.summary}', time: a.timestamp));
      } else if (a.type == ActivityType.stop) {
        items.add(_FeedItem(text: a.isError ? '❌ ${a.summary}' : '✅ ${a.summary}', time: a.timestamp));
      }
    }

    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  Color _color(BuildContext c, String t) {
    if (t.startsWith('✅')) return Colors.green;
    if (t.startsWith('❌')) return Colors.red;
    if (t.startsWith('📢')) return Colors.orange;
    if (t.startsWith('>')) return Theme.of(c).colorScheme.primary;
    if (t.startsWith('[')) return Theme.of(c).colorScheme.tertiary;
    return Theme.of(c).colorScheme.onSurface;
  }
}

class _FeedItem {
  final String text;
  final DateTime time;
  final bool isUser;
  final bool isClaude;
  final String? label;

  const _FeedItem({
    required this.text,
    required this.time,
    this.isUser = false,
    this.isClaude = false,
    this.label,
  });
}
