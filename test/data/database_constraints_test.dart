import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/app_database.dart';

import 'data_test_helpers.dart';

// These go around the repositories on purpose: they prove the database
// itself refuses bad rows, whatever a future caller does.
void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 10, 25, 9);

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<int> insertExpense({
    int amountPesewas = 1250,
    int categoryId = foodId,
    String? note,
  }) => db
      .into(db.expenses)
      .insert(
        ExpensesCompanion.insert(
          amountPesewas: amountPesewas,
          categoryId: categoryId,
          occurredOn: testToday,
          note: Value(note),
          createdAt: now,
          updatedAt: now,
        ),
      );

  // Raw SQL, because the type converter can only produce 10-character dates.
  Future<void> insertRawDate(String occurredOn) => db.customStatement(
    'INSERT INTO expenses '
    '(amount_pesewas, category_id, occurred_on, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?)',
    [1250, foodId, occurredOn, now.toIso8601String(), now.toIso8601String()],
  );

  Future<void> insertRawCategory(String name) => db.customStatement(
    'INSERT INTO categories (name, icon_key, sort_order, is_preset, created_at) '
    'VALUES (?, ?, ?, ?, ?)',
    [name, 'tag', 99, 0, now.toIso8601String()],
  );

  test('onCreate seeds the 8 presets in order', () async {
    final rows = await (db.select(
      db.categories,
    )..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();

    expect(
      [for (final r in rows) r.name],
      [
        'Food',
        'Transport',
        'Bills',
        'Data & Airtime',
        'Shopping',
        'Health',
        'Entertainment',
        'Other',
      ],
    );
    expect(rows.every((r) => r.isPreset && !r.isArchived), isTrue);
    expect(rows.first.id, foodId);
  });

  test('foreign keys are switched on for the connection', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });

  test('amount CHECK rejects 0 and 100,000,001 on a direct insert', () async {
    await expectLater(
      insertExpense(amountPesewas: 0),
      throwsSqlite(checkFailed),
    );
    await expectLater(
      insertExpense(amountPesewas: 100000001),
      throwsSqlite(checkFailed),
    );
    await insertExpense(amountPesewas: 1);
    await insertExpense(amountPesewas: 100000000);
  });

  test('note CHECK rejects 201 characters on a direct insert', () async {
    await expectLater(
      insertExpense(note: 'a' * 201),
      throwsSqlite(checkFailed),
    );
    await insertExpense(note: 'a' * 200);
    await insertExpense(note: '🙂' * 200);
  });

  test('occurred_on CHECK rejects text that is not 10 characters', () async {
    await expectLater(insertRawDate('2026-1-5'), throwsSqlite(checkFailed));
    await expectLater(insertRawDate('2026-10-255'), throwsSqlite(checkFailed));
    await expectLater(insertRawDate(''), throwsSqlite(checkFailed));
    await insertRawDate('2026-10-05');
  });

  test('category name CHECK allows 1 to 20 characters', () async {
    await expectLater(insertRawCategory(''), throwsSqlite(checkFailed));
    await expectLater(insertRawCategory('a' * 21), throwsSqlite(checkFailed));
    await insertRawCategory('a' * 20);
    await insertRawCategory('🙂' * 20);
  });

  test('category names are unique ignoring case', () async {
    await insertRawCategory('School fees');
    await expectLater(
      insertRawCategory('school FEES'),
      throwsSqlite(uniqueFailed),
    );
    await expectLater(insertRawCategory('FOOD'), throwsSqlite(uniqueFailed));
  });

  test('expense must reference an existing category', () async {
    await expectLater(
      insertExpense(categoryId: 999),
      throwsSqlite(foreignKeyFailed),
    );
  });

  test('deleting a category that has expenses fails (FK RESTRICT)', () async {
    await insertExpense(categoryId: transportId);

    await expectLater(
      (db.delete(db.categories)..where((c) => c.id.equals(transportId))).go(),
      throwsSqlite(restrictFailed),
    );

    final stillThere = await (db.select(
      db.categories,
    )..where((c) => c.id.equals(transportId))).getSingleOrNull();
    expect(stillThere, isNotNull);
  });

  test('a category without expenses can be deleted at the SQL level', () async {
    // Shows the failure above comes from the expense, not from the table.
    await (db.delete(db.categories)..where((c) => c.id.equals(8))).go();
  });

  test(
    'a corrupted stored date surfaces as an error, not a wrong date',
    () async {
      await insertRawDate('2026-02-30');
      final repo = expenseRepo(db);

      await expectLater(
        repo.watchMonth(const CalendarMonth(2026, 2)).first,
        throwsA(isA<StorageError>()),
      );
    },
  );
}
