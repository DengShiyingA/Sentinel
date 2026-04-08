import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../core/transport/transport.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '7750');

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionProvider);
    final notifier = ref.read(connectionProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // Connection Mode
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ConnectionMode>(
              segments: ConnectionMode.values.map((m) {
                return ButtonSegment(
                  value: m,
                  label: Text(m.labelZh),
                  icon: Icon(_modeIcon(m)),
                );
              }).toList(),
              selected: {conn.mode},
              onSelectionChanged: (s) => notifier.switchMode(s.first),
            ),
          ),

          // Connection Status
          ListTile(
            leading: Icon(
              Icons.circle,
              size: 12,
              color: conn.isConnected ? Colors.green : Colors.red,
            ),
            title: Text(conn.isConnected ? '已连接' : '未连接'),
            subtitle: conn.host != null ? Text(conn.host!) : null,
          ),

          if (conn.error != null)
            ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: Text(conn.error!, style: const TextStyle(color: Colors.red)),
            ),

          // Manual Connect (LAN mode)
          if (conn.mode == ConnectionMode.lan) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('手动连接',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: '主机',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: '端口',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final host = _hostController.text.trim();
                      final port = int.tryParse(_portController.text) ?? 7750;
                      notifier.connectLan(host, port);
                    },
                    child: const Text('连接'),
                  ),
                ],
              ),
            ),
          ],

          if (conn.isConnected) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.link_off, color: Colors.red),
              title: const Text('断开连接', style: TextStyle(color: Colors.red)),
              onTap: () => notifier.disconnect(),
            ),
          ],

          // Stats
          const Divider(),
          ListTile(
            title: const Text('待处理'),
            trailing: Text('${notifier.pendingRequests.length}'),
          ),
          ListTile(
            title: const Text('已处理'),
            trailing: Text('${notifier.resolvedCount}'),
          ),

          // About
          const Divider(),
          const ListTile(
            title: Text('版本'),
            trailing: Text('0.1.0'),
          ),
          const ListTile(
            title: Text('Sentinel'),
            subtitle: Text('Claude Code Approval Engine'),
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(ConnectionMode m) {
    switch (m) {
      case ConnectionMode.lan: return Icons.wifi;
      case ConnectionMode.cloudkit: return Icons.cloud;
      case ConnectionMode.server: return Icons.dns;
    }
  }
}
