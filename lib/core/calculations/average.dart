import 'package:traccash/core/formatting/dates.dart';

/// [totalPesewas] per day of [month], rounded to the nearest pesewa with
/// halves up (DESIGN_SPEC §6).
///
/// While [month] is the current month it divides by the days so far, today
/// included, so the average doesn't sink because the rest of the month is
/// still ahead. A past month divides by all its days, and so does a month
/// after [today], which can only be selected if the device clock was set
/// back.
int averagePerDayPesewas(
  int totalPesewas,
  CalendarMonth month, {
  required LocalDate today,
}) {
  assert(totalPesewas >= 0, 'Totals are never negative');
  final days = month.contains(today) ? today.day : month.daysInMonth;
  // Integers only: adding half the divisor before dividing rounds halves up.
  return (2 * totalPesewas + days) ~/ (2 * days);
}
