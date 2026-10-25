import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

/// Most months the monthly trend shows, the selected month included.
const int trendMonthCount = 6;

/// Each day's total in [month]: slot 0 is the 1st. Every day has a slot, so
/// a day with nothing, or one still to come, is 0.
List<int> dailyTotals(Iterable<Expense> expenses, CalendarMonth month) {
  final totals = List.filled(month.daysInMonth, 0);
  for (final e in expenses) {
    if (month.contains(e.occurredOn)) {
      totals[e.occurredOn.day - 1] += e.amountPesewas;
    }
  }
  return totals;
}

/// The first day the monthly trend can need for [selected]: the 1st of the
/// earliest month it could show.
LocalDate trendWindowStart(CalendarMonth selected) {
  var month = selected;
  for (var i = 1; i < trendMonthCount; i++) {
    month = month.previous;
  }
  return month.first;
}

/// The months the trend shows for [selected], oldest first: up to
/// [trendMonthCount] ending with [selected], never before the month of
/// [firstExpense] (the earliest record).
///
/// With no records, or a first record after [selected], it is [selected]
/// alone.
List<CalendarMonth> trendMonths(
  CalendarMonth selected, {
  required LocalDate? firstExpense,
}) {
  final months = [selected];
  if (firstExpense == null) return months;
  final firstMonthStart = CalendarMonth.of(firstExpense).first;
  while (months.length < trendMonthCount &&
      months.first.first.compareTo(firstMonthStart) > 0) {
    months.insert(0, months.first.previous);
  }
  return months;
}

/// Each of [months]' totals in [expenses], in the same order. A month with
/// nothing is 0, so a gap between records still shows as a month.
List<int> monthlyTotals(
  Iterable<Expense> expenses,
  List<CalendarMonth> months,
) {
  final slots = {for (final (i, month) in months.indexed) month: i};
  final totals = List.filled(months.length, 0);
  for (final e in expenses) {
    final slot = slots[CalendarMonth.of(e.occurredOn)];
    if (slot != null) totals[slot] += e.amountPesewas;
  }
  return totals;
}
