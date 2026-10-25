import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/features/settings/data/settings_repository.dart';

/// The stored theme choice. The app applies it and Settings shows it.
final StreamProvider<ThemeMode> themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref.watch(settingsRepositoryProvider).watchThemeMode(),
  retry: noRetry,
);

/// "0.1.0 (1)": the version name and build number Android reports for the
/// installed app. Widget tests override it.
final FutureProvider<String> appVersionProvider = FutureProvider<String>((
  ref,
) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}, retry: noRetry);

/// Waits up to [timeout] for the stored theme choice, so the first frame is
/// already in it: a Dark choice never opens in Light for a moment.
///
/// Returns [ThemeMode.system] when the choice can't be read in time. That is
/// never fatal: the app follows the device until [themeModeProvider] has a
/// value, and Settings shows a read error if there is one.
Future<ThemeMode> readInitialThemeMode(
  ProviderContainer container, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  // Listened to rather than read: Riverpod pauses a stream provider that
  // nothing listens to, and its first value would never arrive.
  final subscription = container.listen(themeModeProvider.future, (_, _) {});
  try {
    return await subscription.read().timeout(timeout);
  } catch (error) {
    // Everything is caught, bugs included: the app must still open. A read
    // error also stays in themeModeProvider, where Settings reports it.
    if (kDebugMode) {
      debugPrint('Theme mode not read at startup: ${error.runtimeType}');
    }
    return ThemeMode.system;
  } finally {
    subscription.close();
  }
}
