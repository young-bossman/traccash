import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/data/database/db_errors.dart';
import 'package:traccash/features/categories/data/drift_category_repository.dart';
import 'package:traccash/features/expenses/data/drift_expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

/// "Today" for every data test, so date rules don't depend on the clock.
final LocalDate testToday = LocalDate(2026, 10, 25);

/// The preset ids seeded by onCreate, in order (Food is 1, Other is 8).
const int foodId = 1;
const int transportId = 2;

AppDatabase openTestDatabase() => AppDatabase(NativeDatabase.memory());

/// A local-time clock that moves one second per call, so every write gets a
/// distinct timestamp and the repository must convert it to UTC itself.
DateTime Function() steppingClock() {
  var tick = 0;
  return () => DateTime(2026, 10, 25, 9, 0, tick++);
}

DriftExpenseRepository expenseRepo(AppDatabase db) =>
    DriftExpenseRepository(db, today: () => testToday, clock: steppingClock());

DriftCategoryRepository categoryRepo(AppDatabase db) =>
    DriftCategoryRepository(db, clock: steppingClock());

ExpenseDraft draft({
  int amountPesewas = 1250,
  int categoryId = foodId,
  LocalDate? on,
  String? note,
}) => ExpenseDraft(
  amountPesewas: amountPesewas,
  categoryId: categoryId,
  occurredOn: on ?? testToday,
  note: note,
);

List<int> ids(List<Expense> expenses) => [for (final e in expenses) e.id];

/// The next value from a stream being followed with [StreamIterator]. Using
/// one subscription for a whole test means no emission is missed between
/// a write and the check that follows it.
Future<T> nextValue<T>(StreamIterator<T> stream) async {
  expect(await stream.moveNext(), isTrue, reason: 'stream ended early');
  return stream.current;
}

/// Matches a raw SQLite failure with the given extended result code.
Matcher throwsSqlite(int code) => throwsA(
  isA<SqliteException>().having(
    (e) => e.extendedResultCode,
    'extendedResultCode',
    code,
  ),
);

/// For readability at call sites.
const int checkFailed = SqliteConstraint.check;
const int foreignKeyFailed = SqliteConstraint.foreignKey;
const int restrictFailed = SqliteConstraint.restrict;
const int uniqueFailed = SqliteConstraint.unique;
