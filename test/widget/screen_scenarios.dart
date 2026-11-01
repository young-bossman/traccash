import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/features/reports/presentation/reports_providers.dart';

import '../fakes/fake_expense_repository.dart';
import 'form_test_helpers.dart';
import 'home_seed.dart';
import 'test_app.dart';

/// One screen in one state, opened from a fresh app in [ThemeMode].
///
/// Shared by the accessibility and text-scale tests, so both walk the same
/// screens, sheets and dialogs.
class Scenario {
  const Scenario(
    this.name,
    this.open, {
    required this.shows,
    this.typing = false,
  });

  final String name;
  final Future<void> Function(WidgetTester tester, ThemeMode theme) open;

  /// Found once [open] has reached the state, so a step that silently did
  /// nothing can't pass as a checked screen.
  final Finder shows;

  /// A text field can have focus here, so the keyboard may be open too.
  final bool typing;

  @override
  String toString() => name;
}

/// 200 characters, the most a note can hold.
final String longNote = '${'Long note ' * 19}Long note.';

/// The 01 month and the one before it, plus today's record at the cap with
/// the longest note: every populated view shows a large amount and a long
/// note. That record is [largeExpenseId].
final List<ExpenseDraft> busySeed = [
  ...september,
  ...october,
  draft(maxPesewas, PresetIds.other, note: longNote),
];

final int largeExpenseId = busySeed.length;

/// Every expense read fails, for the screens' error states.
class _FailingReads extends FakeExpenseRepository {
  _FailingReads(super.categories) : super(today: () => testToday);

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) =>
      Stream.error(const StorageError());
}

Future<TestApp> _pump(
  WidgetTester tester,
  ThemeMode theme, {
  String location = AppRoutes.home,
  List<ExpenseDraft> seed = const [],
  bool failingReads = false,
}) => pumpTestApp(
  tester,
  location: location,
  seed: seed,
  themeMode: theme,
  expenseRepository: failingReads ? _FailingReads.new : null,
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // A ListView builds only what is near the screen, so on a small screen the
  // target may not exist until the page scrolls towards it.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<TestApp> _openAdd(WidgetTester tester, ThemeMode theme) async {
  final app = await _pump(tester, theme, location: AppRoutes.expenses);
  await _tap(tester, addExpenseButton);
  return app;
}

Future<TestApp> _openEdit(WidgetTester tester, ThemeMode theme) async {
  final app = await _pump(
    tester,
    theme,
    location: AppRoutes.expenses,
    seed: busySeed,
  );
  // Completes only when the form closes, so it isn't awaited here.
  unawaited(
    app.container
        .read(routerProvider)
        .push(AppRoutes.editExpense(largeExpenseId)),
  );
  await tester.pumpAndSettle();
  return app;
}

final List<Scenario> scenarios = [
  Scenario(
    'Home',
    (tester, theme) => _pump(tester, theme, seed: busySeed),
    shows: find.textContaining('Long note'),
  ),
  Scenario('Home, first use', _pump, shows: find.text('No expenses yet')),
  Scenario(
    'Home, empty month',
    (tester, theme) => _pump(tester, theme, seed: september),
    shows: find.text('Nothing recorded so far this month.'),
  ),
  Scenario(
    'Home, load error',
    (tester, theme) => _pump(tester, theme, failingReads: true),
    shows: find.text('Couldn’t load expenses'),
  ),
  Scenario(
    'Expenses',
    (tester, theme) =>
        _pump(tester, theme, location: AppRoutes.expenses, seed: busySeed),
    shows: find.textContaining('Long note'),
  ),
  Scenario(
    'Expenses, filtered with no results',
    (tester, theme) async {
      final app = await _pump(
        tester,
        theme,
        location: AppRoutes.expenses,
        seed: busySeed,
      );
      app.container
          .read(expenseFiltersProvider.notifier)
          .setCategory(PresetIds.health);
      await tester.enterText(find.byType(TextField), 'nothing like this');
      await tester.pump(ExpenseFiltersNotifier.debounce);
      await tester.pumpAndSettle();
    },
    // In the summary line and under the no-results message.
    shows: find.text('Clear filters'),
    typing: true,
  ),
  Scenario(
    'Expenses, load error',
    (tester, theme) =>
        _pump(tester, theme, location: AppRoutes.expenses, failingReads: true),
    shows: find.text('Couldn’t load expenses'),
  ),
  Scenario('Category filter sheet', (tester, theme) async {
    await _pump(tester, theme, location: AppRoutes.expenses, seed: busySeed);
    await _tap(tester, find.byTooltip('Filter by category'));
  }, shows: find.text('All categories')),
  Scenario(
    'Reports, daily',
    (tester, theme) =>
        _pump(tester, theme, location: AppRoutes.reports, seed: busySeed),
    shows: find.byKey(const ValueKey(TrendPeriod.daily)),
  ),
  Scenario('Reports, monthly', (tester, theme) async {
    await _pump(tester, theme, location: AppRoutes.reports, seed: busySeed);
    await _tap(tester, find.text('Monthly'));
  }, shows: find.byKey(const ValueKey(TrendPeriod.monthly))),
  Scenario(
    'Reports, no data',
    (tester, theme) => _pump(tester, theme, location: AppRoutes.reports),
    shows: find.text('No spending to report'),
  ),
  Scenario(
    'Settings',
    (tester, theme) => _pump(tester, theme, location: AppRoutes.settings),
    shows: find.text('Appearance'),
  ),
  Scenario('Clear all data confirmation', (tester, theme) async {
    await _pump(tester, theme, location: AppRoutes.settings);
    await _tap(tester, find.text('Clear all data'));
  }, shows: find.text('Clear all data?')),
  Scenario(
    'Add expense, errors shown',
    (tester, theme) async {
      await _openAdd(tester, theme);
      await _tap(tester, saveButton('Save expense'));
    },
    shows: find.text(AmountError.empty.message),
    typing: true,
  ),
  Scenario(
    'Add expense, new category panel',
    (tester, theme) async {
      await _openAdd(tester, theme);
      await _tap(tester, find.text('New category'));
    },
    shows: newCategoryNameField,
    typing: true,
  ),
  Scenario(
    'Add expense, save failed',
    (tester, theme) async {
      final app = await _openAdd(tester, theme);
      await tester.enterText(amountField, '12.50');
      await _tap(tester, categoryOption('Food'));
      app.expenses.failNextWrite = true;
      await _tap(tester, saveButton('Save expense'));
    },
    shows: find.text('Couldn’t save this expense'),
    typing: true,
  ),
  Scenario('Add expense, date picker', (tester, theme) async {
    await _openAdd(tester, theme);
    await _tap(tester, find.text('21/10/2026'));
  }, shows: find.byType(DatePickerDialog)),
  Scenario('Discard confirmation', (tester, theme) async {
    await _openAdd(tester, theme);
    await tester.enterText(amountField, '12.50');
    await _tap(tester, find.byType(CloseButton));
  }, shows: find.text('Keep editing')),
  Scenario(
    'Edit expense, long note and large amount',
    _openEdit,
    shows: find.text(longNote),
    typing: true,
  ),
  Scenario('Delete confirmation', (tester, theme) async {
    await _openEdit(tester, theme);
    await _tap(tester, find.byTooltip('Delete expense'));
  }, shows: find.byType(AlertDialog)),
  Scenario('Expense deleted, with Undo', (tester, theme) async {
    await _openEdit(tester, theme);
    await _tap(tester, find.byTooltip('Delete expense'));
    await _tap(tester, find.text('Delete'));
  }, shows: find.text('Expense deleted')),
];
