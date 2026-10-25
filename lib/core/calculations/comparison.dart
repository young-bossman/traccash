import 'dart:math';

import 'package:traccash/core/formatting/dates.dart';

/// Days from [from] to [to], both included.
typedef DateRange = ({LocalDate from, LocalDate to});

enum SpendingChange { less, same, more }

/// How a month's total compares with an earlier period's.
final class Comparison {
  const Comparison(this.change, this.differencePesewas);

  final SpendingChange change;

  /// Never negative; [change] gives the direction.
  final int differencePesewas;

  @override
  bool operator ==(Object other) =>
      other is Comparison &&
      other.change == change &&
      other.differencePesewas == differencePesewas;

  @override
  int get hashCode => Object.hash(change, differencePesewas);

  @override
  String toString() => 'Comparison(${change.name})';
}

/// The days of the previous month that [month] is compared with.
///
/// While [month] is the current month, the same days so far (1–21 Oct
/// against 1–21 Sep), ending early when the previous month is shorter
/// (31 Oct against 1–30 Sep). A past month is compared with the whole
/// previous month.
DateRange comparisonRange(CalendarMonth month, {required LocalDate today}) {
  final previous = month.previous;
  if (!month.contains(today)) return (from: previous.first, to: previous.last);
  final lastDay = min(today.day, previous.daysInMonth);
  return (
    from: previous.first,
    to: LocalDate(previous.year, previous.month, lastDay),
  );
}

/// [current] against [previous], or null when either is 0: a comparison
/// with an empty period says nothing useful.
Comparison? compareTotals({required int current, required int previous}) {
  if (current == 0 || previous == 0) return null;
  final change = current < previous
      ? SpendingChange.less
      : current > previous
      ? SpendingChange.more
      : SpendingChange.same;
  return Comparison(change, (current - previous).abs());
}
