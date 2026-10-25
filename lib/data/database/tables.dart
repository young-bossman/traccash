import 'package:drift/drift.dart';
import 'package:traccash/data/database/local_date_converter.dart';

// Row classes get a `Row` suffix so they never clash with the domain models
// that screens use.

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Drift's Dart DSL has no collation option, so the whole constraint is
  // spelled out. length() counts code points, as the Dart-side rule does.
  TextColumn get name => text().customConstraint(
    'NOT NULL UNIQUE COLLATE NOCASE CHECK (length(name) BETWEEN 1 AND 20)',
  )();

  TextColumn get iconKey => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isPreset => boolean()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('ExpenseRow')
@TableIndex(name: 'expenses_occurred_on', columns: {#occurredOn})
@TableIndex(name: 'expenses_category_id', columns: {#categoryId})
class Expenses extends Table {
  // AUTOINCREMENT: SQLite never hands a deleted id to a new row, so undo can
  // put a deleted expense back under its original id.
  IntColumn get id => integer().autoIncrement()();

  // 100000000 is maxPesewas; the literal is needed in generated SQL. Drift
  // reads the self-reference in check() at build time; it never runs.
  IntColumn get amountPesewas =>
      // ignore: recursive_getters
      integer().check(amountPesewas.isBetweenValues(1, 100000000))();

  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();

  TextColumn get occurredOn => text()
      .map(const LocalDateConverter())
      .check(occurredOn.length.equals(10))();

  TextColumn get note =>
      text().nullable().check(note.length.isSmallerOrEqualValue(200))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
