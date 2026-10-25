import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/data/database/database_provider.dart';
import 'package:traccash/features/settings/data/drift_settings_repository.dart';

/// App preferences stored on the device. Errors are always `AppError`s.
abstract interface class SettingsRepository {
  /// The stored theme choice; [ThemeMode.system] until one is set.
  Stream<ThemeMode> watchThemeMode();

  Future<void> setThemeMode(ThemeMode mode);
}

/// Widget tests override this with a fake.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
    );
