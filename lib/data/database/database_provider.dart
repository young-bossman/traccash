import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/data/database/app_database.dart';

/// The single database connection for the app.
///
/// Data tests build `AppDatabase(NativeDatabase.memory())` directly; widget
/// tests override the repository providers with fakes and never open this.
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(driftDatabase(name: 'traccash'));
  ref.onDispose(database.close);
  return database;
});
