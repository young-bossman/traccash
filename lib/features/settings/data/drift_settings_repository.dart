import 'package:flutter/material.dart' show ThemeMode;
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/data/database/db_errors.dart';
import 'package:traccash/data/database/simulated_failure.dart';
import 'package:traccash/features/settings/data/settings_repository.dart';

const String themeModeKey = 'theme_mode';

// Spelled out rather than ThemeMode.name or index, so renaming or reordering
// the enum in a Flutter release can't change what is stored.
String themeModeToText(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'system',
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
};

/// Anything unrecognised falls back to following the device.
ThemeMode themeModeFromText(String? text) => switch (text) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

class DriftSettingsRepository implements SettingsRepository {
  /// [simulatedFailure] is the debug "Fail the next save" hook.
  DriftSettingsRepository(this._db, {this._simulatedFailure});

  final AppDatabase _db;
  final bool Function()? _simulatedFailure;

  @override
  Stream<ThemeMode> watchThemeMode() {
    final query = _db.select(_db.appSettings)
      ..where((s) => s.key.equals(themeModeKey));
    return guardDbStream(
      query.watchSingleOrNull().map((row) => themeModeFromText(row?.value)),
    );
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) => guardDb(() {
    throwIfSimulated(_simulatedFailure);
    return _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: themeModeKey,
            value: themeModeToText(mode),
          ),
        );
  });
}
