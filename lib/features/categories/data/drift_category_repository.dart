import 'package:drift/drift.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/data/database/db_errors.dart';
import 'package:traccash/features/categories/data/category_repository.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/categories/domain/category_validation.dart';

/// Maps a stored row to the domain model. Shared with the expense repository,
/// which joins categories onto expenses.
Category categoryFromRow(CategoryRow row) => Category(
  id: row.id,
  name: row.name,
  iconKey: row.iconKey,
  sortOrder: row.sortOrder,
  isPreset: row.isPreset,
  isArchived: row.isArchived,
  createdAt: row.createdAt.toUtc(),
);

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  SimpleSelectStatement<$CategoriesTable, CategoryRow> _ordered() =>
      _db.select(_db.categories)..orderBy([
        (c) => OrderingTerm.asc(c.sortOrder),
        (c) => OrderingTerm.asc(c.id),
      ]);

  @override
  Stream<List<Category>> watchActive() {
    final query = _ordered()..where((c) => c.isArchived.equals(false));
    return guardDbStream(
      query.watch().map((rows) => rows.map(categoryFromRow).toList()),
    );
  }

  @override
  Stream<List<Category>> watchAll() => guardDbStream(
    _ordered().watch().map((rows) => rows.map(categoryFromRow).toList()),
  );

  @override
  Future<Category> create(String name, String iconKey) {
    final normalized = normalizeCategoryName(name);
    final invalid = validateNewCategory(normalized, iconKey);
    if (invalid != null) return Future.error(invalid);

    return guardDb(
      // One transaction, so nothing can slip in between the duplicate check
      // and the insert.
      () => _db.transaction(() async {
        final all = (await _ordered().get()).map(categoryFromRow).toList();
        final existing = findCategoryNamed(normalized, all);
        if (existing != null) {
          if (!existing.isArchived) throw DuplicateCategoryError(existing.name);
          await (_db.update(_db.categories)
                ..where((c) => c.id.equals(existing.id)))
              .write(const CategoriesCompanion(isArchived: Value(false)));
          return existing.copyWith(isArchived: false);
        }

        final sortOrder = all.isEmpty
            ? 0
            : all.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
        final createdAt = _clock().toUtc();
        final id = await _db
            .into(_db.categories)
            .insert(
              CategoriesCompanion.insert(
                name: normalized,
                iconKey: iconKey,
                sortOrder: sortOrder,
                isPreset: false,
                createdAt: createdAt,
              ),
            );
        return Category(
          id: id,
          name: normalized,
          iconKey: iconKey,
          sortOrder: sortOrder,
          isPreset: false,
          isArchived: false,
          createdAt: createdAt,
        );
      }),
      translate: (code) => code == SqliteConstraint.unique
          ? DuplicateCategoryError(normalized)
          : null,
    );
  }

  @override
  Future<void> archive(int id) => guardDb(() async {
    final changed =
        await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
          const CategoriesCompanion(isArchived: Value(true)),
        );
    if (changed == 0) throw const CategoryNotFoundError();
  });
}
