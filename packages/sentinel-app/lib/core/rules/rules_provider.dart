import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/rule.dart';
import '../transport/connection_provider.dart';

class RulesState {
  final List<Rule> rules;
  final String searchQuery;
  final RuleType? filterType;

  const RulesState({this.rules = const [], this.searchQuery = '', this.filterType});

  List<Rule> get builtinRules => rules.where((r) => r.isBuiltin).toList();
  List<Rule> get customRules => rules.where((r) => !r.isBuiltin).toList();

  List<Rule> get filtered {
    var list = rules.toList();
    if (filterType != null) list = list.where((r) => r.type == filterType).toList();
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((r) =>
          r.description.toLowerCase().contains(q) ||
          (r.toolPattern ?? '').toLowerCase().contains(q) ||
          (r.pathPattern ?? '').toLowerCase().contains(q)).toList();
    }
    return list..sort((a, b) => a.priority.compareTo(b.priority));
  }

  RulesState copyWith({List<Rule>? rules, String? searchQuery, RuleType? filterType, bool clearFilter = false}) =>
      RulesState(
        rules: rules ?? this.rules,
        searchQuery: searchQuery ?? this.searchQuery,
        filterType: clearFilter ? null : (filterType ?? this.filterType),
      );
}

class RulesNotifier extends Notifier<RulesState> {
  static const _defaultRules = [
    Rule(id: 'builtin-env', pathPattern: '**/.env*', action: RuleAction.requireFaceID, priority: 1, description: '环境变量文件', isBuiltin: true),
    Rule(id: 'builtin-secrets', pathPattern: '**/secrets/**', action: RuleAction.requireFaceID, priority: 2, description: '密钥目录', isBuiltin: true),
    Rule(id: 'builtin-tmp', toolPattern: '*', pathPattern: '/tmp/**', action: RuleAction.autoAllow, priority: 5, description: '/tmp 自动放行', isBuiltin: true),
    Rule(id: 'builtin-bash', toolPattern: 'Bash', action: RuleAction.requireFaceID, priority: 10, description: '终端命令', isBuiltin: true),
    Rule(id: 'builtin-write', toolPattern: 'Write', action: RuleAction.requireConfirm, priority: 20, description: '文件写入', isBuiltin: true),
    Rule(id: 'builtin-edit', toolPattern: 'Edit', action: RuleAction.requireConfirm, priority: 20, description: '文件编辑', isBuiltin: true),
    Rule(id: 'builtin-read', toolPattern: 'Read', action: RuleAction.autoAllow, priority: 50, description: '文件读取', isBuiltin: true),
    Rule(id: 'builtin-grep', toolPattern: 'Grep', action: RuleAction.autoAllow, priority: 50, description: '内容搜索', isBuiltin: true),
    Rule(id: 'builtin-glob', toolPattern: 'Glob', action: RuleAction.autoAllow, priority: 50, description: '文件搜索', isBuiltin: true),
  ];

  @override
  RulesState build() => const RulesState(rules: _defaultRules);

  void setRules(List<Rule> rules) {
    final all = [..._defaultRules, ...rules.where((r) => !r.isBuiltin)];
    state = state.copyWith(rules: all);
  }

  void addRule(Rule rule) {
    state = state.copyWith(rules: [...state.rules, rule]);
    _syncToBackend();
  }

  void updateRule(Rule rule) {
    state = state.copyWith(
      rules: state.rules.map((r) => r.id == rule.id ? rule : r).toList(),
    );
    _syncToBackend();
  }

  void deleteRule(String id) {
    state = state.copyWith(rules: state.rules.where((r) => r.id != id).toList());
    _syncToBackend();
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

  void setFilter(RuleType? type) =>
      state = type == null ? state.copyWith(clearFilter: true) : state.copyWith(filterType: type);

  void _syncToBackend() {
    final custom = state.customRules.map((r) => r.toJson()).toList();
    final transport = ref.read(connectionProvider).isConnected
        ? ref.read(connectionProvider.notifier)
        : null;

    if (transport != null) {
      final t = ref.read(connectionProvider.notifier);
      // Send via transport's underlying sendUserMessage or direct emit
      debugPrint('[Rules] Syncing ${custom.length} custom rules to CLI');
    }
  }
}

final rulesProvider = NotifierProvider<RulesNotifier, RulesState>(RulesNotifier.new);
