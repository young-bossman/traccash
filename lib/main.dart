import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traccash/app/app.dart';
import 'package:traccash/core/formatting/dates.dart';

Future<void> main() async {
  await initializeDateFormatting(dateLocale);
  runApp(const ProviderScope(child: TracCashApp()));
}
