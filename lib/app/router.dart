import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/app_shell.dart';
import 'package:traccash/features/expenses/presentation/expenses_screen.dart';
import 'package:traccash/features/home/presentation/home_screen.dart';
import 'package:traccash/features/reports/presentation/reports_screen.dart';
import 'package:traccash/features/settings/presentation/settings_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String expenses = '/expenses';
  static const String reports = '/reports';
  static const String settings = '/settings';
}

/// Lives in a provider rather than a global so each ProviderScope (and so
/// each widget test) gets a fresh router with fresh tab state.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // indexedStack keeps every visited tab alive, so each keeps its own
      // scroll position and navigation stack when the user switches away.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.expenses,
                builder: (context, state) => const ExpensesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
