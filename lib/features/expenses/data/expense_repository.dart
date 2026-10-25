import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/database_provider.dart';
import 'package:traccash/features/expenses/data/drift_expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

/// Stored expenses. Lists are newest first: by date, then by when they were
/// entered.
///
/// Errors are always `AppError`s. Writes throw `InvalidAmountError`,
/// `InvalidDateError`, `NoteTooLongError`, `CategoryUnavailableError`,
/// `ExpenseNotFoundError` or `StorageError`.
abstract interface class ExpenseRepository {
  Stream<List<Expense>> watchMonth(CalendarMonth month);

  /// The [limit] most recent expenses across all months.
  Stream<List<Expense>> watchRecent({int limit = 5});

  /// Expenses dated [from] to [to], both included.
  Stream<List<Expense>> watchBetween(LocalDate from, LocalDate to);

  /// The earliest expense date, or null when there are no expenses.
  Future<LocalDate?> firstExpenseDate();

  /// Null when no expense has [id].
  Future<Expense?> getById(int id);

  Future<Expense> add(ExpenseDraft draft);

  /// Replaces the editable fields of expense [id] and refreshes `updatedAt`.
  Future<Expense> update(int id, ExpenseDraft draft);

  /// Removes expense [id] and returns it, so the caller can offer undo.
  Future<Expense> delete(int id);

  /// Puts a deleted expense back with its original id and timestamps.
  /// Does nothing if it is already there (a second tap on Undo).
  Future<void> restore(Expense expense);

  /// Debug only: removes every expense and every user-created category in
  /// one transaction. Presets and settings stay as they are.
  Future<void> clearAll();
}

/// Widget tests override this with a fake.
final Provider<ExpenseRepository> expenseRepositoryProvider =
    Provider<ExpenseRepository>(
      (ref) => DriftExpenseRepository(ref.watch(appDatabaseProvider)),
    );
