import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import '../features/approval/screens/approval_list_screen.dart';
import '../features/approval/screens/approval_detail_screen.dart';
import '../features/terminal/screens/terminal_screen.dart';
import '../features/messages/screens/messages_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/rules/screens/rules_screen.dart';

class SentinelApp extends ConsumerWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Sentinel',
      theme: SentinelTheme.light(),
      darkTheme: SentinelTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/approval',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/approval',
            builder: (_, __) => const ApprovalListScreen(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                builder: (_, state) => ApprovalDetailScreen(
                  requestId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/terminal', builder: (_, __) => const TerminalScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
            routes: [
              GoRoute(path: 'rules', builder: (_, __) => const RulesScreen()),
            ],
          ),
        ]),
      ],
    ),
  ],
);

class _Shell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const _Shell({required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(connectionProvider);

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: s.pendingRequests.isNotEmpty,
              label: Text('${s.pendingRequests.length}'),
              child: const Icon(Icons.shield_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: s.pendingRequests.isNotEmpty,
              label: Text('${s.pendingRequests.length}'),
              child: const Icon(Icons.shield),
            ),
            label: '审批',
          ),
          const NavigationDestination(
            icon: Icon(Icons.terminal_outlined),
            selectedIcon: Icon(Icons.terminal),
            label: '终端',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: s.newActivityCount > 0,
              label: Text('${s.newActivityCount}'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: '消息',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

// Re-export for settings connect redirect
import '../core/transport/connection_provider.dart';
