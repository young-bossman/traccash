import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/calculations/breakdown.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

final DateTime _created = DateTime.utc(2026, 10, 1);

Category _category(
  int id,
  String name, {
  int? sortOrder,
  bool archived = false,
}) => Category(
  id: id,
  name: name,
  iconKey: 'tag',
  sortOrder: sortOrder ?? id - 1,
  isPreset: id <= 8,
  isArchived: archived,
  createdAt: _created,
);

// The presets, with their ids and display order.
final Category food = _category(1, 'Food');
final Category transport = _category(2, 'Transport');
final Category bills = _category(3, 'Bills');
final Category dataAirtime = _category(4, 'Data & Airtime');
final Category shopping = _category(5, 'Shopping');
final Category health = _category(6, 'Health');
final Category entertainment = _category(7, 'Entertainment');
final Category other = _category(8, 'Other');
final List<Category> presets = [
  food,
  transport,
  bills,
  dataAirtime,
  shopping,
  health,
  entertainment,
  other,
];

/// Expenses with ids in list order, all on 21 October 2026.
List<Expense> _expenses(List<(int, Category)> items) => [
  for (final (index, (pesewas, category)) in items.indexed)
    Expense(
      id: index + 1,
      amountPesewas: pesewas,
      category: category,
      occurredOn: LocalDate(2026, 10, 21),
      note: null,
      createdAt: _created,
      updatedAt: _created,
    ),
];

/// The month in 01-home-light.png: GH₵ 2,313.90 across all 8 presets.
final List<Expense> october = _expenses([
  (4500, food),
  (1200, transport),
  (5000, dataAirtime),
  (3500, transport),
  (9440, other),
  (8000, entertainment),
  (35000, shopping),
  (12000, health),
  (22800, shopping),
  (31900, bills),
  (53050, food),
  (45000, bills),
]);

List<(String, int)> _named(List<CategoryTotal> totals) => [
  for (final t in totals) (t.category.name, t.totalPesewas),
];

/// A slice as (label, pesewas, tenths), naming the others by their count.
List<(String, int, int)> _slices(List<BreakdownSlice> slices) => [
  for (final s in slices)
    (
      s.category?.name ?? '${s.categoryCount} others',
      s.totalPesewas,
      s.shareTenths,
    ),
];

int _sum(Iterable<int> values) => values.fold(0, (a, b) => a + b);

/// Random months of 1 to 60 expenses across [presets], seeded so a failure
/// can be replayed.
Iterable<List<Expense>> _randomMonths(int count) sync* {
  final random = Random(6);
  for (var i = 0; i < count; i++) {
    yield _expenses([
      for (var j = 0; j <= random.nextInt(60); j++)
        (
          // Mostly everyday amounts, sometimes up to the cap.
          random.nextInt(10) == 0
              ? 1 + random.nextInt(maxPesewas)
              : 1 + random.nextInt(50000),
          presets[random.nextInt(presets.length)],
        ),
    ]);
  }
}

