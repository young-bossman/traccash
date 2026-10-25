import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/core/calculations/trend.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

final DateTime _created = DateTime.utc(2026, 10, 1);

final Category _food = Category(
  id: 1,
  name: 'Food',
  iconKey: 'food',
  sortOrder: 0,
  isPreset: true,
  isArchived: false,
  createdAt: _created,
);

const CalendarMonth _october = CalendarMonth(2026, 10);

List<Expense> _expenses(List<(int, LocalDate)> items) => [
  for (final (index, (pesewas, date)) in items.indexed)
    Expense(
      id: index + 1,
      amountPesewas: pesewas,
      category: _food,
      occurredOn: date,
      note: null,
      createdAt: _created,
      updatedAt: _created,
    ),
];

LocalDate _oct(int day) => LocalDate(2026, 10, day);

/// The month in 10-reports-daily-light (as seeded for Home's tests), up to
/// today, 21 October.
final List<Expense> _october2026 = _expenses([
  (4500, _oct(21)),
  (1200, _oct(21)),
  (5000, _oct(20)),
  (3500, _oct(19)),
  (9440, _oct(18)),
  (8000, _oct(17)),
  (35000, _oct(15)),
  (12000, _oct(14)),
  (22800, _oct(12)),
  (31900, _oct(10)),
  (53050, _oct(8)),
  (45000, _oct(5)),
]);

List<CalendarMonth> _months(List<(int, int)> yearMonths) => [
  for (final (year, month) in yearMonths) CalendarMonth(year, month),
];

