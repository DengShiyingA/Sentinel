import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/rules/rules_provider.dart';
import '../../../shared/models/rule.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rs = ref.watch(rulesProvider);
    final notifier = ref.read(rulesProvider.notifier);
    final filtered = rs.filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('规则管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditSheet(context, ref, null),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            query: rs.searchQuery,
            filter: rs.filterType,
            onSearch: notifier.setSearch,
            onFilter: notifier.setFilter,
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('没有匹配的规则'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final rule = filtered[i];
                      return _RuleListTile(
                        rule: rule,
                        onEdit: rule.isBuiltin ? null : () => _showEditSheet(context, ref, rule),
                        onDelete: rule.isBuiltin ? null : () => notifier.deleteRule(rule.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Rule? rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RuleEditSheet(
        rule: rule,
        onSave: (r) {
          final notifier = ref.read(rulesProvider.notifier);
          if (rule == null) {
            notifier.addRule(r);
          } else {
            notifier.updateRule(r);
          }
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String query;
  final RuleType? filter;
  final ValueChanged<String> onSearch;
  final ValueChanged<RuleType?> onFilter;

  const _SearchBar({required this.query, this.filter, required this.onSearch, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索规则...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: onSearch,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _chip(context, '全部', null),
              _chip(context, '路径', RuleType.path),
              _chip(context, '工具', RuleType.tool),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, RuleType? type) {
    final selected = filter == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onFilter(selected ? null : type),
      ),
    );
  }
}

class _RuleListTile extends StatelessWidget {
  final Rule rule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _RuleListTile({required this.rule, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(rule.id),
      direction: rule.isBuiltin ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async => !rule.isBuiltin,
      onDismissed: (_) => onDelete?.call(),
      child: ListTile(
        leading: Icon(_actionIcon(rule.action), color: _actionColor(rule.action)),
        title: Text(rule.description),
        subtitle: Row(
          children: [
            if (rule.toolPattern != null)
              _tag(theme, rule.toolPattern!, Colors.blue),
            if (rule.pathPattern != null)
              _tag(theme, rule.pathPattern!, Colors.purple),
            _tag(theme, rule.action.label, _actionColor(rule.action)),
            if (rule.isBuiltin)
              _tag(theme, '内置', Colors.grey),
          ],
        ),
        trailing: rule.isBuiltin ? null : const Icon(Icons.chevron_right, size: 18),
        onTap: onEdit,
      ),
    );
  }

  Widget _tag(ThemeData theme, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontFamily: 'monospace')),
    );
  }

  IconData _actionIcon(RuleAction a) {
    if (a == RuleAction.autoAllow) return Icons.check_circle_outline;
    if (a == RuleAction.requireConfirm) return Icons.help_outline;
    if (a == RuleAction.requireFaceID) return Icons.fingerprint;
    return Icons.block;
  }

  Color _actionColor(RuleAction a) {
    if (a == RuleAction.autoAllow) return Colors.green;
    if (a == RuleAction.requireConfirm) return Colors.orange;
    if (a == RuleAction.requireFaceID) return Colors.red;
    return Colors.red.shade900;
  }
}

class _RuleEditSheet extends StatefulWidget {
  final Rule? rule;
  final ValueChanged<Rule> onSave;

  const _RuleEditSheet({this.rule, required this.onSave});

  @override
  State<_RuleEditSheet> createState() => _RuleEditSheetState();
}

class _RuleEditSheetState extends State<_RuleEditSheet> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _toolCtrl;
  late final TextEditingController _pathCtrl;
  late RuleAction _action;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.rule?.description ?? '');
    _toolCtrl = TextEditingController(text: widget.rule?.toolPattern ?? '');
    _pathCtrl = TextEditingController(text: widget.rule?.pathPattern ?? '');
    _action = widget.rule?.action ?? RuleAction.requireConfirm;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _toolCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.rule == null ? '新建规则' : '编辑规则',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toolCtrl,
            decoration: const InputDecoration(labelText: '工具匹配 (如 Write, Bash, *)', border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathCtrl,
            decoration: const InputDecoration(labelText: '路径匹配 (如 *.env, /src/**)', border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),
          SegmentedButton<RuleAction>(
            segments: RuleAction.values.map((a) =>
                ButtonSegment(value: a, label: Text(a.label, style: const TextStyle(fontSize: 11)))).toList(),
            selected: {_action},
            onSelectionChanged: (s) => setState(() => _action = s.first),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _descCtrl.text.trim().isEmpty ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final rule = Rule(
      id: widget.rule?.id ?? 'custom-${DateTime.now().millisecondsSinceEpoch}',
      toolPattern: _toolCtrl.text.trim().isEmpty ? null : _toolCtrl.text.trim(),
      pathPattern: _pathCtrl.text.trim().isEmpty ? null : _pathCtrl.text.trim(),
      action: _action,
      priority: widget.rule?.priority ?? 50,
      description: _descCtrl.text.trim(),
    );
    widget.onSave(rule);
    Navigator.of(context).pop();
  }
}
