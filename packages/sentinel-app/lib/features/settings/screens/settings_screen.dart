import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/transport/connection_provider.dart';
import '../../../core/transport/transport.dart';
import '../../../core/trust/temporary_trust.dart';
import '../../../shared/utils/snackbar.dart';
import '../../../shared/utils/platform.dart' as platform;

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
              segments: ConnectionMode.values
                  .where((m) => platform.supportsLan || m != ConnectionMode.lan)
                  .map((m) => ButtonSegment(value: m, label: Text(m.labelZh), icon: Icon(_modeIcon(m))))
                  .toList(),
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

          // 错误 + 重试
          if (s.status == ConnStatus.error) ...[
            ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: Text(s.error ?? '连接失败',
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
              trailing: FilledButton.tonal(
                onPressed: () => _connect(notifier),
                child: const Text('重试'),
              ),
            ),
          ],

          // ========== 手动连接 ==========
          if (s.mode == ConnectionMode.lan) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('手动连接', style: theme.textTheme.titleSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('Simulator 测试请输入 localhost:7750',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(flex: 3, child: TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                        labelText: '主机', border: OutlineInputBorder(), isDense: true),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                        labelText: '端口', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: s.status == ConnStatus.connecting ? null : () => _connect(notifier),
                    child: s.status == ConnStatus.connecting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('连接'),
                  ),
                ],
              ),
            ),
          ],

          if (s.mode == ConnectionMode.server) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('服务器连接', style: theme.textTheme.titleSmall),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: '服务器地址',
                        hintText: 'http://your-server:3005',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: s.status == ConnStatus.connecting
                        ? null
                        : () => notifier.connectServer(_hostController.text.trim()),
                    child: s.status == ConnStatus.connecting
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('连接'),
                  ),
                ],
              ),
            ),
          ],

          // ========== 断开 ==========
          if (s.isConnected) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.link_off, color: Colors.red),
              title: const Text('断开连接', style: TextStyle(color: Colors.red)),
              onTap: () => notifier.disconnect(),
            ),
          ],

          // ========== 测试工具 ==========
          if (s.isConnected) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('调试工具', style: theme.textTheme.titleSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton.tonal(
                  onPressed: () => _sendTestRequest('Write', 'medium'),
                  child: const Text('测试 Write'),
                ),
                FilledButton.tonal(
                  onPressed: () => _sendTestRequest('Bash', 'high'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red),
                  child: const Text('测试 Bash (高风险)'),
                ),
                FilledButton.tonal(
                  onPressed: () => _sendTestRequest('Read', 'low'),
                  child: const Text('测试 Read (自动放行)'),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // ========== 规则管理 ==========
          const Divider(),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('规则管理'),
            subtitle: const Text('查看和编辑审批规则'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/rules'),
          ),

          _TrustRulesSection(),

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
          ListTile(
            title: const Text('版本'),
            trailing: Text('0.1.0${platform.isWeb ? ' (Web)' : ''}'),
          ),
          const ListTile(
            title: Text('Sentinel Remote'),
            subtitle: Text('Claude Code Approval Engine · Phase 2'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 连接并在成功后切换到审批 Tab
  Future<void> _connect(SentinelNotifier notifier) async {
    await notifier.connectLan(
      _hostController.text.trim(),
      int.tryParse(_portController.text) ?? 7750,
    );
    // 连接成功 → 切换到审批 Tab
    if (mounted && ref.read(connectionProvider).isConnected) {
      context.go('/approval');
      showSuccess(context, '连接成功');
    }
  }

  /// 发送测试审批请求到 sentinel-cli
  Future<void> _sendTestRequest(String toolName, String riskLevel) async {
    try {
      final client = HttpClient();
      final request = await client.post('localhost', 7749, '/hook');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'tool_name': toolName,
        'tool_input': {
          'file_path': '/src/test-${DateTime.now().second}.ts',
          'command': toolName == 'Bash' ? 'rm -rf /tmp/test' : null,
        },
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (mounted) showInfo(context, '测试 $toolName: $body');
      client.close();
    } catch (e) {
      if (mounted) showError(context, '发送失败: $e');
    }
  }

  IconData _modeIcon(ConnectionMode m) {
    if (m == ConnectionMode.lan) return Icons.wifi;
    if (m == ConnectionMode.cloudkit) return Icons.cloud;
    return Icons.dns;
  }

  Widget _statusIcon(ConnStatus s) {
    if (s == ConnStatus.connecting) {
      return const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Icon(Icons.circle, size: 12,
        color: s == ConnStatus.connected ? Colors.green
            : s == ConnStatus.error ? Colors.red : Colors.grey);
  }

  String _statusText(ConnStatus s) {
    if (s == ConnStatus.connected) return '已连接';
    if (s == ConnStatus.connecting) return '连接中...';
    if (s == ConnStatus.error) return '连接失败';
    return '未连接';
  }
}

/// 临时信任规则列表（设置页嵌入）
class _TrustRulesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trust = ref.watch(trustProvider);
    final active = trust.activeRules;

    if (active.isEmpty && trust.autoAllowedCount == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 16,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('临时信任', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (active.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(trustProvider.notifier).clearAll(),
                  child: const Text('全部清除', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        if (trust.autoAllowedCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('已自动允许 ${trust.autoAllowedCount} 项',
                style: TextStyle(fontSize: 12,
                    color: Theme.of(context).colorScheme.outline)),
          ),
        ...active.map((rule) => ListTile(
          leading: const Icon(Icons.timer_outlined, size: 20),
          title: Text(rule.label, style: const TextStyle(fontSize: 14)),
          subtitle: Text('剩余 ${rule.remainingSeconds ~/ 60} 分钟',
              style: const TextStyle(fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref.read(trustProvider.notifier).removeRule(rule.id),
          ),
          dense: true,
        )),
      ],
    );
  }
}
