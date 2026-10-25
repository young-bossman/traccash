import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_theme.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/data/database/demo_seed.dart';
import 'package:traccash/data/database/simulated_failure.dart';
import 'package:traccash/features/expenses/presentation/expense_form.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/features/settings/data/settings_repository.dart';
import 'package:traccash/features/settings/presentation/settings_providers.dart';
import 'package:traccash/features/settings/presentation/settings_screen.dart';

import '../fakes/fake_settings_repository.dart';
import 'form_test_helpers.dart';
import 'test_app.dart';

// Content, behaviour and overflow in the Ahem test font; positions in real
// glyph widths are in settings_layout_test.

/// Tall enough that the whole Settings page is on screen.
const Size _tallPhone = Size(412, 1400);

Future<TestApp> _openSettings(
  WidgetTester tester, {
  ThemeMode themeMode = ThemeMode.system,
  FakeSettingsRepository Function()? settingsRepository,
  Future<String> Function()? appVersion,
  Future<int> Function()? seeder,
}) {
  setScreenSize(tester, _tallPhone);
  return pumpTestApp(
    tester,
    location: AppRoutes.settings,
    themeMode: themeMode,
    settingsRepository: settingsRepository,
    appVersion: appVersion,
    overrides: [
      if (seeder != null) demoSeederProvider.overrideWithValue(seeder),
    ],
  );
}

MaterialApp _materialApp(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(SettingsScreen))).brightness;

SegmentedButton<ThemeMode> _themeButton(WidgetTester tester) =>
    tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );

Switch _failSwitch(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch, skipOffstage: false));

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// A stored theme that can't be read.
class _UnreadableSettings extends FakeSettingsRepository {
  @override
  Stream<ThemeMode> watchThemeMode() => Stream.error(const StorageError());
}

