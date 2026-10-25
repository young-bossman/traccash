import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/shared/selected_month.dart';

/// A [TodayNotifier] pinned to [date], with no timers or lifecycle listener.
/// Use as `todayProvider.overrideWith(() => FixedToday(date))`.
class FixedToday extends TodayNotifier {
  FixedToday(this.date);

  final LocalDate date;

  @override
  LocalDate build() => date;
}
