import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/core/calculations/breakdown.dart';
import 'package:traccash/core/calculations/comparison.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/lists.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/core/formatting/percent.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/shared/selected_month.dart';

/// Rows in Home's Recent list.
const int recentCount = 5;

/// Everything Home shows below the month switcher, for one month.
final class HomeView {
  const HomeView({
    required this.month,
    required this.today,
    required this.hasAnyExpenses,
    required this.totalPesewas,
    required this.comparison,
    required this.comparedDays,
    required this.largest,
    required this.slices,
    required this.recent,
  });

  /// Derives every figure from the month's [expenses] (newest first).
  /// [previousTotalPesewas] is null when the earlier period couldn't be
  /// read.
  factory HomeView.of({
    required CalendarMonth month,
    required LocalDate today,
    required bool hasAnyExpenses,
    required List<Expense> expenses,
    required int? previousTotalPesewas,
  }) {
    final total = sumPesewas(expenses);
    final totals = categoryTotals(expenses);
    return HomeView(
      month: month,
      today: today,
      hasAnyExpenses: hasAnyExpenses,
      totalPesewas: total,
      comparison: previousTotalPesewas == null
          ? null
          : compareTotals(current: total, previous: previousTotalPesewas),
      comparedDays: comparisonRange(month, today: today),
      largest: largestCategories(totals),
      slices: breakdownSlices(totals),
      recent: expenses.take(recentCount).toList(),
    );
  }

  final CalendarMonth month;
  final LocalDate today;

  /// False on first use: nothing saved in any month.
  final bool hasAnyExpenses;
  final int totalPesewas;

  /// Null when the line is hidden.
  final Comparison? comparison;
  final DateRange comparedDays;

  /// Every category tied for the largest total.
  final List<Category> largest;
  final List<BreakdownSlice> slices;
  final List<Expense> recent;

  bool get isCurrentMonth => month.contains(today);

  String get totalLabel =>
      isCurrentMonth ? 'Spent so far this month' : 'Spent in ${month.label}';

  /// "GH₵ 3,257.10 less than 1–21 Sep", or null when hidden.
  String? get comparisonText {
    final c = comparison;
    if (c == null) return null;
    final days = formatDayRange(comparedDays.from, comparedDays.to);
    final difference = formatGhs(c.differencePesewas);
    return switch (c.change) {
      SpendingChange.less => '$difference less than $days',
      SpendingChange.more => '$difference more than $days',
      SpendingChange.same => 'Same as $days',
    };
  }

  /// Null for an empty month.
  ///
  /// A tie is stated with the amount, not a percentage: rounding to 100.0%
  /// can give equal amounts different shares (33.4% and 33.3%).
  String? get largestShareSentence {
    if (slices.isEmpty) return null;
    final top = slices.first;
    if (largest.length > 1) {
      final names = joinWithAnd([for (final c in largest) c.name]);
      return '$names share the largest amount, '
          '${formatGhs(top.totalPesewas)} each.';
    }
    final name = largest.single.name;
    if (slices.length == 1) {
      return isCurrentMonth
          ? '$name is all the spending this month.'
          : '$name is all the spending in ${month.label}.';
    }
    final ofMonth = isCurrentMonth ? 'this month' : month.label;
    return '$name is the largest share of $ofMonth, '
        'at ${formatShare(top.shareTenths)}.';
  }

  /// The category's name, or "5 other categories".
  String sliceLabel(BreakdownSlice slice) =>
      slice.category?.name ?? '${slice.categoryCount} other categories';

  /// The bar as text for screen readers: "Bills 33.2%, Shopping 25.0%, …".
  String get breakdownSummary =>
      [for (final s in slices) '${sliceLabel(s)} ${formatShare(s.shareTenths)}']
          .join(', ');

  /// `Today`, `Yesterday` or `19 Oct`, after the note in a Recent row.
  String recentDateLabel(Expense expense) =>
      shortDayLabel(expense.occurredOn, today: today);
}

/// Loading until the month's expenses (and the comparison, so the line
/// doesn't pop in a moment later) have values for the current selection.
///
/// Only a failure of the month's own data is an error. The comparison is
/// secondary: if the earlier period can't be read, the line is left out
/// and the rest of Home still shows.
final Provider<AsyncValue<HomeView>> homeViewProvider =
    Provider<AsyncValue<HomeView>>((ref) {
      final expenses = ref.watch(monthExpensesProvider);
      final hasAny = ref.watch(hasAnyExpensesProvider);
      final previous = ref.watch(previousPeriodTotalProvider);

      for (final source in <AsyncValue<Object>>[expenses, hasAny]) {
        if (source case AsyncError(:final error, :final stackTrace)) {
          return AsyncError(error, stackTrace);
        }
      }
      if (expenses.isLoading || hasAny.isLoading || previous.isLoading) {
        return const AsyncLoading();
      }

      return AsyncData(
        HomeView.of(
          month: ref.watch(selectedMonthProvider),
          today: ref.watch(todayProvider),
          hasAnyExpenses: hasAny.requireValue,
          expenses: expenses.requireValue,
          // A pattern rather than `.value`, which would keep the last good
          // total after an error.
          previousTotalPesewas: switch (previous) {
            AsyncData(:final value) => value,
            _ => null,
          },
        ),
      );
    });
