import 'package:drift/drift.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/local_date_converter.dart';
import 'package:traccash/data/database/tables.dart';
import 'package:traccash/features/categories/domain/category.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Expenses, AppSettings])
class AppDatabase extends _$AppDatabase {
  /// Takes the executor so tests can pass `NativeDatabase.memory()`.
  AppDatabase(super.executor);

  // Bump by one for every schema change, add a migration step, and export a
  // new snapshot to drift_schemas/. Never edit a released step.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedPresets();
    },
    beforeOpen: (details) async {
      // SQLite leaves foreign keys off unless every connection turns them on.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedPresets() async {
    final now = DateTime.now().toUtc();
    await batch((b) {
      b.insertAll(categories, [
        for (final (index, preset) in presetCategories.indexed)
          CategoriesCompanion.insert(
            name: preset.name,
            iconKey: preset.iconKey,
            sortOrder: index,
            isPreset: true,
            createdAt: now,
          ),
      ]);
    });
  }
}
