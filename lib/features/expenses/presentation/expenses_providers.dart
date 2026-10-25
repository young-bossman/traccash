import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/categories/data/category_repository.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/shared/selected_month.dart';

// Riverpod retries failed providers by default. A storage error here is a
// corrupted row or an unreadable file, which retrying won't fix; the screen
// offers "Try again" instead.
Duration? _noRetry(int retryCount, Object error) => null;

/// The selected month's expenses, newest first.
final StreamProvider<List<Expense>> monthExpensesProvider =
    StreamProvider<List<Expense>>(
      (ref) => ref
          .watch(expenseRepositoryProvider)
          .watchMonth(ref.watch(selectedMonthProvider)),
      retry: _noRetry,
    );

/// False until the first expense is saved, in any month.
final StreamProvider<bool> hasAnyExpensesProvider = StreamProvider<bool>(
  (ref) => ref
      .watch(expenseRepositoryProvider)
      .watchRecent(limit: 1)
      .map((recent) => recent.isNotEmpty),
  retry: _noRetry,
);

/// Every category including archived ones, for the filter sheet.
final StreamProvider<List<Category>> allCategoriesProvider =
    StreamProvider<List<Category>>(
      (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
      retry: _noRetry,
    );

/// The category the ledger is narrowed to, or null for all categories.
final Provider<Category?> filterCategoryProvider = Provider<Category?>((ref) {
  final id = ref.watch(expenseFiltersProvider.select((f) => f.categoryId));
  final categories = ref.watch(allCategoriesProvider).value;
  if (id == null || categories == null) return null;
  for (final c in categories) {
    if (c.id == id) return c;
  }
  return null;
});

/// What the ledger is narrowed to. [query] is the debounced search text.
final class ExpenseFilters {
  const ExpenseFilters({this.query = '', this.categoryId});

  final String query;
  final int? categoryId;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get isActive => hasQuery || categoryId != null;

  @override
  bool operator ==(Object other) =>
      other is ExpenseFilters &&
      other.query == query &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(query, categoryId);
}

final NotifierProvider<ExpenseFiltersNotifier, ExpenseFilters>
expenseFiltersProvider =
    NotifierProvider<ExpenseFiltersNotifier, ExpenseFilters>(
      ExpenseFiltersNotifier.new,
    );

class ExpenseFiltersNotifier extends Notifier<ExpenseFilters> {
  static const Duration debounce = Duration(milliseconds: 200);

  Timer? _pending;

  @override
  ExpenseFilters build() {
    ref.onDispose(() => _pending?.cancel());
    return const ExpenseFilters();
  }

  /// Applies [text] once typing pauses, so the list isn't refiltered on
  /// every keystroke.
  void setQuery(String text) {
    _pending?.cancel();
    _pending = Timer(debounce, () {
      state = ExpenseFilters(query: text, categoryId: state.categoryId);
    });
  }

  void clearQuery() {
    _pending?.cancel();
    state = ExpenseFilters(categoryId: state.categoryId);
  }

  void setCategory(int? categoryId) {
    state = ExpenseFilters(query: state.query, categoryId: categoryId);
  }

  void clear() {
    _pending?.cancel();
    state = const ExpenseFilters();
  }
}

/// Everything the Expenses screen shows below its header, for one month.
final class ExpensesView {
  const ExpensesView({
    required this.month,
    required this.hasAnyExpenses,
    required this.filters,
    required this.filterCategory,
    required this.monthCount,
    required this.monthTotalPesewas,
    required this.shownCount,
    required this.shownTotalPesewas,
    required this.groups,
  });

  final CalendarMonth month;

  /// False on first use: nothing saved in any month.
  final bool hasAnyExpenses;
  final ExpenseFilters filters;

  /// The category [filters] narrows to, or null for all categories.
  final Category? filterCategory;
  final int monthCount;
  final int monthTotalPesewas;

  /// After search and category filter.
  final int shownCount;
  final int shownTotalPesewas;
  final List<DayGroup> groups;

  /// "GH₵ 2,313.90 · 21 expenses", or "GH₵ 126.00 · 5 of 21 expenses" while
  /// a search or category filter is narrowing the list.
  String get summary {
    final noun = monthCount == 1 ? 'expense' : 'expenses';
    if (filters.isActive && monthCount > 0) {
      return '${formatGhs(shownTotalPesewas)} · '
          '$shownCount of $monthCount $noun';
    }
    return '${formatGhs(monthTotalPesewas)} · $monthCount $noun';
  }

  /// Says which filter found nothing, naming the month.
  String get noResultsMessage {
    final query = filters.query.trim();
    final category = filterCategory?.name;
    if (query.isNotEmpty && category != null) {
      return 'Nothing in ${month.label} matches “$query” in $category.';
    }
    if (query.isNotEmpty) return 'Nothing in ${month.label} matches “$query”.';
    return 'No ${category ?? 'matching'} expenses in ${month.label}.';
  }
}

/// Loading until every stream has a value for the current selection. A
/// month change goes back to loading, so the previous month's figures are
/// never shown under the new label.
final Provider<AsyncValue<ExpensesView>> expensesViewProvider =
    Provider<AsyncValue<ExpensesView>>((ref) {
      final month = ref.watch(selectedMonthProvider);
      final expenses = ref.watch(monthExpensesProvider);
      final hasAny = ref.watch(hasAnyExpensesProvider);
      final categories = ref.watch(allCategoriesProvider);
      final filters = ref.watch(expenseFiltersProvider);

      for (final source in <AsyncValue<Object>>[expenses, hasAny, categories]) {
        if (source case AsyncError(:final error, :final stackTrace)) {
          return AsyncError(error, stackTrace);
        }
      }
      if (expenses.isLoading || hasAny.isLoading || categories.isLoading) {
        return const AsyncLoading();
      }

      final all = expenses.requireValue;
      final shown = filterExpenses(
        all,
        query: filters.query,
        categoryId: filters.categoryId,
      );
      return AsyncData(
        ExpensesView(
          month: month,
          hasAnyExpenses: hasAny.requireValue,
          filters: filters,
          filterCategory: ref.watch(filterCategoryProvider),
          monthCount: all.length,
          monthTotalPesewas: sumPesewas(all),
          shownCount: shown.length,
          shownTotalPesewas: sumPesewas(shown),
          groups: groupByDay(shown),
        ),
      );
    });
