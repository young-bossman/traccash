import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_theme.dart';

/// Ghana writes dates day/month/year, which en_GB gives the date picker and
/// numeric dates.
const Locale appLocale = Locale('en', 'GB');

class TracCashApp extends ConsumerWidget {
  const TracCashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TracCash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follows the device until the Settings task stores a choice.
      themeMode: ThemeMode.system,
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
