import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/core/formatting/dates.dart';
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
  sortOrder: sortOrder ?? id,
  isPreset: false,
  isArchived: archived,
  createdAt: _created,
);

final Category food = _category(1, 'Food');
final Category transport = _category(2, 'Transport');
final Category health = _category(3, 'Health');

Expense _expense(
  int id,
  int pesewas,
  Category category,
  LocalDate date, {
  String? note,
}) => Expense(
  id: id,
  amountPesewas: pesewas,
  category: category,
  occurredOn: date,
  note: note,
  createdAt: _created,
  updatedAt: _created,
);

void main() {
  final oct21 = LocalDate(2026, 10, 21);
  final oct20 = LocalDate(2026, 10, 20);
  final oct19 = LocalDate(2026, 10, 19);

  // Repository order: newest date first, then most recently entered.
  final month = [
    _expense(4, 4500, food, oct21, note: 'Waakye and egg, lunch'),
    _expense(3, 1200, transport, oct21, note: 'Trotro, Madina to Circle'),
    _expense(2, 5000, food, oct20),
    _expense(1, 3500, transport, oct19, note: 'Ride to Airport City'),
  ];

  group('sumPesewas', () {
    test('adds integer pesewas, 0 for none', () {
      expect(sumPesewas(month), 14200);
      expect(sumPesewas(const []), 0);
    });

    test('stays exact for the largest amounts', () {
      final big = [
        for (var i = 0; i < 31; i++) _expense(i, 100000000, food, oct21),
      ];
      expect(sumPesewas(big), 3100000000);
    });
  });

  group('filterExpenses', () {
    test('a blank query matches everything', () {
      expect(filterExpenses(month), month);
      expect(filterExpenses(month, query: '   '), month);
    });

    test('matches the note ignoring case and surrounding spaces', () {
      expect(filterExpenses(month, query: '  TROTRO ').map((e) => e.id), [3]);
    });

    test('matches the category name', () {
      expect(filterExpenses(month, query: 'port').map((e) => e.id), [3, 1]);
    });

    test('an expense without a note can still match by category', () {
      expect(filterExpenses(month, query: 'food').map((e) => e.id), [4, 2]);
    });

    test('narrows to a category, and combines with the query', () {
      expect(filterExpenses(month, categoryId: transport.id).map((e) => e.id), [
        3,
        1,
      ]);
      expect(
        filterExpenses(
          month,
          query: 'airport',
          categoryId: transport.id,
        ).map((e) => e.id),
        [1],
      );
      expect(filterExpenses(month, query: 'waakye', categoryId: 2), isEmpty);
    });
  });

  group('groupByDay', () {
    test('groups newest day first with day totals, keeping row order', () {
      final groups = groupByDay(month);

      expect(groups.map((g) => g.date), [oct21, oct20, oct19]);
      expect(groups.map((g) => g.totalPesewas), [5700, 5000, 3500]);
      expect(groups.first.expenses.map((e) => e.id), [4, 3]);
    });

    test('day totals add up to the month total', () {
      final groups = groupByDay(month);
      expect(
        groups.fold(0, (sum, g) => sum + g.totalPesewas),
        sumPesewas(month),
      );
    });

    test('does not rely on the input being sorted by date', () {
      final shuffled = [month[3], month[0], month[2], month[1]];
      expect(groupByDay(shuffled).map((g) => g.date), [oct21, oct20, oct19]);
    });

    test('is empty for no expenses', () {
      expect(groupByDay(const []), isEmpty);
    });
  });

  group('categoryCounts', () {
    test('lists every active category in display order, including 0', () {
      final counts = categoryCounts(month, [health, transport, food]);

      expect(counts.map((c) => (c.category.name, c.count)), [
        ('Food', 2),
        ('Transport', 2),
        ('Health', 0),
      ]);
    });

    test('lists an archived category only when this month uses it', () {
      final oldUsed = _category(9, 'School', archived: true);
      final oldUnused = _category(10, 'Gym', archived: true);
      final withArchived = [...month, _expense(5, 2000, oldUsed, oct19)];

      final names = categoryCounts(withArchived, [
        food,
        transport,
        health,
        oldUsed,
        oldUnused,
      ]).map((c) => c.category.name);

      expect(names, ['Food', 'Transport', 'Health', 'School']);
    });

    test('counts sum to the month count', () {
      final counts = categoryCounts(month, [food, transport, health]);
      expect(counts.fold(0, (sum, c) => sum + c.count), month.length);
    });
  });
}