void main() {
  group('categoryTotals', () {
    test('adds up each category, largest total first', () {
      expect(_named(categoryTotals(october)), [
        ('Bills', 76900),
        ('Shopping', 57800),
        ('Food', 57550),
        ('Health', 12000),
        ('Other', 9440),
        ('Entertainment', 8000),
        ('Data & Airtime', 5000),
        ('Transport', 4700),
      ]);
    });

    test('category totals equal the monthly total', () {
      expect(_sum(categoryTotals(october).map((t) => t.totalPesewas)), 231390);
      expect(sumPesewas(october), 231390);

      for (final month in _randomMonths(200)) {
        expect(
          _sum(categoryTotals(month).map((t) => t.totalPesewas)),
          sumPesewas(month),
        );
      }
    });

    test('ties keep display order: sort order, then id', () {
      final tag9 = _category(9, 'School fees', sortOrder: 8);
      final tag10 = _category(10, 'Church', sortOrder: 8);
      final month = _expenses([
        (1000, tag10),
        (1000, health),
        (400, tag9),
        (600, tag9),
        (1000, food),
        (2000, bills),
      ]);

      expect(_named(categoryTotals(month)), [
        ('Bills', 2000),
        ('Food', 1000),
        ('Health', 1000),
        ('School fees', 1000),
        ('Church', 1000),
      ]);
    });

    test('a single category is one total for the whole month', () {
      final month = _expenses([(4500, food), (1200, food), (300, food)]);

      expect(_named(categoryTotals(month)), [('Food', 6000)]);
    });

    test('an archived category still has its total', () {
      final archived = _category(9, 'Old shop', archived: true);
      final month = _expenses([(2500, archived), (1000, food)]);

      expect(_named(categoryTotals(month)), [
        ('Old shop', 2500),
        ('Food', 1000),
      ]);
    });

    test('no expenses, no totals', () {
      expect(categoryTotals(const []), isEmpty);
    });
  });

  group('shareTenths', () {
    test('three equal shares are 33.4%, 33.3% and 33.3%', () {
      expect(shareTenths([1500, 1500, 1500]), [334, 333, 333]);
    });

    test('a single category is 100.0%', () {
      expect(shareTenths([4500]), [1000]);
    });

    test('two equal shares are 50.0% each', () {
      expect(shareTenths([700, 700]), [500, 500]);
    });

    test(
      'the tenths left after rounding down go to the largest remainders',
      () {
        // October's exact shares: 33.23, 24.98, 24.87, 5.19, 4.08, 3.46,
        // 2.16, 2.03. Rounded down they total 99.5%; the five largest
        // remainders (Health, Other, Shopping, Food, Data) get a tenth each.
        final amounts = [
          for (final t in categoryTotals(october)) t.totalPesewas,
        ];

        expect(shareTenths(amounts), [332, 250, 249, 52, 41, 34, 22, 20]);
      },
    );

    test('equal remainders go to the earlier amount', () {
      // 16.67% each: four of the six round up.
      expect(shareTenths([1, 1, 1, 1, 1, 1]), [167, 167, 167, 167, 166, 166]);
    });

    test('a tiny amount beside a huge one shows as 0.0%', () {
      expect(shareTenths([maxPesewas - 1, 1]), [1000, 0]);
    });

    test('always totals 100.0%, each within a tenth of the exact share', () {
      for (final month in _randomMonths(500)) {
        final amounts = [for (final t in categoryTotals(month)) t.totalPesewas];
        final total = _sum(amounts);
        final shares = shareTenths(amounts);

        expect(_sum(shares), 1000, reason: '$amounts');
        for (final (i, share) in shares.indexed) {
          final roundedDown = amounts[i] * 1000 ~/ total;
          expect(share, inInclusiveRange(roundedDown, roundedDown + 1));
        }
      }
    });

    test('no amounts, no shares', () {
      expect(shareTenths(const []), isEmpty);
    });

    test('nothing spent is 0.0% each rather than a division by zero', () {
      expect(shareTenths([0, 0]), [0, 0]);
    });
  });

  group('breakdownSlices', () {
    test('names the 3 largest categories and groups the rest', () {
      expect(_slices(breakdownSlices(categoryTotals(october))), [
        ('Bills', 76900, 332),
        ('Shopping', 57800, 250),
        ('Food', 57550, 249),
        ('5 others', 39140, 169),
      ]);
    });

    test('with exactly 4 categories the fourth is named', () {
      final month = _expenses([
        (4000, food),
        (3000, transport),
        (2000, bills),
        (1000, health),
      ]);

      expect(_slices(breakdownSlices(categoryTotals(month))), [
        ('Food', 4000, 400),
        ('Transport', 3000, 300),
        ('Bills', 2000, 200),
        ('Health', 1000, 100),
      ]);
    });

    test('with 3 or fewer categories every one is named', () {
      expect(
        _slices(breakdownSlices(categoryTotals(_expenses([(4500, food)])))),
        [('Food', 4500, 1000)],
      );
      expect(
        _slices(
          breakdownSlices(
            categoryTotals(
              _expenses([(1500, food), (1500, transport), (1500, bills)]),
            ),
          ),
        ),
        [('Food', 1500, 334), ('Transport', 1500, 333), ('Bills', 1500, 333)],
      );
    });

    test('slices add up to 100.0% and to the monthly total', () {
      for (final month in [october, ..._randomMonths(200)]) {
        final slices = breakdownSlices(categoryTotals(month));

        expect(_sum(slices.map((s) => s.shareTenths)), 1000);
        expect(_sum(slices.map((s) => s.totalPesewas)), sumPesewas(month));
      }
    });

    test("a category's share is its share among all categories, as a full "
        'table of categories shows it', () {
      for (final month in [october, ..._randomMonths(200)]) {
        final totals = categoryTotals(month);
        final all = shareTenths([for (final t in totals) t.totalPesewas]);

        for (final slice in breakdownSlices(totals)) {
          final category = slice.category;
          if (category == null) continue;
          final index = totals.indexWhere((t) => t.category == category);
          expect(slice.shareTenths, all[index], reason: category.name);
        }
      }
    });

    test("the others' share is the sum of its members' shares", () {
      final totals = categoryTotals(october);
      final all = shareTenths([for (final t in totals) t.totalPesewas]);
      final others = breakdownSlices(totals).last;

      expect(others.category, isNull);
      expect(others.categoryCount, 5);
      expect(others.shareTenths, _sum(all.skip(3)));
    });

    test('no expenses, no slices', () {
      expect(breakdownSlices(const []), isEmpty);
    });
  });

  group('largestCategories', () {
    test('the category with the largest total', () {
      expect(largestCategories(categoryTotals(october)), [bills]);
    });

    test('two categories tied, in display order', () {
      final month = _expenses([(5000, transport), (5000, food), (1200, bills)]);

      expect(largestCategories(categoryTotals(month)), [food, transport]);
    });

    test('three categories tied, in display order', () {
      final month = _expenses([
        (5000, bills),
        (5000, transport),
        (1200, health),
        (5000, food),
      ]);

      expect(largestCategories(categoryTotals(month)), [
        food,
        transport,
        bills,
      ]);
    });

    test('a single category', () {
      expect(largestCategories(categoryTotals(_expenses([(300, food)]))), [
        food,
      ]);
    });

    test('no expenses, no largest category', () {
      expect(largestCategories(const []), isEmpty);
    });
  });
}
