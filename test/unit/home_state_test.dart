import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/percent.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/home/presentation/home_providers.dart';

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

/// Expenses in the given (newest first) order, ids counting down so the
/// first is the most recently entered, as the repository returns them.
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

/// 01-home-light.png: GH₵ 2,313.90 in October, newest first.
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

HomeView _view({
  CalendarMonth month = _october,
  List<Expense>? expenses,
  int? previous = 557100,
}) => HomeView.of(
  month: month,
  today: _today,
  hasAnyExpenses: true,
  expenses: expenses ?? october,
  previousTotalPesewas: previous,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting(dateLocale);
  });

  group('the current month, as in 01-home-light', () {
    test('total and its label', () {
      final view = _view();

      expect(view.totalPesewas, 231390);
      expect(view.isCurrentMonth, isTrue);
      expect(view.totalLabel, 'Spent so far this month');
    });

    test('compares with the same days of last month', () {
      expect(_view().comparisonText, 'GH₵ 3,257.10 less than 1–21 Sep');
    });

    test('names the largest share', () {
      expect(
        _view().largestShareSentence,
        'Bills is the largest share of this month, at 33.2%.',
      );
    });

    test('legend: the top 3 by name and "5 other categories", totalling '
        '100.0%', () {
      final view = _view();

      expect(
        [
          for (final s in view.slices)
            (view.sliceLabel(s), s.totalPesewas, formatShare(s.shareTenths)),
        ],
        [
          ('Bills', 76900, '33.2%'),
          ('Shopping', 57800, '25.0%'),
          ('Food', 57550, '24.9%'),
          ('5 other categories', 39140, '16.9%'),
        ],
      );
      expect(
        view.slices.fold<int>(0, (sum, s) => sum + s.totalPesewas),
        view.totalPesewas,
      );
    });

    test('the bar is summarised for screen readers', () {
      expect(
        _view().breakdownSummary,
        'Bills 33.2%, Shopping 25.0%, Food 24.9%, 5 other categories 16.9%',
      );
    });

    test('Recent is the 5 latest in the month, dated without the year', () {
      final view = _view();

      expect(view.recent, october.take(5).toList());
      expect(
        [for (final e in view.recent) view.recentDateLabel(e)],
        ['Today', 'Today', 'Yesterday', '19 Oct', '18 Oct'],
      );
    });
  });

  group('a past month', () {
    final september = _expenses([
      (2000, food, LocalDate(2026, 9, 30)),
      (1000, transport, LocalDate(2026, 9, 2)),
    ]);

    test('names the month instead of "this month"', () {
      final view = _view(month: _september, expenses: september);

      expect(view.isCurrentMonth, isFalse);
      expect(view.totalLabel, 'Spent in September 2026');
      expect(
        view.largestShareSentence,
        'Food is the largest share of September 2026, at 66.7%.',
      );
    });

    test('compares with the whole month before, as 1–31 Aug', () {
      expect(
        _view(
          month: _september,
          expenses: september,
          previous: 1000,
        ).comparisonText,
        'GH₵ 20.00 more than 1–31 Aug',
      );
    });
  });

  group('comparison line', () {
    test('equal spending reads "Same as"', () {
      expect(_view(previous: 231390).comparisonText, 'Same as 1–21 Sep');
    });

    test('hidden for a month with no previous data', () {
      final view = _view(previous: 0);

      expect(view.comparison, isNull);
      expect(view.comparisonText, isNull);
    });

    test('hidden when the earlier period could not be read, and only it', () {
      final view = _view(previous: null);

      expect(view.comparisonText, isNull);
      expect(view.totalPesewas, 231390);
      expect(view.slices, hasLength(4));
      expect(view.recent, hasLength(5));
    });
  });

  group('largest share sentence', () {
    test('two categories tied', () {
      final view = _view(
        expenses: _expenses([
          (5000, transport, _oct(21)),
          (1200, bills, _oct(20)),
          (5000, food, _oct(19)),
        ]),
      );

      expect(
        view.largestShareSentence,
        'Food and Transport share the largest amount, GH₵ 50.00 each.',
      );
    });

    test('three or more categories tied', () {
      expect(
        _view(
          expenses: _expenses([
            (5000, bills, _oct(21)),
            (5000, transport, _oct(20)),
            (5000, food, _oct(19)),
          ]),
        ).largestShareSentence,
        'Food, Transport and Bills share the largest amount, GH₵ 50.00 each.',
      );
      expect(
        _view(
          expenses: _expenses([
            (5000, health, _oct(21)),
            (5000, bills, _oct(20)),
            (5000, transport, _oct(20)),
            (5000, food, _oct(19)),
          ]),
        ).largestShareSentence,
        'Food, Transport, Bills and Health share the largest amount, '
        'GH₵ 50.00 each.',
      );
    });

    test('a single category is all the spending this month', () {
      final onlyFood = _expenses([(4500, food, _oct(21))]);

      expect(
        _view(expenses: onlyFood).largestShareSentence,
        'Food is all the spending this month.',
      );
    });

    test('a single category in a past month names the month', () {
      expect(
        _view(
          month: _september,
          expenses: _expenses([(4500, food, LocalDate(2026, 9, 3))]),
        ).largestShareSentence,
        'Food is all the spending in September 2026.',
      );
    });
  });

  test('an empty month has a zero total and nothing else', () {
    final view = _view(expenses: const []);

    expect(view.totalPesewas, 0);
    expect(view.comparisonText, isNull);
    expect(view.slices, isEmpty);
    expect(view.largestShareSentence, isNull);
    expect(view.recent, isEmpty);
  });
}
