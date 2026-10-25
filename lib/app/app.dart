import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_theme.dart';
import 'package:traccash/features/settings/presentation/settings_providers.dart';

/// Ghana writes dates day/month/year, which en_GB gives the date picker and
/// numeric dates.
const Locale appLocale = Locale('en', 'GB');

class TracCashApp extends ConsumerWidget {
  const TracCashApp({this.initialThemeMode = ThemeMode.system, super.key});

  /// Used until [themeModeProvider] has the stored choice; `main()` reads it
  /// with `readInitialThemeMode` before the first frame.
  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TracCash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // System follows the device's setting live, through MediaQuery.
      themeMode: ref.watch(themeModeProvider).value ?? initialThemeMode,
      // DESIGN_SPEC §7: a theme choice applies instantly, with no cross-fade,
      // which also covers reduced motion.
      themeAnimationStyle: AnimationStyle.noAnimation,
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
