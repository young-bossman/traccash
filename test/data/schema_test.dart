import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/data/database/app_database.dart';

import '../generated_migrations/schema.dart';

// The snapshots in drift_schemas/ are what installed apps actually have. If
// these fail after a table change: bump schemaVersion, add a migration step,
// run `dart run drift_dev schema dump lib/data/database/app_database.dart
// drift_schemas/` and `dart run drift_dev schema generate drift_schemas/
// test/generated_migrations/`.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('a new install has exactly the schema of the latest snapshot', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Throws if the tables changed without a new snapshot, or if
    // schemaVersion was bumped without one.
    await verifier.migrateAndValidate(db, db.schemaVersion);
  });

  for (final version in GeneratedHelper.versions) {
    test('a v$version database migrates to the current schema', () async {
      final db = AppDatabase(await verifier.startAt(version));
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, db.schemaVersion);
    });
  }
}
