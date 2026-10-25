import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/calculations/average.dart';
import 'package:traccash/core/formatting/dates.dart';

/// Wednesday, 21 October 2026, as in the widget tests.
final LocalDate _today = LocalDate(2026, 10, 21);

void main() {
  group('the current month divides by the days so far, today included', () {
    test('on the 21st, as in 10-reports-daily-light', () {
      // GH₵ 2,313.90 ÷ 21 = GH₵ 110.1857…
      expect(
        averagePerDayPesewas(
          231390,
          const CalendarMonth(2026, 10),
          today: _today,
        ),
        11019,
      );
    });

    test('on the 1st, the average is that day’s total', () {
      expect(
        averagePerDayPesewas(
          4550,
          const CalendarMonth(2026, 10),
          today: LocalDate(2026, 10, 1),
        ),
        4550,
      );
    });

    test('February while it is the current month', () {
      // 14 days so far: 7000 ÷ 14 = 500.
      expect(
        averagePerDayPesewas(
          7000,
          const CalendarMonth(2026, 2),
          today: LocalDate(2026, 2, 14),
        ),
        500,
      );
    });
  });

  group('a past month divides by all its days', () {
    test('a 30-day month', () {
      // GH₵ 6,571.00 ÷ 30 = GH₵ 219.0333…
      expect(
        averagePerDayPesewas(
          657100,
          const CalendarMonth(2026, 9),
          today: _today,
        ),
        21903,
      );
    });

    test('a 31-day month', () {
      // 100000 ÷ 31 = 3225.806…
      expect(
        averagePerDayPesewas(
          100000,
          const CalendarMonth(2026, 8),
          today: _today,
        ),
        3226,
      );
    });

    test('February 2026 has 28 days', () {
      // 10000 ÷ 28 = 357.14…
      expect(
        averagePerDayPesewas(
          10000,
          const CalendarMonth(2026, 2),
          today: _today,
        ),
        357,
      );
    });

    test('February 2028 has 29 days', () {
      // 10000 ÷ 29 = 344.83…
      expect(
        averagePerDayPesewas(
          10000,
          const CalendarMonth(2028, 2),
          today: LocalDate(2028, 3, 1),
        ),
        345,
      );
    });

    test('the current month counts as past once the day moves on', () {
      // Viewed on 1 November: all 31 days of October.
      expect(
        averagePerDayPesewas(
          3100,
          const CalendarMonth(2026, 10),
          today: LocalDate(2026, 11, 1),
        ),
        100,
      );
    });
  });

  test('a month after today (the clock was set back) counts all its days', () {
    expect(
      averagePerDayPesewas(
        3100,
        const CalendarMonth(2026, 10),
        today: LocalDate(2026, 9, 30),
      ),
      100,
    );
  });

  group('rounded to the nearest pesewa', () {
    test('a half pesewa rounds up', () {
      // 45 ÷ 30 = 1.5 and 14 ÷ 28 = 0.5.
      expect(
        averagePerDayPesewas(45, const CalendarMonth(2026, 9), today: _today),
        2,
      );
      expect(
        averagePerDayPesewas(14, const CalendarMonth(2026, 2), today: _today),
        1,
      );
    });

    test('just under a half rounds down, just over rounds up', () {
      // 44 ÷ 30 = 1.47 and 46 ÷ 30 = 1.53.
      expect(
        averagePerDayPesewas(44, const CalendarMonth(2026, 9), today: _today),
        1,
      );
      expect(
        averagePerDayPesewas(46, const CalendarMonth(2026, 9), today: _today),
        2,
      );
    });

    test('an exact division is unchanged', () {
      expect(
        averagePerDayPesewas(3100, const CalendarMonth(2026, 8), today: _today),
        100,
      );
    });
  });

  test('a month with one record', () {
    // One GH₵ 25.00 expense in September: 2500 ÷ 30 = 83.33…
    expect(
      averagePerDayPesewas(2500, const CalendarMonth(2026, 9), today: _today),
      83,
    );
  });

  test('an empty month averages 0', () {
    expect(
      averagePerDayPesewas(0, const CalendarMonth(2026, 9), today: _today),
      0,
    );
  });

  test('large totals stay exact', () {
    // 31 expenses at the GH₵ 1,000,000.00 cap in a 31-day month.
    expect(
      averagePerDayPesewas(
        31 * 100000000,
        const CalendarMonth(2026, 8),
        today: _today,
      ),
      100000000,
    );
  });
}
