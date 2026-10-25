import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/theme/app_theme.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/data/database/demo_seed.dart';
import 'package:traccash/features/settings/presentation/settings_screen.dart';

void main() {
  Future<void> pumpWithSeeder(
    WidgetTester tester,
    Future<int> Function() seeder,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [demoSeederProvider.overrideWithValue(seeder)],
        child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
      ),
    );
  }

  testWidgets('debug button loads demo data and confirms', (tester) async {
    var calls = 0;
    await pumpWithSeeder(tester, () async {
      calls++;
      return 41;
    });

    await tester.tap(find.text('Load demo data'));
    await tester.pump();

    expect(calls, 1);
    expect(find.text('Loaded 41 demo expenses.'), findsOneWidget);
  });

  testWidgets('says so when expenses already exist', (tester) async {
    await pumpWithSeeder(tester, () async => 0);

    await tester.tap(find.text('Load demo data'));
    await tester.pump();

    expect(
      find.text('Demo data not loaded: there are already expenses.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the friendly message when seeding fails', (tester) async {
    await pumpWithSeeder(tester, () async => throw const StorageError());

    await tester.tap(find.text('Load demo data'));
    await tester.pump();

    expect(find.text(const StorageError().message), findsOneWidget);
  });
}
