import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/features/settings/data/drift_settings_repository.dart';

import 'data_test_helpers.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repo;

  setUp(() {
    db = openTestDatabase();
    repo = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  Future<String?> storedText() async {
    final row = await (db.select(
      db.appSettings,
    )..where((s) => s.key.equals(themeModeKey))).getSingleOrNull();
    return row?.value;
  }

  test('defaults to system when nothing is stored', () async {
    expect(await storedText(), isNull);
    expect(await repo.watchThemeMode().first, ThemeMode.system);
  });

  test('stores the explicit strings light, dark and system', () async {
    const expected = {
      ThemeMode.light: 'light',
      ThemeMode.dark: 'dark',
      ThemeMode.system: 'system',
    };
    for (final MapEntry(key: mode, value: text) in expected.entries) {
      await repo.setThemeMode(mode);
      expect(await storedText(), text);
      expect(await repo.watchThemeMode().first, mode);
    }
    final rows = await db.select(db.appSettings).get();
    expect(rows, hasLength(1), reason: 'upserted, not appended');
  });

  test('an unknown stored value means system', () async {
    await db
        .into(db.appSettings)
        .insert(AppSettingsCompanion.insert(key: themeModeKey, value: 'sepia'));

    expect(await repo.watchThemeMode().first, ThemeMode.system);
  });

  test('the stream emits each new choice', () async {
    final modes = StreamIterator(repo.watchThemeMode());
    expect(await nextValue(modes), ThemeMode.system);

    await repo.setThemeMode(ThemeMode.dark);
    expect(await nextValue(modes), ThemeMode.dark);

    await repo.setThemeMode(ThemeMode.light);
    expect(await nextValue(modes), ThemeMode.light);
    await modes.cancel();
  });
}
