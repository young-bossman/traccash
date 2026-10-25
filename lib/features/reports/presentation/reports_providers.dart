import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/core/calculations/average.dart';
import 'package:traccash/core/calculations/breakdown.dart';
import 'package:traccash/core/calculations/chart_scale.dart';
import 'package:traccash/core/calculations/comparison.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/core/calculations/trend.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/lists.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/core/formatting/percent.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/shared/selected_month.dart';

/// The trend chart's two views.
enum TrendPeriod { daily, monthly }

/// Which trend is shown. Provider state rather than widget state, because a
/// month change rebuilds the page through its spinner and would reset it.
final NotifierProvider<TrendPeriodNotifier, TrendPeriod> trendPeriodProvider =
    NotifierProvider<TrendPeriodNotifier, TrendPeriod>(TrendPeriodNotifier.new);

class TrendPeriodNotifier extends Notifier<TrendPeriod> {
  @override
  TrendPeriod build() => TrendPeriod.daily;

  void select(TrendPeriod period) => state = period;
}

/// Expenses in every month the monthly trend could show for the selected
/// month.
final StreamProvider<List<Expense>> trendExpensesProvider =
    StreamProvider<List<Expense>>((ref) {
      final month = ref.watch(selectedMonthProvider);
      return ref
          .watch(expenseRepositoryProvider)
          .watchBetween(trendWindowStart(month), month.last);
    }, retry: noRetry);

/// The earliest expense date, read again whenever [trendExpensesProvider]
/// emits.
///
/// The repository offers this only as a one-off read. Drift re-runs every
/// watched expenses query after any write to the table, so the trend's
/// stream emits after every add, edit or delete, including ones dated
/// outside the trend's months, and this follows.
final FutureProvider<LocalDate?> firstExpenseDateProvider =
    FutureProvider<LocalDate?>((ref) {
      ref.watch(trendExpensesProvider);
      return ref.watch(expenseRepositoryProvider).firstExpenseDate();
    }, retry: noRetry);

/// One row of Reports' category table.
typedef CategoryShare = ({CategoryTotal total, int shareTenths});

/// Daily bar labels: the 1st and every 7 days after.
const List<int> _labelledDays = [1, 8, 15, 22, 29];

const String _minusSign = '−';

/// The monthly bars: [months] oldest first, ending with the selected month,
/// with each month's total in [totals].
final class MonthlyTrend {
  const MonthlyTrend({required this.months, required this.totals});

  factory MonthlyTrend.of(
    CalendarMonth selected, {
    required Iterable<Expense> expenses,
    required LocalDate? firstExpense,
  }) {
    final months = trendMonths(selected, firstExpense: firstExpense);
    return MonthlyTrend(
      months: months,
      totals: monthlyTotals(expenses, months),
    );
  }

  final List<CalendarMonth> months;
  final List<int> totals;

  int get axisMaxPesewas => chartAxisMaxPesewas(totals.fold(0, max));

  /// `Sep`, under bar [index].
  String axisLabel(int index) => shortMonthName(months[index].month);

  /// The bars as text for screen readers. Each month carries its year when
  /// the bars cross into a new year.
  String get summary {
    final crossesYear = months.first.year != months.last.year;
    final parts = [
      for (final (i, month) in months.indexed)
        '${crossesYear ? month.label : month.name} ${formatGhs(totals[i])}',
    ];
    return 'Monthly spending: ${parts.join(', ')}.';
  }
}

/// Everything Reports shows below its header, for one month.
final class ReportsView {
  const ReportsView({
    required this.month,
    required this.today,
    required this.expenseCount,
    required this.totalPesewas,
    required this.averagePesewas,
    required this.previousTotalPesewas,
    required this.comparedDays,
    required this.categories,
    required this.largest,
    required this.dayTotals,
    required this.monthly,
    required this.monthlyError,
  });

  /// Derives every figure from the month's [expenses]. [monthly] is null
  /// when the trend couldn't be read, with [monthlyError] saying why;
  /// [previousTotalPesewas] is null when the compared days couldn't be.
  factory ReportsView.of({
    required CalendarMonth month,
    required LocalDate today,
    required List<Expense> expenses,
    required int? previousTotalPesewas,
    required MonthlyTrend? monthly,
    Object? monthlyError,
  }) {
    final total = sumPesewas(expenses);
    final totals = categoryTotals(expenses);
    final shares = shareTenths([for (final t in totals) t.totalPesewas]);
    return ReportsView(
      month: month,
      today: today,
      expenseCount: expenses.length,
      totalPesewas: total,
      averagePesewas: averagePerDayPesewas(total, month, today: today),
      previousTotalPesewas: previousTotalPesewas,
      comparedDays: comparisonRange(month, today: today),
      categories: [
        for (final (i, t) in totals.indexed) (total: t, shareTenths: shares[i]),
      ],
      largest: largestCategories(totals),
      dayTotals: dailyTotals(expenses, month),
      monthly: monthly,
      monthlyError: monthlyError,
    );
  }

  final CalendarMonth month;
  final LocalDate today;
  final int expenseCount;
  final int totalPesewas;
  final int averagePesewas;

  /// Null when the compared days couldn't be read.
  final int? previousTotalPesewas;
  final DateRange comparedDays;

  /// Every category with spending this month, largest first.
  final List<CategoryShare> categories;

  /// Every category tied for the largest total.
  final List<Category> largest;

  /// Slot 0 is the 1st.
  final List<int> dayTotals;

  /// Null when the trend couldn't be read.
  final MonthlyTrend? monthly;
  final Object? monthlyError;

  /// Nothing recorded in [month]: Reports shows its no-data state.
  bool get isEmpty => expenseCount == 0;

