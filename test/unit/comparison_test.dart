import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/calculations/comparison.dart';
import 'package:traccash/core/formatting/dates.dart';

DateRange _days(LocalDate from, LocalDate to) => (from: from, to: to);

void main() {
  group('comparisonRange', () {
    test('the current month uses the same days of the previous month', () {
      expect(
        comparisonRange(
          const CalendarMonth(2026, 10),
          today: LocalDate(2026, 10, 21),
        ),
        _days(LocalDate(2026, 9, 1), LocalDate(2026, 9, 21)),
      );
    });

    test('on the 31st, a 30-day previous month ends at its last day', () {
      expect(
        comparisonRange(
          const CalendarMonth(2026, 10),
          today: LocalDate(2026, 10, 31),
        ),
        _days(LocalDate(2026, 9, 1), LocalDate(2026, 9, 30)),
      );
    });

    test('30 March compares with all of February', () {
      expect(
        comparisonRange(
          const CalendarMonth(2026, 3),
          today: LocalDate(2026, 3, 30),
        ),
        _days(LocalDate(2026, 2, 1), LocalDate(2026, 2, 28)),
      );
    });

    test('in a leap year, 30 March compares with 1–29 February', () {
      expect(
        comparisonRange(
          const CalendarMonth(2028, 3),
          today: LocalDate(2028, 3, 30),
        ),
        _days(LocalDate(2028, 2, 1), LocalDate(2028, 2, 29)),
      );
    });

    test('on the 1st, only the 1st of the previous month', () {
      expect(
        comparisonRange(
          const CalendarMonth(2026, 10),
          today: LocalDate(2026, 10, 1),
        ),
        _days(LocalDate(2026, 9, 1), LocalDate(2026, 9, 1)),
      );
    });

    test('January compares with December of the year before', () {
      expect(
        comparisonRange(
          const CalendarMonth(2027, 1),
          today: LocalDate(2027, 1, 21),
        ),
        _days(LocalDate(2026, 12, 1), LocalDate(2026, 12, 21)),
      );
    });

    test('a past month uses the whole previous month', () {
      final today = LocalDate(2026, 10, 21);
      expect(
        comparisonRange(const CalendarMonth(2026, 9), today: today),
        _days(LocalDate(2026, 8, 1), LocalDate(2026, 8, 31)),
      );
      expect(
        comparisonRange(const CalendarMonth(2026, 3), today: today),
        _days(LocalDate(2026, 2, 1), LocalDate(2026, 2, 28)),
      );
      expect(
        comparisonRange(const CalendarMonth(2026, 1), today: today),
        _days(LocalDate(2025, 12, 1), LocalDate(2025, 12, 31)),
      );
    });
  });

  group('compareTotals', () {
    test('less than the previous period, by the difference', () {
      expect(
        compareTotals(current: 231390, previous: 557100),
        const Comparison(SpendingChange.less, 325710),
      );
    });

    test('more than the previous period, by the difference', () {
      expect(
        compareTotals(current: 557100, previous: 231390),
        const Comparison(SpendingChange.more, 325710),
      );
    });

    test('the same as the previous period', () {
      expect(
        compareTotals(current: 4500, previous: 4500),
        const Comparison(SpendingChange.same, 0),
      );
    });

    test('hidden when the current month has nothing yet', () {
      expect(compareTotals(current: 0, previous: 557100), isNull);
    });

    test('hidden for a month with no previous data', () {
      expect(compareTotals(current: 231390, previous: 0), isNull);
    });

    test('hidden when both sides are 0', () {
      expect(compareTotals(current: 0, previous: 0), isNull);
    });
  });
}
