import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/app.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/simulated_failure.dart';
import 'package:traccash/features/categories/data/category_repository.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/settings/data/settings_repository.dart';
import 'package:traccash/features/settings/presentation/settings_providers.dart';
import 'package:traccash/shared/selected_month.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_expense_repository.dart';
import '../fakes/fake_settings_repository.dart';
import '../fakes/fixed_today.dart';

/// Wednesday, 21 October 2026: the day every widget test treats as today.
final LocalDate testToday = LocalDate(2026, 10, 21);

/// Preset ids in the fake category repository.
abstract final class PresetIds {
  static const int food = 1;
  static const int transport = 2;
  static const int bills = 3;
  static const int dataAirtime = 4;
  static const int shopping = 5;
  static const int health = 6;
  static const int entertainment = 7;
  static const int other = 8;
}

/// What Settings shows as the version in widget tests.
const String testAppVersion = '0.1.0 (1)';

/// The fakes behind a pumped app, for seeding and inspecting data.
class TestApp {
  TestApp._(this.container, this.categories, this.expenses, this.settings);

  final ProviderContainer container;
  final FakeCategoryRepository categories;
  final FakeExpenseRepository expenses;
  final FakeSettingsRepository settings;
}

/// Pumps the whole app on fake repositories, opened at [location].
///
/// [expenseRepository] and [settingsRepository] build fake subclasses, for
/// tests that need a stream that fails or never emits. [seed] is added
/// before the first frame. [themeMode] is the stored theme choice.
/// [appVersion] answers for the platform; [overrides] are added to the
/// fakes'. Pass `settle: false` when a spinner would keep `pumpAndSettle`
/// waiting.
Future<TestApp> pumpTestApp(
  WidgetTester tester, {
  String location = AppRoutes.home,
  List<ExpenseDraft> seed = const [],
  FakeExpenseRepository Function(FakeCategoryRepository categories)?
  expenseRepository,
  ThemeMode themeMode = ThemeMode.system,
  FakeSettingsRepository Function()? settingsRepository,
  Future<String> Function()? appVersion,
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  // Settings' "Fail the next save" reaches the default fakes as it reaches
  // the Drift repositories. Read lazily: the container is made below.
  late final ProviderContainer container;
  bool simulatedFailure() =>
      container.read(failNextWriteProvider.notifier).take();

  final categories = FakeCategoryRepository(simulatedFailure: simulatedFailure);
  final expenses =
      expenseRepository?.call(categories) ??
      FakeExpenseRepository(
        categories,
        today: () => testToday,
        simulatedFailure: simulatedFailure,
      );
  final settings =
      settingsRepository?.call() ??
      FakeSettingsRepository(
        initial: themeMode,
        simulatedFailure: simulatedFailure,
      );
  addTearDown(() async {
    await expenses.dispose();
    await categories.dispose();
    await settings.dispose();
  });

  container = ProviderContainer.test(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(expenses),
      categoryRepositoryProvider.overrideWithValue(categories),
      settingsRepositoryProvider.overrideWithValue(settings),
      todayProvider.overrideWith(() => FixedToday(testToday)),
      // Never asks the platform, which a test doesn't have.
      appVersionProvider.overrideWith(
        (ref) => appVersion?.call() ?? Future.value(testAppVersion),
      ),
      ...overrides,
    ],
  );
  // After the container: every write asks it about "Fail the next save".
  for (final draft in seed) {
    await expenses.add(draft);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TracCashApp()),
  );
  if (location != AppRoutes.home) {
    container.read(routerProvider).go(location);
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Route change, then the frame that shows the new route.
    await tester.pump();
    await tester.pump();
  }
  return TestApp._(container, categories, expenses, settings);
}

/// A new expense on [date] (default today) for seeding.
ExpenseDraft draft(
  int pesewas,
  int categoryId, {
  LocalDate? date,
  String? note,
}) => ExpenseDraft(
  amountPesewas: pesewas,
  categoryId: categoryId,
  occurredOn: date ?? testToday,
  note: note,
);

/// Sets the logical screen size for one test.
void setScreenSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}
