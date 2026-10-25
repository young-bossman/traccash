import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/features/expenses/presentation/expenses_screen.dart';
import 'package:traccash/features/home/presentation/home_screen.dart';
import 'package:traccash/features/reports/presentation/reports_screen.dart';
import 'package:traccash/features/settings/presentation/settings_screen.dart';

import 'test_app.dart';

// Fake repositories, so opening the Expenses tab never touches a database.
Future<void> pumpApp(WidgetTester tester) => pumpTestApp(tester);

/// Tab labels also appear as screen titles, so tap inside the nav bar only.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Sends the same platform message Android's back button does.
Future<void> pressAndroidBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  testWidgets('app builds and opens on Home', (tester) async {
    await pumpApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(selectedTab(tester), 0);
  });

  testWidgets('every tab can be selected', (tester) async {
    await pumpApp(tester);

    // Ends on Home to check returning to a tab that was already built.
    const tabs = [
      ('Expenses', ExpensesScreen, 1),
      ('Reports', ReportsScreen, 2),
      ('Settings', SettingsScreen, 3),
      ('Home', HomeScreen, 0),
    ];

    for (final (label, screen, index) in tabs) {
      await tapTab(tester, label);

      // Inactive tabs stay alive offstage, and finders skip offstage widgets.
      expect(find.byType(screen), findsOneWidget, reason: label);
      expect(selectedTab(tester), index, reason: label);
    }
  });

  group('Android back', () {
    late List<String> platformCalls;

    setUp(() {
      platformCalls = [];
    });

    void recordPlatformCalls(WidgetTester tester) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
    }

    testWidgets('from another tab returns to Home', (tester) async {
      recordPlatformCalls(tester);
      await pumpApp(tester);
      await tapTab(tester, 'Reports');

      await pressAndroidBack(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(selectedTab(tester), 0);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('on Home exits the app', (tester) async {
      recordPlatformCalls(tester);
      await pumpApp(tester);

      await pressAndroidBack(tester);

      expect(platformCalls, contains('SystemNavigator.pop'));
    });
  });

  testWidgets('follows the device when it is in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpApp(tester);

    final context = tester.element(find.byType(HomeScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('uses the light theme when the device is light', (tester) async {
    await pumpApp(tester);

    final context = tester.element(find.byType(HomeScreen));
    expect(Theme.of(context).brightness, Brightness.light);
  });
}
