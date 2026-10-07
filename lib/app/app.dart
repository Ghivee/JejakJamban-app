import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insight/presentation/insight_screen.dart';
import '../features/league/presentation/league_screen.dart';
import '../features/log/domain/bowel_log.dart';
import '../features/log/presentation/log_editor_screen.dart';
import '../features/log/presentation/log_list_screen.dart';
import '../features/map/presentation/map_screen.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insight',
                builder: (context, state) => const InsightScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/jejak',
                builder: (context, state) => const LogListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/liga',
                builder: (context, state) => const LeagueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/peta',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/catat',
        builder: (context, state) => LogEditorScreen(
          log: state.extra is BowelLog ? state.extra! as BowelLog : null,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class JejakJambanApp extends ConsumerWidget {
  const JejakJambanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'JejakJamban',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
    routerConfig: ref.watch(routerProvider),
  );
}
