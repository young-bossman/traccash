import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expense_form_screen.dart';
import 'package:traccash/features/expenses/presentation/expense_tile.dart';
import 'package:traccash/features/expenses/presentation/expenses_header.dart';
import 'package:traccash/features/expenses/presentation/expenses_screen.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_expense_repository.dart';
import 'test_app.dart';

/// Today 57.00, yesterday 50.00, Monday 19 Oct 35.00: GH₵ 142.00 in October.
final List<ExpenseDraft> october = [
  draft(4500, PresetIds.food, note: 'Waakye and egg, lunch'),
  draft(1200, PresetIds.transport, note: 'Trotro, Madina to Circle'),
  draft(
    5000,
    PresetIds.dataAirtime,
    date: testToday.addDays(-1),
    note: 'MTN data bundle',
  ),
  draft(
    3500,
    PresetIds.transport,
    date: LocalDate(2026, 10, 19),
    note: 'Ride to Airport City',
  ),
];

Future<TestApp> pumpExpenses(
  WidgetTester tester, {
  List<ExpenseDraft> seed = const [],
  FakeExpenseRepository Function(FakeCategoryRepository categories)?
  expenseRepository,
  bool settle = true,
}) {
  return pumpTestApp(
    tester,
    location: AppRoutes.expenses,
    seed: seed,
    expenseRepository: expenseRepository,
    settle: settle,
  );
}

Finder get searchField => find.byType(TextField);

Future<void> search(WidgetTester tester, String text) async {
  await tester.enterText(searchField, text);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}

Future<void> chooseCategory(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Filter by category'));
  await tester.pumpAndSettle();
  final option = find.descendant(
    of: find.byType(RadioListTile<int?>),
    matching: find.text(name),
  );
  // The sheet scrolls when the categories don't all fit.
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
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

/// A fake whose month stream can be replaced, to show loading and error
/// states. Months [watch] returns null for use the normal fake stream.
class _MonthStreamOverride extends FakeExpenseRepository {
  _MonthStreamOverride(super.categories, this.watch)
    : super(today: () => testToday);

  final Stream<List<Expense>>? Function(CalendarMonth month) watch;

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) =>
      watch(month) ?? super.watchMonth(month);
}

