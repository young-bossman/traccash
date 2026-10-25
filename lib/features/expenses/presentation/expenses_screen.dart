import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/features/expenses/presentation/expense_ledger.dart';
import 'package:traccash/features/expenses/presentation/expenses_header.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/shared/widgets/empty_state.dart';

/// The selected month's expenses with search and a category filter.
///
/// The header (title, month, summary, search, filter chip) stays put; only
/// the ledger below it scrolls. When space is short (large text, keyboard
/// open) the ledger gives up height first. The Add expense button belongs to
/// `AppShell`, so it can move up when a snackbar appears.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  // The text being typed is UI state; the provider holds the debounced query.
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(expenseFiltersProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Never taller than the screen: in the extreme case the header
              // scrolls inside itself rather than overflowing.
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: SingleChildScrollView(
                  child: ExpensesHeader(
                    search: _search,
                    onClearFilters: _clearFilters,
                  ),
                ),
              ),
              Expanded(child: _LedgerArea(onClearFilters: _clearFilters)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerArea extends ConsumerWidget {
  const _LedgerArea({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(expensesViewProvider);

    return switch (view) {
      AsyncData(:final value) => _forView(context, value),
      AsyncError(:final error) => _Scrollable(
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Couldn’t load expenses',
          message: error is AppError
              ? error.message
              : const StorageError().message,
          action: FilledButton.tonal(
            onPressed: () {
              ref
                ..invalidate(monthExpensesProvider)
                ..invalidate(hasAnyExpensesProvider)
                ..invalidate(allCategoriesProvider);
            },
            child: const Text('Try again'),
          ),
        ),
      ),
      _ => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading expenses'),
      ),
    };
  }

  Widget _forView(BuildContext context, ExpensesView view) {
    if (!view.hasAnyExpenses) {
      return _Scrollable(
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No expenses yet',
          message:
              'Add what you spend and TracCash will total it by month and '
              'category. Your records stay on this device.',
          action: FilledButton.tonalIcon(
            onPressed: () => context.push(AppRoutes.addExpense),
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
          ),
        ),
      );
    }
    if (view.monthCount == 0) {
      return _Scrollable(
        child: EmptyState(
          icon: Icons.calendar_month_outlined,
          title: 'No expenses in ${view.month.label}',
          message: 'Nothing was recorded for this month.',
        ),
      );
    }
    if (view.shownCount == 0) {
      return _Scrollable(
        child: EmptyState(
          icon: Icons.search,
          title: 'No matching expenses',
          message: view.noResultsMessage,
          action: FilledButton.tonal(
            onPressed: onClearFilters,
            child: const Text('Clear filters'),
          ),
        ),
      );
    }
    return ExpenseLedger(groups: view.groups);
  }
}

/// Keeps an empty state reachable when large text or the keyboard leaves
/// little height.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s32,
        AppSpacing.s20,
        AppSizes.fabClearance,
      ),
      child: child,
    );
  }
}
