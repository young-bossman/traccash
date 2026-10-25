import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expense_form.dart';
import 'package:traccash/features/expenses/presentation/expenses_screen.dart';
import 'package:traccash/shared/selected_month.dart';

import 'form_test_helpers.dart';
import 'test_app.dart';

const String marketNote =
    'Market run: tomatoes, onions, rice, cooking oil and plantain for the '
    'week ahead';

/// GH₵ 186.50, Food, yesterday, with a long note: screenshot 08.
final List<ExpenseDraft> marketRun = [
  draft(18650, PresetIds.food, date: testToday.addDays(-1), note: marketNote),
];

/// GH₵ 45.00, Food, today: the delete dialog example.
final List<ExpenseDraft> lunch = [
  draft(4500, PresetIds.food, note: 'Waakye and egg'),
];

Future<void> tapDeleteAndConfirm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Delete expense'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
}

void main() {
  group('opening', () {
    testWidgets('edit: prefilled, with a delete action and no focus', (
      tester,
    ) async {
      await openEditForm(tester, seed: marketRun);

      expect(find.text('Edit expense'), findsOneWidget);
      expect(find.byTooltip('Delete expense'), findsOneWidget);
      expect(saveButton('Save changes'), findsOneWidget);
      expect(fieldText(tester, amountField), '186.50');
      expect(hasFocus(tester, amountField), isFalse);
      expect(isChosen('Food'), isTrue);
      expect(isChosen('Transport'), isFalse);
      expect(find.text('20/10/2026'), findsOneWidget);
      expect(find.text('Yesterday · Tuesday, 20 October 2026'), findsOneWidget);
      // The whole note, not the ledger's one-line cut.
      expect(fieldText(tester, noteField), marketNote);
      expect(find.text('${marketNote.runes.length} / 200'), findsOneWidget);
    });

    testWidgets('selected state is exposed to screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await openEditForm(tester, seed: marketRun);

      expect(
        tester.getSemantics(categoryOption('Food')),
        isSemantics(label: 'Food', isSelected: true, isButton: true),
      );
      expect(
        tester.getSemantics(categoryOption('Transport')),
        isSemantics(label: 'Transport', isSelected: false),
      );
      semantics.dispose();
    });

    testWidgets(
      'deleted elsewhere: a missing id shows "This expense no longer exists." '
      '(not in spec)',
      (tester) async {
        await openEditForm(tester, seed: marketRun, id: 99);

        expect(find.text('Expense not found'), findsOneWidget);
        expect(find.text('This expense no longer exists.'), findsOneWidget);
        expect(find.byType(ExpenseForm), findsNothing);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(ExpensesScreen), findsOneWidget);
      },
    );

    testWidgets('an archived category stays chosen on its old expense', (
      tester,
    ) async {
      final app = await pumpTestApp(tester, seed: marketRun);
      await app.categories.archive(PresetIds.food);
      unawaited(
        app.container.read(routerProvider).push(AppRoutes.editExpense(1)),
      );
      await tester.pumpAndSettle();

      expect(isChosen('Food'), isTrue);

      await tester.enterText(amountField, '190');
      await tester.tap(saveButton('Save changes'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseForm), findsNothing);
      expect((await app.expenses.getById(1))?.amountPesewas, 19000);
    });
  });

  group('saving', () {
    testWidgets('edit: update called once; "Changes saved"', (tester) async {
      final app = await openEditForm(tester, seed: marketRun);
      final original = await app.expenses.getById(1);

      await tester.enterText(amountField, '190');
      await tester.tap(saveButton('Save changes'));
      await tester.pumpAndSettle();

      expect(app.expenses.updateCalls, 1);
      expect(app.expenses.addCalls, 1); // the seed
      expect(find.byType(ExpenseForm), findsNothing);
      expect(find.text('Changes saved'), findsOneWidget);
      final saved = await app.expenses.getById(1);
      expect(saved?.amountPesewas, 19000);
      expect(saved?.createdAt, original?.createdAt);
      expect(saved?.note, marketNote);
    });

    testWidgets(
      'edit: saved to another month shows "Changes saved to September 2026" '
      'with View',
      (tester) async {
        final app = await openEditForm(tester, seed: marketRun);

        await tapInForm(tester, find.text('20/10/2026'));
        await pickDayLastMonth(tester, '30');
        await tester.tap(saveButton('Save changes'));
        await tester.pumpAndSettle();

        expect(find.text('Changes saved to September 2026'), findsOneWidget);
        expect(app.expenses.updateCalls, 1);

        await tester.tap(find.text('View'));
        await tester.pumpAndSettle();
        expect(
          app.container.read(selectedMonthProvider),
          const CalendarMonth(2026, 9),
        );
        expect(find.textContaining('Market run'), findsOneWidget);
      },
    );

    testWidgets('deleted elsewhere before Save: the banner says so', (
      tester,
    ) async {
      final app = await openEditForm(tester, seed: marketRun);
      await app.expenses.delete(1);

      await tester.enterText(amountField, '190');
      await tester.tap(saveButton('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t save this expense'), findsOneWidget);
      expect(find.text('This expense no longer exists.'), findsOneWidget);
      expect(find.text(storageBannerMessage), findsNothing);
      expect(fieldText(tester, amountField), '190');
    });
  });

  group('closing', () {
    testWidgets('an unchanged expense closes at once', (tester) async {
      await openEditForm(tester, seed: marketRun);

      await pressAndroidBack(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ExpenseForm), findsNothing);
    });

    testWidgets('the same amount written differently is not a change', (
      tester,
    ) async {
      await openEditForm(tester, seed: marketRun);
      await tester.enterText(amountField, '186.5');
      await tester.pump();

      await pressAndroidBack(tester);

      expect(find.byType(ExpenseForm), findsNothing);
    });

    testWidgets('a changed expense asks "Discard changes?"', (tester) async {
      final app = await openEditForm(tester, seed: marketRun);
      await tester.enterText(noteField, 'Market run');
      await tester.pump();

      await pressAndroidBack(tester);
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(
        find.text('Your edits to this expense won’t be saved.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseForm), findsNothing);
      expect((await app.expenses.getById(1))?.note, marketNote);
      expect(app.expenses.updateCalls, 0);
    });
  });

  group('delete', () {
    testWidgets(
      'delete: the dialog names the stored amount, category and date; Undo '
      'restores the same record',
      (tester) async {
        final app = await openEditForm(tester, seed: lunch);
        final original = await app.expenses.getById(1);
        // Unsaved edits don't change what the dialog describes.
        await tester.enterText(amountField, '99');
        await tester.pump();

        await tester.tap(find.byTooltip('Delete expense'));
        await tester.pumpAndSettle();
        expect(find.text('Delete this expense?'), findsOneWidget);
        expect(
          find.text(
            'GH₵ 45.00 for Food on 21 October will be removed from your '
            'records.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(find.byType(ExpenseForm), findsNothing);
        expect(find.text('Expense deleted'), findsOneWidget);
        expect(await app.expenses.getById(1), isNull);
        expect(find.text('Waakye and egg'), findsNothing);

        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        final restored = await app.expenses.getById(1);
        expect(restored, original);
        expect(restored?.createdAt, original?.createdAt);
        expect(find.text('Waakye and egg'), findsOneWidget);
        expect(find.text('Couldn’t restore the expense.'), findsNothing);
      },
    );

    testWidgets('Cancel keeps the expense and the form', (tester) async {
      final app = await openEditForm(tester, seed: lunch);

      await tester.tap(find.byTooltip('Delete expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseForm), findsOneWidget);
      expect(await app.expenses.getById(1), isNotNull);
    });

    testWidgets('Undo stays up for 5 seconds, then goes', (tester) async {
      final app = await openEditForm(tester, seed: lunch);
      await tapDeleteAndConfirm(tester);
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 4500));
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsNothing);
      expect(await app.expenses.getById(1), isNull);
    });

    testWidgets('with a screen reader, Undo stays up until used', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final app = await openEditForm(tester, seed: lunch);
      await tapDeleteAndConfirm(tester);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsNothing);
      expect(await app.expenses.getById(1), isNotNull);
    });

    testWidgets('an expense from another year names the year', (tester) async {
      await openEditForm(
        tester,
        seed: [draft(4500, PresetIds.food, date: LocalDate(2025, 10, 21))],
      );

      await tester.tap(find.byTooltip('Delete expense'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'GH₵ 45.00 for Food on 21 October 2025 will be removed from your '
          'records.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a failed delete shows the banner and keeps the expense', (
      tester,
    ) async {
      final app = await openEditForm(tester, seed: lunch);
      app.expenses.failNextWrite = true;

      await tapDeleteAndConfirm(tester);

      expect(find.byType(ExpenseForm), findsOneWidget);
      expect(find.text('Couldn’t save this expense'), findsOneWidget);
      expect(find.text(storageBannerMessage), findsOneWidget);
      expect(find.text('Expense deleted'), findsNothing);
      expect(await app.expenses.getById(1), isNotNull);
    });
  });
}