  bool get isCurrentMonth => month.contains(today);

  String get totalLabel => 'Total spent · ${month.label}';

  String get expenseCountText => '$expenseCount';

  String get averageText => formatGhs(averagePesewas);

  /// `vs 1–21 Sep` (`vs 1 Sep` on the 1st) for the current month; a past
  /// month is compared with the whole month before: `vs Aug 2026`.
  String get comparisonLabel => isCurrentMonth
      ? 'vs ${formatDayRange(comparedDays.from, comparedDays.to)}'
      : 'vs ${month.previous.shortLabel}';

  Comparison? get _comparison {
    final previous = previousTotalPesewas;
    if (previous == null) return null;
    return compareTotals(current: totalPesewas, previous: previous);
  }

  /// `+GH₵ 1,234.00`, `−GH₵ 3,257.10`, `GH₵ 0.00`, or `No data` when either
  /// side is zero. Null when the compared days couldn't be read, so the
  /// stat is left out rather than claiming there is nothing to compare.
  String? get comparisonValue {
    if (previousTotalPesewas == null) return null;
    final c = _comparison;
    if (c == null) return 'No data';
    final difference = formatGhs(c.differencePesewas);
    return switch (c.change) {
      SpendingChange.more => '+$difference',
      SpendingChange.less => '$_minusSign$difference',
      SpendingChange.same => difference,
    };
  }

  /// What a screen reader hears for the comparison:
  /// `GH₵ 3,257.10 less than 1–21 Sep`. Null when there is no difference to
  /// put in words.
  String? get comparisonSpoken {
    final c = _comparison;
    if (c == null) return null;
    final period = isCurrentMonth
        ? formatDayRange(comparedDays.from, comparedDays.to)
        : month.previous.label;
    final difference = formatGhs(c.differencePesewas);
    return switch (c.change) {
      SpendingChange.more => '$difference more than $period',
      SpendingChange.less => '$difference less than $period',
      SpendingChange.same => 'Same as $period',
    };
  }

  String get largestLabel =>
      largest.length > 1 ? 'Largest categories' : 'Largest category';

  /// `Food and Transport` on a tie.
  String get largestName => joinWithAnd([for (final c in largest) c.name]);

  String get largestAmount => formatGhs(categories.first.total.totalPesewas);

  /// `33.2% of total`, or `each` on a tie: rounding to 100.0% can give equal
  /// amounts different shares.
  String get largestDetail => largest.length > 1
      ? 'each'
      : '${formatShare(categories.first.shareTenths)} of total';

  /// `3 expenses`, `1 expense`.
  String expenseCountLabel(CategoryShare row) {
    final count = row.total.expenseCount;
    return count == 1 ? '1 expense' : '$count expenses';
  }

  int get dailyAxisMaxPesewas => chartAxisMaxPesewas(dayTotals.fold(0, max));

  /// The day under bar [index], on the 1st, 8th, 15th, 22nd and 29th only.
  String? dailyAxisLabel(int index) {
    final day = index + 1;
    return _labelledDays.contains(day) ? '$day' : null;
  }

  /// The daily bars as text for screen readers. Every day tied for the
  /// highest is named.
  String get dailySummary {
    final intro = 'Daily spending for ${month.label}.';
    final highest = dayTotals.fold(0, max);
    if (highest == 0) return intro;
    final days = [
      for (final (i, total) in dayTotals.indexed)
        if (total == highest)
          formatDayAndMonth(
            LocalDate(month.year, month.month, i + 1),
            today: today,
          ),
    ];
    final amount = formatGhs(highest);
    return days.length == 1
        ? '$intro Highest day: ${days.single}, $amount.'
        : '$intro Highest days: ${joinWithAnd(days)}, $amount each.';
  }

  String get monthlyNote =>
      'Monthly totals in cedis, ending ${month.label}. '
      'Months before your first record are not shown.';
}

/// Loading until the month, the compared days, the trend and a first read
/// of the earliest date all have values for the current selection, so
/// nothing pops in a moment later.
///
/// Only a failure of the month's own expenses is an error for the page. If
/// the compared days fail, the comparison is left out; if the trend fails,
/// only the monthly chart says so.
final Provider<AsyncValue<ReportsView>> reportsViewProvider =
    Provider<AsyncValue<ReportsView>>((ref) {
      final expenses = ref.watch(monthExpensesProvider);
      final previous = ref.watch(previousPeriodTotalProvider);
      final trend = ref.watch(trendExpensesProvider);
      final first = ref.watch(firstExpenseDateProvider);

      if (expenses case AsyncError(:final error, :final stackTrace)) {
        return AsyncError(error, stackTrace);
      }
      // The first date is read again after every write. Its last value
      // stands until the new one arrives, so a save doesn't flash the
      // spinner.
      if (expenses.isLoading ||
          previous.isLoading ||
          trend.isLoading ||
          (first.isLoading && !first.hasValue)) {
        return const AsyncLoading();
      }

      final month = ref.watch(selectedMonthProvider);
      final trendError = switch ((trend, first)) {
        (AsyncError(:final error), _) => error,
        (_, AsyncError(:final error)) => error,
        _ => null,
      };
      return AsyncData(
        ReportsView.of(
          month: month,
          today: ref.watch(todayProvider),
          expenses: expenses.requireValue,
          // A pattern rather than `.value`, which would keep the last good
          // total after an error.
          previousTotalPesewas: switch (previous) {
            AsyncData(:final value) => value,
            _ => null,
          },
          monthly: trendError != null
              ? null
              : MonthlyTrend.of(
                  month,
                  expenses: trend.requireValue,
                  firstExpense: first.value,
                ),
          monthlyError: trendError,
        ),
      );
    });
