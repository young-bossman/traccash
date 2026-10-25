import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/app_shell.dart';
import 'package:traccash/app/theme/app_motion.dart';
import 'package:traccash/features/expenses/presentation/expense_form_screen.dart';
import 'package:traccash/features/expenses/presentation/expenses_screen.dart';
import 'package:traccash/features/home/presentation/home_screen.dart';
import 'package:traccash/features/reports/presentation/reports_screen.dart';
import 'package:traccash/features/settings/presentation/settings_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String expenses = '/expenses';
  static const String reports = '/reports';
  static const String settings = '/settings';

  /// Full-screen form above the tabs (no navigation bar).
  static const String addExpense = '/expense/new';

  static String editExpense(int id) => '/expense/$id';
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
      // Outside the shell so the form covers the navigation bar. "new" is
      // listed first so it isn't read as an id.
      GoRoute(
        path: AppRoutes.addExpense,
        pageBuilder: (context, state) =>
            _formPage(context, state, const ExpenseFormScreen()),
      ),
      GoRoute(
        path: '/expense/:id',
        redirect: (context, state) =>
            int.tryParse(state.pathParameters['id']!) == null
            ? AppRoutes.expenses
            : null,
        pageBuilder: (context, state) => _formPage(
          context,
          state,
          ExpenseFormScreen(expenseId: int.parse(state.pathParameters['id']!)),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// The add / edit form slides up over the tabs (DESIGN_SPEC §7), or appears
/// in place when the device asks for reduced motion.
Page<void> _formPage(BuildContext context, GoRouterState state, Widget child) {
  final duration = MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : AppMotion.formSlide;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    fullscreenDialog: true,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = animation.drive(
        Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      );
      return SlideTransition(
        position: offset,
        // A route takes taps while it slides in, so the second tap of a
        // double tap on "Add expense" or a ledger row would land on
        // whatever part of the form is passing under the finger.
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => IgnorePointer(
            ignoring: animation.status == AnimationStatus.forward,
            child: child,
          ),
          child: child,
        ),
      );
    },
  );
}