void main() {
  group('dailyTotals', () {
    test('one slot per day of the month, February included', () {
      const none = <Expense>[];
      expect(dailyTotals(none, _october), hasLength(31));
      expect(dailyTotals(none, const CalendarMonth(2026, 9)), hasLength(30));
      expect(dailyTotals(none, const CalendarMonth(2026, 2)), hasLength(28));
      expect(dailyTotals(none, const CalendarMonth(2028, 2)), hasLength(29));
    });

    test('slot 0 is the 1st; expenses on one day are added together', () {
      final totals = dailyTotals(
        _expenses([(100, _oct(1)), (250, _oct(31)), (50, _oct(31))]),
        _october,
      );

      expect(totals.first, 100);
      expect(totals.last, 300);
      expect(totals.sublist(1, 30), everyElement(0));
    });

    test('the days add up to the month total', () {
      final totals = dailyTotals(_october2026, _october);

      expect(totals.fold<int>(0, (sum, t) => sum + t), 231390);
      expect(
        totals.fold<int>(0, (sum, t) => sum + t),
        sumPesewas(_october2026),
      );
    });

    test('the biggest day is the biggest day in the ledger', () {
      final totals = dailyTotals(_october2026, _october);
      final biggestDay = groupByDay(_october2026)
          .map((g) => g.totalPesewas)
          .reduce((a, b) => a > b ? a : b);

      expect(totals.reduce((a, b) => a > b ? a : b), biggestDay);
      expect(totals[7], 53050);
      expect(totals[20], 5700);
    });

    test('days after today in the current month are empty', () {
      final totals = dailyTotals(_october2026, _october);

      expect(totals.sublist(21), everyElement(0));
      expect(totals.sublist(21), hasLength(10));
    });

    test('expenses outside the month are left out', () {
      final totals = dailyTotals(
        _expenses([
          (100, LocalDate(2026, 9, 30)),
          (200, _oct(1)),
          (400, LocalDate(2026, 11, 1)),
          (800, LocalDate(2025, 10, 1)),
        ]),
        _october,
      );

      expect(totals.fold<int>(0, (sum, t) => sum + t), 200);
    });

    test('a month with one record has one day with spending', () {
      final totals = dailyTotals(
        _expenses([(2500, LocalDate(2026, 2, 14))]),
        const CalendarMonth(2026, 2),
      );

      expect(totals, hasLength(28));
      expect(totals[13], 2500);
      expect(totals.where((t) => t > 0), hasLength(1));
    });
  });

  group('trendWindowStart', () {
    test('the 1st of the month five months before the selected one', () {
      expect(trendWindowStart(_october), LocalDate(2026, 5, 1));
    });

    test('across a year boundary', () {
      expect(
        trendWindowStart(const CalendarMonth(2026, 2)),
        LocalDate(2025, 9, 1),
      );
    });
  });

  group('trendMonths', () {
    test('at most 6 months, ending with the selected month', () {
      expect(
        trendMonths(_october, firstExpense: LocalDate(2025, 12, 5)),
        _months([
          (2026, 5),
          (2026, 6),
          (2026, 7),
          (2026, 8),
          (2026, 9),
          (2026, 10),
        ]),
      );
    });

    test('a first record exactly 5 months back gives 6; 6 months back is '
        'cut to 6', () {
      expect(
        trendMonths(_october, firstExpense: LocalDate(2026, 5, 31)),
        hasLength(6),
      );
      expect(
        trendMonths(_october, firstExpense: LocalDate(2026, 4, 30)),
        hasLength(6),
      );
      expect(
        trendMonths(_october, firstExpense: LocalDate(2026, 4, 30)).first,
        const CalendarMonth(2026, 5),
      );
    });

    test('never before the first record', () {
      expect(
        trendMonths(_october, firstExpense: LocalDate(2026, 7, 14)),
        _months([(2026, 7), (2026, 8), (2026, 9), (2026, 10)]),
      );
      expect(
        trendMonths(_october, firstExpense: LocalDate(2026, 9, 2)),
        _months([(2026, 9), (2026, 10)]),
      );
    });

    test('a first record in the selected month gives that month alone', () {
      expect(trendMonths(_october, firstExpense: _oct(21)), [_october]);
    });

    test('across a year boundary', () {
      expect(
        trendMonths(
          const CalendarMonth(2026, 2),
          firstExpense: LocalDate(2025, 1, 1),
        ),
        _months([
          (2025, 9),
          (2025, 10),
          (2025, 11),
          (2025, 12),
          (2026, 1),
          (2026, 2),
        ]),
      );
    });

    test('no records, or a first record after the selected month, gives the '
        'selected month alone', () {
      expect(trendMonths(_october, firstExpense: null), [_october]);
      expect(
        trendMonths(
          const CalendarMonth(2026, 9),
          firstExpense: LocalDate(2026, 10, 1),
        ),
        [const CalendarMonth(2026, 9)],
      );
    });
  });

  group('monthlyTotals', () {
    test('each month’s total, oldest first; empty months stay as 0', () {
      final months = _months([(2026, 7), (2026, 8), (2026, 9), (2026, 10)]);
      final expenses = _expenses([
        (1000, LocalDate(2026, 7, 31)),
        (2000, LocalDate(2026, 9, 1)),
        (500, LocalDate(2026, 9, 30)),
        ..._october2026.map((e) => (e.amountPesewas, e.occurredOn)),
      ]);

      expect(monthlyTotals(expenses, months), [1000, 0, 2500, 231390]);
    });

    test('the selected month’s bar equals its total', () {
      final totals = monthlyTotals(_october2026, [_october]);

      expect(totals.single, sumPesewas(_october2026));
    });

    test('expenses outside the months are left out', () {
      final totals = monthlyTotals(
        _expenses([
          (100, LocalDate(2026, 4, 30)),
          (200, LocalDate(2026, 5, 1)),
          (400, LocalDate(2025, 5, 1)),
        ]),
        _months([(2026, 5), (2026, 6)]),
      );

      expect(totals, [200, 0]);
    });

    test('across a year boundary', () {
      final totals = monthlyTotals(
        _expenses([
          (300, LocalDate(2025, 12, 31)),
          (700, LocalDate(2026, 1, 1)),
        ]),
        _months([(2025, 12), (2026, 1), (2026, 2)]),
      );

      expect(totals, [300, 700, 0]);
    });

    test('a month with one record', () {
      final first = LocalDate(2026, 10, 3);
      final months = trendMonths(_october, firstExpense: first);

      expect(monthlyTotals(_expenses([(2500, first)]), months), [2500]);
    });
  });
}
