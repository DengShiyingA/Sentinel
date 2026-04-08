import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';

class TerminalScreen extends ConsumerWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(connectionProvider);
    final lines = s.terminalLines;

    return Scaffold(
      appBar: AppBar(
        title: const Text('终端'),
        actions: [
          if (lines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(connectionProvider.notifier).clearTerminal(),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(
                color: s.isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('${lines.length}', style: Theme.of(context).textTheme.labelSmall),
            ]),
          ),
        ],
      ),
      body: lines.isEmpty ? _empty(context) : _list(context, lines),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.terminal, size: 72, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text('等待输出', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Claude Code 的实时输出会显示在这里',
            style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      ]),
    );
  }

  Widget _list(BuildContext context, List<TerminalLine> lines) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: lines.length,
      itemBuilder: (context, i) {
        final line = lines[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${line.timestamp.hour.toString().padLeft(2, '0')}'
              ':${line.timestamp.minute.toString().padLeft(2, '0')}'
              ':${line.timestamp.second.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                line.text,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: _color(context, line.text),
                ),
              ),
            ),
          ]),
        );
      },
    );
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
