import 'package:drift/drift.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/data/database/db_errors.dart';
import 'package:traccash/features/categories/data/drift_category_repository.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/domain/expense_validation.dart';

class DriftExpenseRepository implements ExpenseRepository {
  /// [today] and [clock] are injectable so tests control "now".
  DriftExpenseRepository(
    this._db, {
    LocalDate Function()? today,
    DateTime Function()? clock,
  }) : _today = today ?? LocalDate.today,
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final LocalDate Function() _today;
  final DateTime Function() _clock;

  $ExpensesTable get _expenses => _db.expenses;

  JoinedSelectStatement<HasResultSet, Object?> _joined() =>
      _db.select(_expenses).join([
        innerJoin(
          _db.categories,
          _db.categories.id.equalsExp(_expenses.categoryId),
        ),
      ]);

  JoinedSelectStatement<HasResultSet, Object?> _newestFirst() =>
      _joined()..orderBy([
        OrderingTerm.desc(_expenses.occurredOn),
        OrderingTerm.desc(_expenses.createdAt),
        // Rows entered in the same instant (the demo seeder) still sort the
        // same way every time.
        OrderingTerm.desc(_expenses.id),
      ]);

  Expense _fromRow(TypedResult row) {
    final expense = row.readTable(_expenses);
    return Expense(
      id: expense.id,
      amountPesewas: expense.amountPesewas,
      category: categoryFromRow(row.readTable(_db.categories)),
      occurredOn: expense.occurredOn,
      note: expense.note,
      createdAt: expense.createdAt.toUtc(),
      updatedAt: expense.updatedAt.toUtc(),
    );
  }

  Stream<List<Expense>> _watch(
    JoinedSelectStatement<HasResultSet, Object?> q,
  ) => guardDbStream(q.watch().map((rows) => rows.map(_fromRow).toList()));

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) {
    // Half-open range: ISO text sorts like the dates it holds.
    final query = _newestFirst()
      ..where(
        _expenses.occurredOn.isBiggerOrEqualValue(month.first.toIso()) &
            _expenses.occurredOn.isSmallerThanValue(month.nextStart.toIso()),
      );
    return _watch(query);
  }

  @override
  Stream<List<Expense>> watchRecent({int limit = 5}) =>
      _watch(_newestFirst()..limit(limit));

  @override
  Stream<List<Expense>> watchBetween(LocalDate from, LocalDate to) {
    if (from.compareTo(to) > 0) {
      throw ArgumentError('from ($from) is after to ($to)');
    }
    final query = _newestFirst()
      ..where(_expenses.occurredOn.isBetweenValues(from.toIso(), to.toIso()));
    return _watch(query);
  }

  @override
  Future<LocalDate?> firstExpenseDate() => guardDb(() async {
    final earliest = _expenses.occurredOn.min();
    final row = await (_db.selectOnly(
      _expenses,
    )..addColumns([earliest])).getSingle();
    final iso = row.read(earliest);
    return iso == null ? null : LocalDate.parseIso(iso);
  });

  @override
  Future<Expense?> getById(int id) => guardDb(() => _findById(id));

  Future<Expense?> _findById(int id) async {
    final row = await (_joined()..where(_expenses.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Category?> _findCategory(int id) async {
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : categoryFromRow(row);
  }

  /// The draft with its note normalized, or throws the first rule it breaks.
  ExpenseDraft _validated(ExpenseDraft draft) {
    final clean = draft.copyWith(note: () => normalizeNote(draft.note));
    final invalid = validateExpenseDraft(clean, today: _today());
    if (invalid != null) throw invalid;
    return clean;
  }

  // The category is checked inside each transaction first, so a foreign key
  // failure here means it vanished in between.
  AppError? _translate(int code) => code == SqliteConstraint.foreignKey
      ? const CategoryUnavailableError()
      : null;

  @override
  Future<Expense> add(ExpenseDraft draft) => guardDb(
    () => _db.transaction(() async {
      final clean = _validated(draft);
      final category = await _findCategory(clean.categoryId);
      final invalidCategory = validateExpenseCategory(category);
      if (invalidCategory != null) throw invalidCategory;

      final now = _clock().toUtc();
      final id = await _db
          .into(_expenses)
          .insert(
            ExpensesCompanion.insert(
              amountPesewas: clean.amountPesewas,
              categoryId: clean.categoryId,
              occurredOn: clean.occurredOn,
              note: Value(clean.note),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return Expense(
        id: id,
        amountPesewas: clean.amountPesewas,
        category: category!,
        occurredOn: clean.occurredOn,
        note: clean.note,
        createdAt: now,
        updatedAt: now,
      );
    }),
    translate: _translate,
  );

  @override
  Future<Expense> update(int id, ExpenseDraft draft) => guardDb(
    () => _db.transaction(() async {
      final clean = _validated(draft);
      final existing = await _findById(id);
      if (existing == null) throw const ExpenseNotFoundError();
      final category = await _findCategory(clean.categoryId);
      final invalidCategory = validateExpenseCategory(
        category,
        currentCategoryId: existing.category.id,
      );
      if (invalidCategory != null) throw invalidCategory;

      final now = _clock().toUtc();
      await (_db.update(_expenses)..where((e) => e.id.equals(id))).write(
        ExpensesCompanion(
          amountPesewas: Value(clean.amountPesewas),
          categoryId: Value(clean.categoryId),
          occurredOn: Value(clean.occurredOn),
          note: Value(clean.note),
          updatedAt: Value(now),
        ),
      );
      return existing.copyWith(
        amountPesewas: clean.amountPesewas,
        category: category,
        occurredOn: clean.occurredOn,
        note: () => clean.note,
        updatedAt: now,
      );
    }),
    translate: _translate,
  );

  @override
  Future<Expense> delete(int id) => guardDb(
    () => _db.transaction(() async {
      final existing = await _findById(id);
      if (existing == null) throw const ExpenseNotFoundError();
      await (_db.delete(_expenses)..where((e) => e.id.equals(id))).go();
      return existing;
    }),
  );

  @override
  Future<void> restore(Expense expense) => guardDb(
    () => _db.transaction(() async {
      if (await _findById(expense.id) != null) return;

      final clean = _validated(expense.toDraft());
      // The expense may keep the category it had, even if it was archived
      // since; it can't come back if that category is gone.
      final category = await _findCategory(clean.categoryId);
      final invalidCategory = validateExpenseCategory(
        category,
        currentCategoryId: expense.category.id,
      );
      if (invalidCategory != null) throw invalidCategory;

      // An explicit id is safe: AUTOINCREMENT never gave it to another row.
      // A plain insert (not insert-or-ignore) keeps CHECK failures loud.
      await _db
          .into(_expenses)
          .insert(
            ExpensesCompanion.insert(
              id: Value(expense.id),
              amountPesewas: clean.amountPesewas,
              categoryId: clean.categoryId,
              occurredOn: clean.occurredOn,
              note: Value(clean.note),
              createdAt: expense.createdAt.toUtc(),
              updatedAt: expense.updatedAt.toUtc(),
            ),
          );
    }),
    translate: _translate,
  );

  @override
  Future<void> clearAll() => guardDb(
    () => _db.transaction(() async {
      // Expenses first: the foreign key would block deleting their
      // categories.
      await _db.delete(_expenses).go();
      await (_db.delete(
        _db.categories,
      )..where((c) => c.isPreset.equals(false))).go();
    }),
  );
}
