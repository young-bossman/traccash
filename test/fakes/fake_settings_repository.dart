import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/features/settings/data/settings_repository.dart';

import 'fake_streams.dart';

/// In-memory [SettingsRepository] for widget tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({ThemeMode initial = ThemeMode.system})
    : _themeMode = initial;

  ThemeMode _themeMode;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// When true, the next write throws [StorageError] and the flag resets.
  bool failNextWrite = false;

  ThemeMode get themeMode => _themeMode;

  Future<void> dispose() => _changes.close();

  @override
  Stream<ThemeMode> watchThemeMode() =>
      watchValue(_changes.stream, () => _themeMode);

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw const StorageError();
    }
    _themeMode = mode;
    _changes.add(null);
  }
}
