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
    final s = ref.watch(connectionProvider);
    final notifier = ref.read(connectionProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ========== 连接模式 ==========
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
              selected: {s.mode},
              onSelectionChanged: (sel) => notifier.switchMode(sel.first),
            ),
          ),

          // ========== 连接状态 ==========
          ListTile(
            leading: _statusIcon(s.status),
            title: Text(_statusText(s.status)),
            subtitle: s.host != null ? Text(s.host!) : null,
          ),

          if (s.error != null)
            ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: Text(s.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          // ========== 手动连接（LAN 模式）==========
          if (s.mode == ConnectionMode.lan) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('手动连接', style: theme.textTheme.titleSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Simulator 测试请输入 localhost:7750',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline)),
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
                        labelText: '主机', border: OutlineInputBorder(), isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: '端口', border: OutlineInputBorder(), isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: s.status == ConnStatus.connecting
                        ? null
                        : () {
                            notifier.connectLan(
                              _hostController.text.trim(),
                              int.tryParse(_portController.text) ?? 7750,
                            );
                          },
                    child: s.status == ConnStatus.connecting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('连接'),
                  ),
                ],
              ),
            ),
          ],

          // ========== 断开连接 ==========
          if (s.isConnected) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.link_off, color: Colors.red),
              title: const Text('断开连接', style: TextStyle(color: Colors.red)),
              onTap: () => notifier.disconnect(),
            ),
          ],

          // ========== 统计 ==========
          const Divider(),
          ListTile(
            title: const Text('待处理'),
            trailing: Text('${s.pendingRequests.length}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('已处理'),
            trailing: Text('${s.resolvedCount}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),

          // ========== 关于 ==========
          const Divider(),
          const ListTile(title: Text('版本'), trailing: Text('0.1.0')),
          const ListTile(
            title: Text('Sentinel Remote'),
            subtitle: Text('Claude Code Approval Engine'),
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(ConnectionMode m) {
    if (m == ConnectionMode.lan) return Icons.wifi;
    if (m == ConnectionMode.cloudkit) return Icons.cloud;
    return Icons.dns;
  }

  Widget _statusIcon(ConnStatus s) {
    if (s == ConnStatus.connecting) {
      return const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Icon(Icons.circle, size: 12,
        color: s == ConnStatus.connected ? Colors.green
            : s == ConnStatus.error ? Colors.red
            : Colors.grey);
  }

  String _statusText(ConnStatus s) {
    if (s == ConnStatus.connected) return '已连接';
    if (s == ConnStatus.connecting) return '连接中...';
    if (s == ConnStatus.error) return '连接失败';
    return '未连接';
  }
}
