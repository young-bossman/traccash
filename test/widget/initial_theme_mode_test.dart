import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/features/settings/data/settings_repository.dart';
import 'package:traccash/features/settings/presentation/settings_providers.dart';

import '../fakes/fake_settings_repository.dart';
import 'test_app.dart';

// testWidgets runs each body in a FakeAsync zone, so the 1-second timeout
// runs on the test's clock: it passes when the test pumps time, never on
// the wall clock. (The fake_async package is only a transitive dependency.)

/// A stored theme whose first value never arrives.
class _SilentSettings extends FakeSettingsRepository {
  @override
  Stream<ThemeMode> watchThemeMode() =>
      Stream.fromFuture(Completer<ThemeMode>().future);
}

/// A stored theme that can't be read.
class _UnreadableSettings extends FakeSettingsRepository {
  @override
  Stream<ThemeMode> watchThemeMode() => Stream.error(const StorageError());
}

/// A stored theme whose first value arrives when the test sends it.
class _LateSettings extends FakeSettingsRepository {
  final StreamController<ThemeMode> values =
      StreamController<ThemeMode>.broadcast();

  @override
  Stream<ThemeMode> watchThemeMode() => values.stream;

  @override
  Future<void> dispose() async {
    await values.close();
    await super.dispose();
  }
}

ProviderContainer _containerFor(FakeSettingsRepository settings) {
  addTearDown(settings.dispose);
  return ProviderContainer.test(
    overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
  );
}

/// Runs [body] with debugPrint recorded, restoring it before the test ends
/// (flutter_test checks that it was put back).
Future<List<String>> _recordDebugPrint(Future<void> Function() body) async {
  final printed = <String>[];
  final original = debugPrint;
  debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return printed;
}

void main() {
  group('readInitialThemeMode', () {
    testWidgets('returns a stored Dark choice', (tester) async {
      final container = _containerFor(
        FakeSettingsRepository(initial: ThemeMode.dark),
      );

      expect(await readInitialThemeMode(container), ThemeMode.dark);
    });

    testWidgets('returns System after 1 second when the first value never '
        'comes, and logs only the error type', (tester) async {
      final container = _containerFor(_SilentSettings());
      ThemeMode? result;

      final printed = await _recordDebugPrint(() async {
        unawaited(
          readInitialThemeMode(container).then((mode) => result = mode),
        );
        await tester.pump(const Duration(milliseconds: 999));
        expect(result, isNull, reason: 'still waiting at 999 ms');

        await tester.pump(const Duration(milliseconds: 1));
      });

      expect(result, ThemeMode.system);
      expect(printed, ['Theme mode not read at startup: TimeoutException']);
    });

    testWidgets('returns System when the repository throws, and logs only '
        'the error type', (tester) async {
      final container = _containerFor(_UnreadableSettings());
      ThemeMode? result;

      final printed = await _recordDebugPrint(() async {
        result = await readInitialThemeMode(container);
      });

      expect(result, ThemeMode.system);
      expect(printed, ['Theme mode not read at startup: StorageError']);
    });
  });

  testWidgets('after a timeout the app follows the device, then takes the '
      'stored choice when it arrives', (tester) async {
    final settings = _LateSettings();
    await pumpTestApp(
      tester,
      location: AppRoutes.settings,
      settingsRepository: () => settings,
    );
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.system);

    settings.values.add(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(app().themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
  });
}
