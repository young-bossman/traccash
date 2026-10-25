import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traccash/app/app.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/settings/presentation/settings_providers.dart';

Future<void> main() async {
  // The database is opened before runApp, and finding its file needs the
  // platform channels.
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(dateLocale);
  final container = ProviderContainer();
  final themeMode = await readInitialThemeMode(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TracCashApp(initialThemeMode: themeMode),
    ),
  );
}
