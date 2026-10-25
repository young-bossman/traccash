import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/core/formatting/percent.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/home/presentation/home_providers.dart';
import 'package:traccash/features/reports/presentation/reports_providers.dart';

final DateTime _created = DateTime.utc(2026, 10, 1);
final LocalDate _today = LocalDate(2026, 10, 21);
const CalendarMonth _october = CalendarMonth(2026, 10);
const CalendarMonth _september = CalendarMonth(2026, 9);

Category _preset(int id, String name) => Category(
  id: id,
  name: name,
  iconKey: 'tag',
  sortOrder: id - 1,
  isPreset: true,
  isArchived: false,
  createdAt: _created,
);

final Category food = _preset(1, 'Food');
final Category transport = _preset(2, 'Transport');
final Category bills = _preset(3, 'Bills');
final Category dataAirtime = _preset(4, 'Data & Airtime');
final Category shopping = _preset(5, 'Shopping');
final Category health = _preset(6, 'Health');
final Category entertainment = _preset(7, 'Entertainment');
final Category other = _preset(8, 'Other');

/// Expenses newest first, ids counting down, as the repository returns them.
List<Expense> _expenses(List<(int, Category, LocalDate)> items) => [
  for (final (index, (pesewas, category, date)) in items.indexed)
    Expense(
      id: items.length - index,
      amountPesewas: pesewas,
      category: category,
      occurredOn: date,
      note: null,
      createdAt: _created,
      updatedAt: _created,
    ),
];

LocalDate _oct(int day) => LocalDate(2026, 10, day);
LocalDate _sep(int day) => LocalDate(2026, 9, day);

/// The month Home's tests use for 01: GH₵ 2,313.90 across all 8 presets.
final List<Expense> october = _expenses([
  (4500, food, _oct(21)),
  (1200, transport, _oct(21)),
  (5000, dataAirtime, _oct(20)),
  (3500, transport, _oct(19)),
  (9440, other, _oct(18)),
  (8000, entertainment, _oct(17)),
  (35000, shopping, _oct(15)),
  (12000, health, _oct(14)),
  (22800, shopping, _oct(12)),
  (31900, bills, _oct(10)),
  (53050, food, _oct(8)),
  (45000, bills, _oct(5)),
]);

/// GH₵ 6,571.00, with GH₵ 5,571.00 on 1–21 September.
final List<Expense> september = _expenses([
  (100000, transport, _sep(25)),
  (57100, food, _sep(21)),
  (200000, shopping, _sep(10)),
  (300000, bills, _sep(2)),
]);

