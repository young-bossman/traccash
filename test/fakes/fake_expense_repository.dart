import 'dart:async';

import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/domain/expense_validation.dart';

import 'fake_category_repository.dart';
import 'fake_streams.dart';

/// In-memory [ExpenseRepository] for widget tests.
///
/// Uses the same validation and throws the same typed errors as the Drift
/// repository. Ids only ever increase, like SQLite's AUTOINCREMENT.
class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository(
    this.categories, {
    LocalDate Function()? today,
    DateTime Function()? clock,
  }) : _today = today ?? LocalDate.today,
       _clock = clock ?? DateTime.now {
    // Labels follow category changes, as they do through a Drift join.
    _categorySubscription = categories.changes.listen((_) => _notify());
  }

  final FakeCategoryRepository categories;
  final LocalDate Function() _today;
  final DateTime Function() _clock;
  final Map<int, Expense> _expenses = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  late final StreamSubscription<void> _categorySubscription;
  int _nextId = 1;

  /// When true, the next write throws [StorageError] and the flag resets.
  bool failNextWrite = false;

  Future<void> dispose() async {
    await _categorySubscription.cancel();
    await _changes.close();
  }

  void _notify() => _changes.add(null);

  void _maybeFail() {
    if (failNextWrite) {
      failNextWrite = false;
      throw const StorageError();
    }
  }

  // Re-reads the category so an archive shows up on old expenses.
  Expense _withCurrentCategory(Expense e) =>
      e.copyWith(category: categories.byId(e.category.id));

  List<Expense> _query(bool Function(Expense) keep, {int? limit}) {
    final list = _expenses.values.where(keep).map(_withCurrentCategory).toList()
      ..sort((a, b) {
        var c = b.occurredOn.compareTo(a.occurredOn);
        if (c == 0) c = b.createdAt.compareTo(a.createdAt);
        if (c == 0) c = b.id.compareTo(a.id);
        return c;
      });
    return limit == null ? list : list.take(limit).toList();
  }

  ExpenseDraft _validated(ExpenseDraft draft) {
    final clean = draft.copyWith(note: () => normalizeNote(draft.note));
    final invalid = validateExpenseDraft(clean, today: _today());
    if (invalid != null) throw invalid;
    return clean;
  }

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) => watchValue(
    _changes.stream,
    () => _query((e) => month.contains(e.occurredOn)),
  );

  @override
  Stream<List<Expense>> watchRecent({int limit = 5}) =>
      watchValue(_changes.stream, () => _query((_) => true, limit: limit));

  @override
  Stream<List<Expense>> watchBetween(LocalDate from, LocalDate to) {
    if (from.compareTo(to) > 0) {
      throw ArgumentError('from ($from) is after to ($to)');
    }
    return watchValue(
      _changes.stream,
      () => _query(
        (e) =>
            e.occurredOn.compareTo(from) >= 0 &&
            e.occurredOn.compareTo(to) <= 0,
      ),
    );
  }

  @override
  Future<LocalDate?> firstExpenseDate() async {
    LocalDate? earliest;
    for (final e in _expenses.values) {
      if (earliest == null || e.occurredOn.compareTo(earliest) < 0) {
        earliest = e.occurredOn;
      }
    }
    return earliest;
  }

  @override
  Future<Expense?> getById(int id) async {
    final e = _expenses[id];
    return e == null ? null : _withCurrentCategory(e);
  }

  @override
  Future<Expense> add(ExpenseDraft draft) async {
    final clean = _validated(draft);
    final category = categories.byId(clean.categoryId);
    final invalidCategory = validateExpenseCategory(category);
    if (invalidCategory != null) throw invalidCategory;
    _maybeFail();

    final now = _clock().toUtc();
    final expense = Expense(
      id: _nextId++,
      amountPesewas: clean.amountPesewas,
      category: category!,
      occurredOn: clean.occurredOn,
      note: clean.note,
      createdAt: now,
      updatedAt: now,
    );
    _expenses[expense.id] = expense;
    _notify();
    return expense;
  }

  @override
  Future<Expense> update(int id, ExpenseDraft draft) async {
    final clean = _validated(draft);
    final existing = _expenses[id];
    if (existing == null) throw const ExpenseNotFoundError();
    final category = categories.byId(clean.categoryId);
    final invalidCategory = validateExpenseCategory(
      category,
      currentCategoryId: existing.category.id,
    );
    if (invalidCategory != null) throw invalidCategory;
    _maybeFail();

    final updated = existing.copyWith(
      amountPesewas: clean.amountPesewas,
      category: category,
      occurredOn: clean.occurredOn,
      note: () => clean.note,
      updatedAt: _clock().toUtc(),
    );
    _expenses[id] = updated;
    _notify();
    return updated;
  }

  @override
  Future<Expense> delete(int id) async {
    final existing = _expenses[id];
    if (existing == null) throw const ExpenseNotFoundError();
    _maybeFail();
    _expenses.remove(id);
    _notify();
    return _withCurrentCategory(existing);
  }

  @override
  Future<void> restore(Expense expense) async {
    if (_expenses.containsKey(expense.id)) return;
    final clean = _validated(expense.toDraft());
    final category = categories.byId(clean.categoryId);
    final invalidCategory = validateExpenseCategory(
      category,
      currentCategoryId: expense.category.id,
    );
    if (invalidCategory != null) throw invalidCategory;
    _maybeFail();

    _expenses[expense.id] = expense.copyWith(
      category: category,
      note: () => clean.note,
    );
    _notify();
  }

  @override
  Future<void> clearAll() async {
    _maybeFail();
    _expenses.clear();
    categories.removeUserCategories();
    _notify();
  }
}