void main() {
  group('ledger', () {
    testWidgets('groups rows by day with pinned headers and day totals', (
      tester,
    ) async {
      setScreenSize(tester, const Size(412, 1400));
      await pumpExpenses(tester, seed: october);

      expect(find.text('GH₵ 142.00 · 4 expenses'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('GH₵ 57.00'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      // Yesterday's only expense: once as the day total, once in the row.
      expect(find.text('GH₵ 50.00'), findsNWidgets(2));
      expect(find.text('Monday, 19 October'), findsOneWidget);
      expect(find.text('Waakye and egg, lunch'), findsOneWidget);

      final today = tester.getTopLeft(find.text('Today')).dy;
      final yesterday = tester.getTopLeft(find.text('Yesterday')).dy;
      final monday = tester.getTopLeft(find.text('Monday, 19 October')).dy;
      expect(today, lessThan(yesterday));
      expect(yesterday, lessThan(monday));

      // Rows are keyed by expense id, never list position.
      expect(find.byType(ExpenseTile), findsNWidgets(4));
      for (var id = 1; id <= 4; id++) {
        expect(find.byKey(ValueKey(id)), findsOneWidget);
      }
    });

    testWidgets('a day header stays pinned while its rows scroll', (
      tester,
    ) async {
      setScreenSize(tester, const Size(412, 800));
      await pumpExpenses(
        tester,
        seed: [
          draft(900, PresetIds.food, date: testToday.addDays(-1)),
          for (var i = 1; i <= 12; i++) draft(i * 100, PresetIds.transport),
        ],
      );
      final ledgerTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Today')).dy, greaterThan(ledgerTop));
      expect(
        tester.getTopLeft(find.text('Today')).dy,
        lessThan(ledgerTop + AppSpacing.s12),
      );
    });

    testWidgets('summary says "1 expense" for one', (tester) async {
      await pumpExpenses(tester, seed: [draft(1200, PresetIds.transport)]);

      expect(find.text('GH₵ 12.00 · 1 expense'), findsOneWidget);
    });

    testWidgets('a long note stays on one line with an ellipsis', (
      tester,
    ) async {
      final note = 'Market run: tomatoes, onions, pepper, garden eggs ' * 3;
      await pumpExpenses(
        tester,
        seed: [draft(18650, PresetIds.food, note: note)],
      );

      final text = tester.widget<Text>(find.text(note.trim()));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      // One bodySmall line (13/18).
      expect(tester.getSize(find.text(note.trim())).height, 18);
    });

    testWidgets('tapping a row opens the edit form for that expense', (
      tester,
    ) async {
      await pumpExpenses(tester, seed: october);

      await tester.tap(find.text('MTN data bundle'));
      await tester.pumpAndSettle();

      final form = tester.widget<ExpenseFormScreen>(
        find.byType(ExpenseFormScreen),
      );
      expect(form.expenseId, 3);
      expect(find.text('Edit expense'), findsOneWidget);
    });

    testWidgets('Add expense opens the form and back returns to the list', (
      tester,
    ) async {
      await pumpExpenses(tester, seed: october);

      await tester.tap(
        find.widgetWithText(FloatingActionButton, 'Add expense'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseFormScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await pressAndroidBack(tester);

      expect(find.byType(ExpenseFormScreen), findsNothing);
      expect(find.byType(ExpensesScreen), findsOneWidget);
      expect(find.text('GH₵ 142.00 · 4 expenses'), findsOneWidget);
    });

    testWidgets('a double tap on Add expense opens one form', (tester) async {
      await pumpExpenses(tester, seed: october);
      final fab = find.widgetWithText(FloatingActionButton, 'Add expense');

      await tester.tap(fab);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(fab, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseFormScreen), findsOneWidget);
      await pressAndroidBack(tester);
      expect(find.byType(ExpenseFormScreen), findsNothing);
    });
  });

  group('states', () {
    testWidgets('first use shows "No expenses yet" without search', (
      tester,
    ) async {
      await pumpExpenses(tester);

      expect(find.text('No expenses yet'), findsOneWidget);
      expect(find.text('GH₵ 0.00 · 0 expenses'), findsOneWidget);
      expect(searchField, findsNothing);
      expect(find.widgetWithText(FilledButton, 'Add expense'), findsOneWidget);
    });

    testWidgets('an empty month says so, and other months still show', (
      tester,
    ) async {
      await pumpExpenses(
        tester,
        seed: [draft(2000, PresetIds.bills, date: LocalDate(2026, 9, 30))],
      );

      expect(find.text('No expenses in October 2026'), findsOneWidget);
      expect(find.text('GH₵ 0.00 · 0 expenses'), findsOneWidget);
      expect(searchField, findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text('Sep 2026'), findsOneWidget);
      expect(find.text('GH₵ 20.00 · 1 expense'), findsOneWidget);
      expect(find.text('Wednesday, 30 September'), findsOneWidget);
    });

    testWidgets('next month is disabled at the current month', (tester) async {
      await pumpExpenses(tester, seed: october);

      IconButton next() => tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(find.text('Oct 2026'), findsOneWidget);
      expect(next().onPressed, isNull);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(next().onPressed, isNotNull);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('Oct 2026'), findsOneWidget);
      expect(next().onPressed, isNull);
    });

    testWidgets('loading shows a spinner and no figures', (tester) async {
      final never = StreamController<List<Expense>>();
      addTearDown(never.close);
      await pumpExpenses(
        tester,
        expenseRepository: (categories) =>
            _MonthStreamOverride(categories, (_) => never.stream),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('GH₵'), findsNothing);
      expect(find.text('Oct 2026'), findsOneWidget);
    });

    testWidgets('changing month never shows the old month under the new '
        'label', (tester) async {
      final september = StreamController<List<Expense>>();
      addTearDown(september.close);
      await pumpExpenses(
        tester,
        seed: october,
        expenseRepository: (categories) => _MonthStreamOverride(
          categories,
          (month) =>
              month == const CalendarMonth(2026, 9) ? september.stream : null,
        ),
      );
      expect(find.text('GH₵ 142.00 · 4 expenses'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pump();

      expect(find.text('Sep 2026'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('GH₵'), findsNothing);
    });

    testWidgets('a storage error shows the friendly message', (tester) async {
      await pumpExpenses(
        tester,
        expenseRepository: (categories) => _MonthStreamOverride(
          categories,
          (_) => Stream.error(const StorageError()),
        ),
      );

      expect(find.text('Couldn’t load expenses'), findsOneWidget);
      expect(find.text(const StorageError().message), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('waits for typing to pause before filtering', (tester) async {
      await pumpExpenses(tester, seed: october);

      await tester.enterText(searchField, 'trotro');
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('GH₵ 142.00 · 4 expenses'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('GH₵ 12.00 · 1 of 4 expenses'), findsOneWidget);
      expect(find.text('Trotro, Madina to Circle'), findsOneWidget);
      expect(find.text('Waakye and egg, lunch'), findsNothing);
    });

    testWidgets('matches category names ignoring case', (tester) async {
      await pumpExpenses(tester, seed: october);

      await search(tester, 'TRANSPORT');

      expect(find.text('GH₵ 47.00 · 2 of 4 expenses'), findsOneWidget);
    });

    testWidgets('no results, then Clear filters restores the month', (
      tester,
    ) async {
      await pumpExpenses(tester, seed: october);

      await search(tester, '  pizza ');

      expect(find.text('GH₵ 0.00 · 0 of 4 expenses'), findsOneWidget);
      expect(find.text('No matching expenses'), findsOneWidget);
      expect(
        find.text('Nothing in October 2026 matches “pizza”.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Clear filters'));
      await tester.pump();

      expect(find.text('GH₵ 142.00 · 4 expenses'), findsOneWidget);
      expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('the clear button empties the search at once', (tester) async {
      await pumpExpenses(tester, seed: october);
      await search(tester, 'pizza');

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(find.text('GH₵ 142.00 · 4 expenses'), findsOneWidget);
    });
  });

  group('category filter', () {
    testWidgets('lists every active category with its count for the month', (
      tester,
    ) async {
      await pumpExpenses(tester, seed: october);

      await tester.tap(find.byTooltip('Filter by category'));
      await tester.pumpAndSettle();

      expect(find.text('Filter by category'), findsWidgets);
      expect(find.byType(RadioListTile<int?>), findsNWidgets(9));
      String countFor(String name) {
        final tile = find.ancestor(
          of: find.text(name),
          matching: find.byType(RadioListTile<int?>),
        );
        return tester
            .widget<Text>(
              find.descendant(of: tile, matching: find.byType(Text)).last,
            )
            .data!;
      }

      expect(countFor('All categories'), '4');
      expect(countFor('Transport'), '2');
      expect(countFor('Food'), '1');
      expect(countFor('Health'), '0');
    });

    testWidgets('choosing a category changes the summary and shows a chip', (
      tester,
    ) async {
      await pumpExpenses(tester, seed: october);

      await chooseCategory(tester, 'Transport');

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('GH₵ 47.00 · 2 of 4 expenses'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Transport'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Clear filters'), findsOneWidget);
      expect(find.text('Waakye and egg, lunch'), findsNothing);

      // The chip's × removes the category filter.
      await tester.tap(find.byTooltip('Remove Transport filter'));
      await tester.pump();

      expect(find.text('GH₵ 142.00 · 4 expenses'), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('a category with nothing this month says so', (tester) async {
      await pumpExpenses(tester, seed: october);

      await chooseCategory(tester, 'Health');

      expect(find.text('No matching expenses'), findsOneWidget);
      expect(find.text('No Health expenses in October 2026.'), findsOneWidget);
    });

    testWidgets('search and category together name both', (tester) async {
      await pumpExpenses(tester, seed: october);

      await chooseCategory(tester, 'Transport');
      await search(tester, 'pizza');

      expect(
        find.text('Nothing in October 2026 matches “pizza” in Transport.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Clear filters'));
      await tester.pump();

      expect(find.text('GH₵ 142.00 · 4 expenses'), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);
    });
  });

  group('layout', () {
    testWidgets('320dp, text scale 2.0 and the keyboard open: no overflow', (
      tester,
    ) async {
      setScreenSize(tester, const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final app = await pumpExpenses(
        tester,
        seed: [
          draft(
            100000000,
            PresetIds.bills,
            note: 'A very long note about a very large payment ' * 4,
          ),
          ...october,
        ],
      );
      final school = await app.categories.create(
        'Kids school uniforms',
        'education',
      );
      await app.expenses.add(draft(450000, school.id));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await chooseCategory(tester, 'Kids school uniforms');
      expect(tester.takeException(), isNull);

      final header = find.byType(ExpensesHeader);
      final headerHeight = tester.getSize(header).height;

      await tester.showKeyboard(searchField);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The header keeps its height; the ledger below gave up the space.
      expect(tester.getSize(header).height, headerHeight);
      final ledger = find.byType(CustomScrollView);
      expect(
        tester.getSize(ledger).height,
        lessThan(tester.getSize(header).height),
      );
    });

    // Where the amount sits is tested with real fonts in expense_tile_test.
    testWidgets('a GH₵ 1,000,000.00 day shows its total and row at 360dp '
        'without overflow', (tester) async {
      setScreenSize(tester, const Size(360, 800));
      await pumpExpenses(
        tester,
        seed: [draft(100000000, PresetIds.bills, note: 'Land')],
      );

      expect(tester.takeException(), isNull);
      // Day total and row.
      expect(find.text('GH₵ 1,000,000.00'), findsNWidgets(2));
    });
  });
}