ReportsView _view({
  CalendarMonth month = _october,
  LocalDate? today,
  List<Expense>? expenses,
  int? previous = 557100,
  MonthlyTrend? monthly,
}) => ReportsView.of(
  month: month,
  today: today ?? _today,
  expenses: expenses ?? october,
  previousTotalPesewas: previous,
  monthly: monthly,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting(dateLocale);
  });

  group('the month in 10-reports-daily-light', () {
    test('total, expense count and daily average', () {
      final view = _view();

      expect(view.totalLabel, 'Total spent · October 2026');
      expect(view.totalPesewas, 231390);
      expect(view.expenseCountText, '12');
      // GH₵ 2,313.90 ÷ 21 days so far.
      expect(view.averageText, 'GH₵ 110.19');
      expect(view.isEmpty, isFalse);
    });

    test('largest category: name, amount and share of the total', () {
      final view = _view();

      expect(view.largestLabel, 'Largest category');
      expect(view.largestName, 'Bills');
      expect(view.largestAmount, 'GH₵ 769.00');
      expect(view.largestDetail, '33.2% of total');
    });

    test('by category: every category, largest first, with counts, '
        'amounts and shares', () {
      final view = _view();

      expect(
        [
          for (final row in view.categories)
            (
              '${row.total.category.name} · ${view.expenseCountLabel(row)}',
              formatGhs(row.total.totalPesewas),
              formatShare(row.shareTenths),
            ),
        ],
        [
          ('Bills · 2 expenses', 'GH₵ 769.00', '33.2%'),
          ('Shopping · 2 expenses', 'GH₵ 578.00', '25.0%'),
          ('Food · 2 expenses', 'GH₵ 575.50', '24.9%'),
          ('Health · 1 expense', 'GH₵ 120.00', '5.2%'),
          ('Other · 1 expense', 'GH₵ 94.40', '4.1%'),
          ('Entertainment · 1 expense', 'GH₵ 80.00', '3.4%'),
          ('Data & Airtime · 1 expense', 'GH₵ 50.00', '2.2%'),
          ('Transport · 2 expenses', 'GH₵ 47.00', '2.0%'),
        ],
      );
    });

    test('the table totals 100.0% and the month total', () {
      final view = _view();

      expect(
        view.categories.fold<int>(0, (sum, r) => sum + r.shareTenths),
        1000,
      );
      expect(
        view.categories.fold<int>(0, (sum, r) => sum + r.total.totalPesewas),
        view.totalPesewas,
      );
    });
  });

  group('share parity with Home', () {
    void expectSameShares(List<Expense> expenses) {
      final reports = _view(expenses: expenses);
      final home = HomeView.of(
        month: _october,
        today: _today,
        hasAnyExpenses: true,
        expenses: expenses,
        previousTotalPesewas: null,
      );
      final reportShares = {
        for (final row in reports.categories)
          row.total.category.id: row.shareTenths,
      };

      expect(home.slices, isNotEmpty);
      for (final slice in home.slices) {
        final category = slice.category;
        if (category == null) {
          // The grouped legend row is the sum of its members' table shares.
          final grouped = reports.categories.skip(3);
          expect(
            slice.shareTenths,
            grouped.fold<int>(0, (sum, r) => sum + r.shareTenths),
          );
        } else {
          expect(
            reportShares[category.id],
            slice.shareTenths,
            reason: category.name,
          );
        }
      }
      expect(reportShares.values.fold<int>(0, (sum, s) => sum + s), 1000);
    }

    test('every category in Home’s legend has the same share in the table', () {
      expectSameShares(october);
    });

    test('also when rounding has to break a three-way tie', () {
      // 33.4%, 33.3%, 33.3% in both places.
      expectSameShares(
        _expenses([
          (5000, bills, _oct(21)),
          (5000, transport, _oct(20)),
          (5000, food, _oct(19)),
        ]),
      );
    });

    test('also with exactly four categories, all named on Home', () {
      expectSameShares(
        _expenses([
          (1000, health, _oct(21)),
          (2000, bills, _oct(20)),
          (3000, transport, _oct(20)),
          (4000, food, _oct(19)),
        ]),
      );
    });
  });

  group('comparison stat', () {
    test('less: a minus sign, read in words', () {
      final view = _view();

      expect(view.comparisonLabel, 'vs 1–21 Sep');
      expect(view.comparisonValue, '−GH₵ 3,257.10');
      expect(view.comparisonSpoken, 'GH₵ 3,257.10 less than 1–21 Sep');
    });

    test('more: a plus sign, read in words', () {
      final view = _view(previous: 100000);

      expect(view.comparisonValue, '+GH₵ 1,313.90');
      expect(view.comparisonSpoken, 'GH₵ 1,313.90 more than 1–21 Sep');
    });

    test('equal: GH₵ 0.00, read as "Same as"', () {
      final view = _view(previous: 231390);

      expect(view.comparisonValue, 'GH₵ 0.00');
      expect(view.comparisonSpoken, 'Same as 1–21 Sep');
    });

    test('nothing to compare with: "No data"', () {
      final view = _view(previous: 0);

      expect(view.comparisonLabel, 'vs 1–21 Sep');
      expect(view.comparisonValue, 'No data');
      expect(view.comparisonSpoken, isNull);
    });

    test('on the 1st the label is a single day', () {
      final view = _view(
        today: _oct(1),
        expenses: _expenses([(4500, food, _oct(1))]),
        previous: 1000,
      );

      expect(view.comparisonLabel, 'vs 1 Sep');
    });

    test('a past month names the previous month', () {
      final view = _view(month: _september, expenses: september, previous: 0);

      expect(view.comparisonLabel, 'vs Aug 2026');
      expect(view.comparisonValue, 'No data');
    });

    test('a past month reads the previous month in full', () {
      final view = _view(
        month: _september,
        expenses: september,
        previous: 600000,
      );

      expect(view.comparisonValue, '+GH₵ 571.00');
      expect(view.comparisonSpoken, 'GH₵ 571.00 more than August 2026');
    });

    test('left out when the earlier period could not be read', () {
      final view = _view(previous: null);

      expect(view.comparisonValue, isNull);
      expect(view.comparisonSpoken, isNull);
      expect(view.totalPesewas, 231390);
    });
  });

  group('largest category on a tie', () {
    test('names every tied category with the amount each', () {
      final view = _view(
        expenses: _expenses([
          (5000, transport, _oct(21)),
          (1200, bills, _oct(20)),
          (5000, food, _oct(19)),
        ]),
      );

      expect(view.largestLabel, 'Largest categories');
      expect(view.largestName, 'Food and Transport');
      expect(view.largestAmount, 'GH₵ 50.00');
      expect(view.largestDetail, 'each');
    });

    test('a single category is 100.0% of the total', () {
      final view = _view(expenses: _expenses([(4500, food, _oct(21))]));

      expect(view.largestName, 'Food');
      expect(view.largestDetail, '100.0% of total');
    });
  });

  group('daily chart', () {
    test('one bar per day, labelled on the 1st, 8th, 15th, 22nd and 29th', () {
      final view = _view();

      expect(view.dayTotals, hasLength(31));
      expect(
        [for (var i = 0; i < 31; i++) ?view.dailyAxisLabel(i)],
        ['1', '8', '15', '22', '29'],
      );
    });

    test('the axis ends at GH₵ 1,000 for a biggest day of GH₵ 530.50', () {
      expect(_view().dailyAxisMaxPesewas, 100000);
    });

    test('summary names the highest day', () {
      expect(
        _view().dailySummary,
        'Daily spending for October 2026. Highest day: 8 October, '
        'GH₵ 530.50.',
      );
    });

    test('summary names every day tied for the highest', () {
      expect(
        _view(
          expenses: _expenses([
            (45000, food, _oct(8)),
            (1200, food, _oct(6)),
            (45000, bills, _oct(5)),
          ]),
        ).dailySummary,
        'Daily spending for October 2026. Highest days: 5 October and '
        '8 October, GH₵ 450.00 each.',
      );
    });

    test('a past year’s days carry the year', () {
      final view = _view(
        month: const CalendarMonth(2025, 3),
        expenses: _expenses([(2500, food, LocalDate(2025, 3, 9))]),
        previous: 0,
      );

      expect(
        view.dailySummary,
        'Daily spending for March 2025. Highest day: 9 March 2025, '
        'GH₵ 25.00.',
      );
    });

    test('February has 28 slots, February 2028 has 29', () {
      expect(
        _view(
          month: const CalendarMonth(2026, 2),
          expenses: _expenses([(100, food, LocalDate(2026, 2, 28))]),
        ).dayTotals,
        hasLength(28),
      );
      expect(
        _view(
          month: const CalendarMonth(2028, 2),
          today: LocalDate(2028, 3, 1),
          expenses: _expenses([(100, food, LocalDate(2028, 2, 29))]),
        ).dayTotals,
        hasLength(29),
      );
    });
  });

  group('monthly chart', () {
    MonthlyTrend trend(
      CalendarMonth selected,
      List<Expense> expenses, {
      required LocalDate? first,
    }) => MonthlyTrend.of(selected, expenses: expenses, firstExpense: first);

    test('September and October, from the first record', () {
      final monthly = trend(_october, [
        ...october,
        ...september,
      ], first: _sep(2));

      expect(monthly.totals, [657100, 231390]);
      expect(
        [for (var i = 0; i < 2; i++) monthly.axisLabel(i)],
        ['Sep', 'Oct'],
      );
      expect(monthly.axisMaxPesewas, 1000000);
      expect(
        monthly.summary,
        'Monthly spending: September GH₵ 6,571.00, October GH₵ 2,313.90.',
      );
    });

    test('six months at most; empty months are kept', () {
      final monthly = trend(_october, october, first: LocalDate(2025, 1, 1));

      expect(monthly.months.first, const CalendarMonth(2026, 5));
      expect(monthly.totals, [0, 0, 0, 0, 0, 231390]);
      expect(
        monthly.summary,
        'Monthly spending: May GH₵ 0.00, June GH₵ 0.00, July GH₵ 0.00, '
        'August GH₵ 0.00, September GH₵ 0.00, October GH₵ 2,313.90.',
      );
    });

    test('across a year boundary every month carries its year', () {
      final monthly = trend(
        const CalendarMonth(2026, 2),
        _expenses([
          (2000, food, LocalDate(2026, 2, 3)),
          (1000, food, LocalDate(2025, 12, 24)),
        ]),
        first: LocalDate(2025, 12, 24),
      );

      expect(
        [for (var i = 0; i < 3; i++) monthly.axisLabel(i)],
        ['Dec', 'Jan', 'Feb'],
      );
      expect(
        monthly.summary,
        'Monthly spending: December 2025 GH₵ 10.00, January 2026 GH₵ 0.00, '
        'February 2026 GH₵ 20.00.',
      );
    });

    test('the note names the month the bars end with', () {
      expect(
        _view().monthlyNote,
        'Monthly totals in cedis, ending October 2026. Months before your '
        'first record are not shown.',
      );
    });
  });

  test('a month with one record: one day, one month, the average', () {
    final only = _expenses([(2500, food, _sep(14))]);
    final view = _view(
      month: _september,
      expenses: only,
      previous: 0,
      monthly: MonthlyTrend.of(
        _september,
        expenses: only,
        firstExpense: _sep(14),
      ),
    );

    expect(view.dayTotals.where((t) => t > 0), [2500]);
    expect(view.dayTotals[13], 2500);
    expect(view.monthly!.totals, [2500]);
    expect(view.monthly!.months, [_september]);
    // GH₵ 25.00 ÷ 30 days.
    expect(view.averagePesewas, 83);
    expect(view.largestDetail, '100.0% of total');
    expect(view.expenseCountLabel(view.categories.single), '1 expense');
  });

  test('an empty month is empty', () {
    final view = _view(expenses: const []);

    expect(view.isEmpty, isTrue);
    expect(view.totalPesewas, 0);
    expect(view.categories, isEmpty);
  });
}
