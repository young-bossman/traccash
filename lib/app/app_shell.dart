import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/router.dart';

/// Scaffold around the four tabs, with the bottom navigation bar and the
/// Add expense button.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const int _homeIndex = 0;
  static const int _expensesIndex = 1;

  void _selectTab(int index) {
    // Tapping the tab you're already on returns it to its first screen.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onHome = navigationShell.currentIndex == _homeIndex;

    // Android back from another tab returns to Home instead of closing the
    // app; only back on Home exits. Tabs have no nested routes yet, so this
    // only ever sees the shell page.
    return PopScope(
      canPop: onHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _selectTab(_homeIndex);
      },
      child: Scaffold(
        body: navigationShell,
        // Here rather than on a tab's own Scaffold: snackbars appear in this
        // outermost Scaffold, which lifts its own button above them.
        floatingActionButton: navigationShell.currentIndex == _expensesIndex
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.addExpense),
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              )
            : null,
        floatingActionButtonAnimator: MediaQuery.disableAnimationsOf(context)
            ? FloatingActionButtonAnimator.noAnimation
            : null,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _selectTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.format_list_bulleted),
                label: 'Expenses',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
