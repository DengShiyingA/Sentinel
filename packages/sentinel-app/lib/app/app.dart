import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import '../features/approval/screens/dashboard_screen.dart';
import '../features/approval/screens/approval_detail_screen.dart';
import '../features/messages/screens/messages_screen.dart';
import '../features/settings/screens/settings_screen.dart';

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
      builder: (context, state, shell) => ScaffoldWithNav(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/approval',
            builder: (_, __) => const DashboardScreen(),
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
          GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ]),
      ],
    ),
  ],
);

class ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ScaffoldWithNav({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield), label: '审批'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '消息'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