void main() {
  group('Appearance', () {
    testWidgets('shows System, Light and Dark with the helper text; System '
        'is selected until a choice is stored', (tester) async {
      await _openSettings(tester);

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(
        find.text('System follows your device’s light or dark setting.'),
        findsOneWidget,
      );
      expect(_themeButton(tester).selected, {ThemeMode.system});
      // The check icon marks the choice, not colour alone.
      expect(
        find.descendant(
          of: find.widgetWithText(TextButton, 'System'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('choosing Dark persists and changes ThemeMode', (tester) async {
      final app = await _openSettings(tester);
      expect(_brightness(tester), Brightness.light);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(app.settings.themeMode, ThemeMode.dark);
      expect(_materialApp(tester).themeMode, ThemeMode.dark);
      expect(_brightness(tester), Brightness.dark);
      expect(_themeButton(tester).selected, {ThemeMode.dark});
    });

    testWidgets('choosing Light then System stores each choice', (
      tester,
    ) async {
      final app = await _openSettings(tester, themeMode: ThemeMode.dark);

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(app.settings.themeMode, ThemeMode.light);
      expect(_brightness(tester), Brightness.light);

      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(app.settings.themeMode, ThemeMode.system);
      expect(_materialApp(tester).themeMode, ThemeMode.system);
    });

    testWidgets('a stored Dark choice opens the app dark', (tester) async {
      await _openSettings(tester, themeMode: ThemeMode.dark);

      expect(_materialApp(tester).themeMode, ThemeMode.dark);
      expect(_brightness(tester), Brightness.dark);
      expect(_themeButton(tester).selected, {ThemeMode.dark});
    });

    testWidgets('System follows the device brightness live', (tester) async {
      await _openSettings(tester);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      expect(_brightness(tester), Brightness.light);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(_brightness(tester), Brightness.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(_brightness(tester), Brightness.light);
    });

    testWidgets('a stored Light choice ignores the device', (tester) async {
      await _openSettings(tester, themeMode: ThemeMode.light);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();

      expect(_brightness(tester), Brightness.light);
    });

    testWidgets('a failed theme write keeps the selection and shows the '
        'message', (tester) async {
      final app = await _openSettings(tester);
      app.settings.failNextWrite = true;

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(app.settings.themeMode, ThemeMode.system);
      expect(_themeButton(tester).selected, {ThemeMode.system});
      expect(_materialApp(tester).themeMode, ThemeMode.system);
      expect(_brightness(tester), Brightness.light);
      expect(
        find.text('Couldn’t save your theme choice. Try again.'),
        findsOneWidget,
      );
    });

    testWidgets('a theme that can’t be read: nothing selected, the error in '
        'place of the helper, the device followed, choices still offered', (
      tester,
    ) async {
      final app = await _openSettings(
        tester,
        settingsRepository: _UnreadableSettings.new,
      );

      expect(
        find.text(
          'Couldn’t load your theme choice, so TracCash is following your '
          'device.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('System follows your device’s light or dark setting.'),
        findsNothing,
      );
      expect(_themeButton(tester).selected, isEmpty);
      expect(_themeButton(tester).onSelectionChanged, isNotNull);
      expect(_materialApp(tester).themeMode, ThemeMode.system);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(app.settings.themeMode, ThemeMode.dark);
    });
  });

  group('General', () {
    testWidgets('shows currency, storage and the platform version', (
      tester,
    ) async {
      await _openSettings(tester);

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(
        find.text('Ghanaian cedi (GH₵) · fixed in this version'),
        findsOneWidget,
      );
      expect(find.text('Stored on this device'), findsOneWidget);
      expect(
        find.text(
          'Your expenses are kept in a local database on this phone. '
          'TracCash has no account and does not sync or upload them.',
        ),
        findsOneWidget,
      );
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('0.1.0 (1)'), findsOneWidget);
    });

    testWidgets('says "Not available" when the platform has no version', (
      tester,
    ) async {
      await _openSettings(
        tester,
        appVersion: () => Future.error(PlatformException(code: 'none')),
      );

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('Not available'), findsOneWidget);
    });
  });

  group('Developer', () {
    testWidgets('shows its heading, helper text and three tools', (
      tester,
    ) async {
      await _openSettings(tester);

      expect(find.text('Developer'), findsOneWidget);
      expect(
        find.text('Debug builds only. Not in the release app.'),
        findsOneWidget,
      );
      expect(find.text('Load demo data'), findsOneWidget);
      expect(
        find.text('Adds sample expenses when there are none yet.'),
        findsOneWidget,
      );
      expect(find.text('Clear all data'), findsOneWidget);
      expect(
        find.text('Deletes every expense and every category you created.'),
        findsOneWidget,
      );
      expect(find.text('Fail the next save'), findsOneWidget);
      expect(
        find.text('Simulates a local database error once.'),
        findsOneWidget,
      );
      expect(_failSwitch(tester).value, isFalse);
    });

    testWidgets('is hidden when showDeveloper is false', (tester) async {
      final settings = FakeSettingsRepository();
      addTearDown(settings.dispose);
      setScreenSize(tester, _tallPhone);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(settings),
            appVersionProvider.overrideWith((ref) => testAppVersion),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SettingsScreen(showDeveloper: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Developer', skipOffstage: false), findsNothing);
      expect(find.text('Load demo data', skipOffstage: false), findsNothing);
      expect(find.text('Clear all data', skipOffstage: false), findsNothing);
      expect(
        find.text('Fail the next save', skipOffstage: false),
        findsNothing,
      );
      expect(find.byType(Switch, skipOffstage: false), findsNothing);
    });

    group('Load demo data', () {
      testWidgets('loads demo data and confirms', (tester) async {
        var calls = 0;
        await _openSettings(
          tester,
          seeder: () async {
            calls++;
            return 41;
          },
        );

        await tester.tap(find.text('Load demo data'));
        await tester.pump();

        expect(calls, 1);
        expect(find.text('Loaded 41 demo expenses.'), findsOneWidget);
      });

      testWidgets('says so when expenses already exist', (tester) async {
        await _openSettings(tester, seeder: () async => 0);

        await tester.tap(find.text('Load demo data'));
        await tester.pump();

        expect(
          find.text('Demo data not loaded: there are already expenses.'),
          findsOneWidget,
        );
      });

      testWidgets('shows the friendly message when seeding fails', (
        tester,
      ) async {
        await _openSettings(
          tester,
          seeder: () async => throw const StorageError(),
        );

        await tester.tap(find.text('Load demo data'));
        await tester.pump();

        expect(
          find.text('Couldn’t read or save on this device. Try again.'),
          findsOneWidget,
        );
      });

      testWidgets('ignores Fail the next save: the seeder is not a '
          'repository write', (tester) async {
        final app = await _openSettings(tester, seeder: () async => 41);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Load demo data'));
        await tester.pump();

        expect(find.text('Loaded 41 demo expenses.'), findsOneWidget);
        expect(app.container.read(failNextWriteProvider), isTrue);
      });
    });

    group('Clear all data', () {
      /// Two expenses, one in a custom category the Expenses filter is set to.
      Future<int> seedCustom(TestApp app) async {
        final schoolFees = await app.categories.create(
          'School fees',
          'education',
        );
        await app.expenses.add(draft(4800, PresetIds.food));
        await app.expenses.add(draft(150000, schoolFees.id));
        app.container
            .read(expenseFiltersProvider.notifier)
            .setCategory(schoolFees.id);
        return schoolFees.id;
      }

      testWidgets('asks first; Cancel removes nothing', (tester) async {
        final app = await _openSettings(tester);
        final schoolFeesId = await seedCustom(app);

        await tester.tap(find.text('Clear all data'));
        await tester.pumpAndSettle();

        expect(find.text('Clear all data?'), findsOneWidget);
        expect(
          find.text(
            'Every expense and every category you created will be deleted. '
            'The 8 preset categories and your theme setting stay. This can’t '
            'be undone.',
          ),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Clear'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Clear all data?'), findsNothing);
        expect(await app.expenses.getById(1), isNotNull);
        expect(await app.expenses.getById(2), isNotNull);
        expect(app.categories.byId(schoolFeesId), isNotNull);
        expect(app.categories.categories, hasLength(9));
        expect(
          app.container.read(expenseFiltersProvider).categoryId,
          schoolFeesId,
        );
      });

      testWidgets('Clear removes expenses and custom categories, keeps the 8 '
          'presets and Dark, and resets the category filter', (tester) async {
        final app = await _openSettings(tester, themeMode: ThemeMode.dark);
        final schoolFeesId = await seedCustom(app);

        await tester.tap(find.text('Clear all data'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Clear'));
        await tester.pumpAndSettle();

        expect(await app.expenses.firstExpenseDate(), isNull);
        expect(app.categories.byId(schoolFeesId), isNull);
        expect(
          [for (final c in app.categories.categories) c.name],
          [
            'Food',
            'Transport',
            'Bills',
            'Data & Airtime',
            'Shopping',
            'Health',
            'Entertainment',
            'Other',
          ],
        );
        expect(app.settings.themeMode, ThemeMode.dark);
        expect(_brightness(tester), Brightness.dark);
        expect(app.container.read(expenseFiltersProvider).categoryId, isNull);
        expect(
          find.text('Cleared every expense and the categories you created.'),
          findsOneWidget,
        );
      });

      testWidgets('a failed clear keeps everything and shows the error', (
        tester,
      ) async {
        final app = await _openSettings(tester);
        final schoolFeesId = await seedCustom(app);
        app.expenses.failNextWrite = true;

        await tester.tap(find.text('Clear all data'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Clear'));
        await tester.pumpAndSettle();

        expect(
          find.text('Couldn’t read or save on this device. Try again.'),
          findsOneWidget,
        );
        expect(
          find.text('Cleared every expense and the categories you created.'),
          findsNothing,
        );
        expect(await app.expenses.getById(1), isNotNull);
        expect(app.categories.byId(schoolFeesId), isNotNull);
        expect(
          app.container.read(expenseFiltersProvider).categoryId,
          schoolFeesId,
        );
      });
    });

    group('Fail the next save', () {
      testWidgets('the switch, or a tap on its row, arms and disarms it', (
        tester,
      ) async {
        final app = await _openSettings(tester);

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(app.container.read(failNextWriteProvider), isTrue);
        expect(_failSwitch(tester).value, isTrue);

        await tester.tap(find.text('Fail the next save'));
        await tester.pumpAndSettle();
        expect(app.container.read(failNextWriteProvider), isFalse);
        expect(_failSwitch(tester).value, isFalse);
      });

      testWidgets('through the form: the next save shows the screen 12 '
          'banner and the switch turns off', (tester) async {
        final app = await _openSettings(tester);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        await _tapTab(tester, 'Expenses');
        await tester.tap(addExpenseButton);
        await tester.pumpAndSettle();
        await tester.enterText(amountField, '86.40');
        await tapInForm(tester, find.text('Food'));
        await tester.tap(saveButton('Save expense'));
        await tester.pumpAndSettle();

        expect(find.text('Couldn’t save this expense'), findsOneWidget);
        expect(
          find.text(
            'Nothing was written to the device. Your entry is still here, so '
            'you can try again.',
          ),
          findsOneWidget,
        );
        expect(find.byType(ExpenseForm), findsOneWidget);
        expect(await app.expenses.getById(1), isNull);
        expect(app.container.read(failNextWriteProvider), isFalse);

        // Only once: the retry saves.
        await tester.tap(saveButton('Save expense'));
        await tester.pumpAndSettle();
        expect(find.byType(ExpenseForm), findsNothing);
        expect(find.text('Expense saved'), findsOneWidget);
        expect(await app.expenses.getById(1), isNotNull);

        // Riverpod pauses hidden widgets; the switch redraws when Settings
        // is on screen again.
        await _tapTab(tester, 'Settings');
        expect(_failSwitch(tester).value, isFalse);
      });

      testWidgets('also fails the next theme write, once', (tester) async {
        final app = await _openSettings(tester);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(app.settings.themeMode, ThemeMode.system);
        expect(
          find.text('Couldn’t save your theme choice. Try again.'),
          findsOneWidget,
        );
        expect(_failSwitch(tester).value, isFalse);

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
        expect(app.settings.themeMode, ThemeMode.dark);
      });
    });
  });

  testWidgets('reduced motion: the Clear all data dialog and its snackbar '
      'appear without animating', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _openSettings(tester);

    await tester.tap(find.text('Clear all data'));
    await tester.pump();
    final dialog = ModalRoute.of(tester.element(find.text('Clear all data?')))!;
    expect(dialog.animation!.value, 1);

    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pump();
    await tester.pump();
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      find.text('Cleared every expense and the categories you created.'),
      findsOneWidget,
    );
    expect(snackBar.animation!.value, 1);
  });
}
