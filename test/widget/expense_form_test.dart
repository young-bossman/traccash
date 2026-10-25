import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/presentation/expense_form.dart';
import 'package:traccash/features/expenses/presentation/expenses_screen.dart';
import 'package:traccash/shared/selected_month.dart';

import 'form_test_helpers.dart';
import 'test_app.dart';

void main() {
  group('opening', () {
    testWidgets('Add expense opens an empty form with the amount focused', (
      tester,
    ) async {
      await openAddForm(tester);

      expect(find.text('Add expense'), findsOneWidget);
      expect(saveButton('Save expense'), findsOneWidget);
      expect(find.byTooltip('Delete expense'), findsNothing);
      expect(hasFocus(tester, amountField), isTrue);
      expect(fieldText(tester, amountField), isEmpty);
      expect(find.text('0.00'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.text('21/10/2026'), findsOneWidget);
      expect(find.text('Today · Wednesday, 21 October 2026'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
      expect(
        find.text('What was it for? For example, lunch at the office'),
        findsOneWidget,
      );
      expect(find.text('0 / 200'), findsOneWidget);
    });

    testWidgets('the date picker runs from 1 January 2000 to today', (
      tester,
    ) async {
      await openAddForm(tester);

      await tapInForm(tester, find.text('21/10/2026'));

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.firstDate, DateTime(2000));
      expect(picker.lastDate, DateTime(2026, 10, 21));
      expect(picker.initialDate, DateTime(2026, 10, 21));
    });
  });

  group('validation', () {
    testWidgets(
      'invalid save shows messages under each failing field, none before '
      'the first Save, then live',
      (tester) async {
        final app = await openAddForm(tester);

        await tester.enterText(amountField, '0');
        await tester.pump();
        expect(find.text(AmountError.zero.message), findsNothing);

        await tester.tap(saveButton('Save expense'));
        await tester.pumpAndSettle();
        expect(find.text('Amount must be more than GH₵ 0.00.'), findsOneWidget);
        expect(find.text('Choose a category.'), findsOneWidget);
        expect(app.expenses.addCalls, 0);
        expect(find.byType(ExpenseForm), findsOneWidget);

        // From now on the messages follow the input.
        await tester.enterText(amountField, '12,50');
        await tester.pump();
        expect(
          find.text('Use a dot for pesewas, for example 12.50.'),
          findsOneWidget,
        );
        expect(find.text(AmountError.zero.message), findsNothing);

        await tester.enterText(amountField, '1000000.01');
        await tester.pump();
        expect(
          find.text('Amount must be at most GH₵ 1,000,000.00.'),
          findsOneWidget,
        );

        // Letters never reach the field.
        await tester.enterText(amountField, 'abc');
        await tester.pump();
        expect(fieldText(tester, amountField), isEmpty);
        expect(find.text('Enter an amount.'), findsOneWidget);

        await tester.enterText(amountField, '45');
        await tester.pump();
        expect(find.text('Enter an amount.'), findsNothing);

        await tapInForm(tester, find.text('Food'));
        expect(find.text('Choose a category.'), findsNothing);
        expect(isChosen('Food'), isTrue);
      },
    );

    testWidgets('the note counts code points and stops at 200', (tester) async {
      await openAddForm(tester);

      await tester.enterText(noteField, 'a' * 250);
      await tester.pump();
      expect(fieldText(tester, noteField), 'a' * 200);
      expect(find.text('200 / 200'), findsOneWidget);

      // Rainbow flag: one character on screen, four code points.
      await tester.enterText(noteField, '\u{1F3F3}\u{FE0F}\u{200D}\u{1F308}');
      await tester.pump();
      expect(find.text('4 / 200'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('valid save calls add exactly once on a double tap', (
      tester,
    ) async {
      final app = await openAddForm(tester);
      await tester.enterText(amountField, '45');
      await tapInForm(tester, find.text('Food'));
      app.expenses.writeGate = Completer<void>();

      await tester.tap(saveButton('Save expense'));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(saveButton('Saving…')).onPressed,
        null,
      );

      await tester.tap(saveButton('Saving…'), warnIfMissed: false);
      await tester.pump();
      expect(app.expenses.addCalls, 1);

      app.expenses.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(app.expenses.addCalls, 1);
      expect(find.byType(ExpenseForm), findsNothing);
      expect(find.text('Expense saved'), findsOneWidget);
      final saved = await app.expenses.getById(1);
      expect(saved?.amountPesewas, 4500);
      expect(saved?.category.name, 'Food');
      expect(saved?.occurredOn, testToday);
      expect(saved?.note, isNull);
    });

    testWidgets('two taps in the same frame also call add once', (
      tester,
    ) async {
      final app = await openAddForm(tester);
      await tester.enterText(amountField, '45');
      await tapInForm(tester, find.text('Food'));
      app.expenses.writeGate = Completer<void>();

      // No pump between: the button has not been redrawn as disabled yet.
      await tester.tap(saveButton('Save expense'));
      await tester.tap(saveButton('Save expense'));
      await tester.pump();
      expect(app.expenses.addCalls, 1);

      app.expenses.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(app.expenses.addCalls, 1);
    });

    testWidgets(
      'failed save keeps all values and shows the banner; a retry succeeds',
      (tester) async {
        final app = await openAddForm(tester);
        await tester.enterText(amountField, '86.40');
        await tapInForm(tester, find.text('Food'));
        await tester.enterText(noteField, 'Groceries at Makola');
        app.expenses.failNextWrite = true;

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
        expect(fieldText(tester, amountField), '86.40');
        expect(fieldText(tester, noteField), 'Groceries at Makola');
        expect(isChosen('Food'), isTrue);
        expect(find.text('21/10/2026'), findsOneWidget);
        expect(find.text('Expense saved'), findsNothing);
        expect(await app.expenses.getById(1), isNull);

        await tester.tap(saveButton('Save expense'));
        await tester.pumpAndSettle();
        expect(find.byType(ExpenseForm), findsNothing);
        expect(find.text('Expense saved'), findsOneWidget);
        expect(app.expenses.addCalls, 2);
        expect((await app.expenses.getById(1))?.note, 'Groceries at Makola');
      },
    );

    testWidgets('the banner shows any other AppError’s own message', (
      tester,
    ) async {
      final app = await openAddForm(tester);
      await tester.enterText(amountField, '30');
      await tapInForm(tester, find.text('Health'));
      // Archived after it was chosen, so the repository refuses it.
      await app.categories.archive(PresetIds.health);
      await tester.pumpAndSettle();

      await tester.tap(saveButton('Save expense'));
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t save this expense'), findsOneWidget);
      expect(
        find.text('That category is no longer available. Choose another.'),
        findsOneWidget,
      );
      expect(find.text(storageBannerMessage), findsNothing);
      expect(fieldText(tester, amountField), '30');
    });

    testWidgets('saving to last month says so, and View switches to it', (
      tester,
    ) async {
      final app = await openAddForm(tester);
      await tester.enterText(amountField, '25');
      await tapInForm(tester, find.text('Transport'));
      await tester.enterText(noteField, 'Trotro to Kaneshie');
      await tapInForm(tester, find.text('21/10/2026'));
      await pickDayLastMonth(tester, '30');
      expect(find.text('30/09/2026'), findsOneWidget);
      expect(find.text('Wednesday, 30 September 2026'), findsOneWidget);

      await tester.tap(saveButton('Save expense'));
      await tester.pumpAndSettle();
      expect(find.text('Expense saved to September 2026'), findsOneWidget);
      expect(find.text('Trotro to Kaneshie'), findsNothing);

      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(
        app.container.read(selectedMonthProvider),
        const CalendarMonth(2026, 9),
      );
      // Still on the Expenses tab, now showing September.
      expect(find.byType(ExpensesScreen), findsOneWidget);
      expect(find.text('Trotro to Kaneshie'), findsOneWidget);
    });

    testWidgets('with a screen reader, View stays up until used', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final app = await openAddForm(tester);
      await tester.enterText(amountField, '25');
      await tapInForm(tester, find.text('Transport'));
      await tapInForm(tester, find.text('21/10/2026'));
      await pickDayLastMonth(tester, '30');
      await tester.tap(saveButton('Save expense'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Expense saved to September 2026'), findsOneWidget);
      expect(
        app.container.read(selectedMonthProvider),
        const CalendarMonth(2026, 10),
      );

      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(
        app.container.read(selectedMonthProvider),
        const CalendarMonth(2026, 9),
      );
    });
  });

  group('closing', () {
    testWidgets('an untouched form closes at once', (tester) async {
      await openAddForm(tester);

      await pressAndroidBack(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ExpenseForm), findsNothing);
      expect(find.byType(ExpensesScreen), findsOneWidget);
    });

    testWidgets(
      'discard dialog appears when there are changes; Keep editing stays, '
      'Discard closes',
      (tester) async {
        final app = await openAddForm(tester);
        await tester.enterText(amountField, '12');
        await tester.pump();

        await pressAndroidBack(tester);
        expect(find.text('Discard this expense?'), findsOneWidget);
        expect(
          find.text('What you entered hasn’t been saved.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Keep editing'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(fieldText(tester, amountField), '12');

        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();
        expect(find.byType(ExpenseForm), findsNothing);
        expect(find.byType(ExpensesScreen), findsOneWidget);
        expect(app.expenses.addCalls, 0);
      },
    );

    testWidgets('text in the new-category panel counts as a change', (
      tester,
    ) async {
      await openAddForm(tester);
      await tapInForm(tester, find.text('New category'));

      // Open but empty is not a change.
      await pressAndroidBack(tester);
      expect(find.byType(ExpenseForm), findsNothing);

      await tester.tap(addExpenseButton);
      await tester.pumpAndSettle();
      await tapInForm(tester, find.text('New category'));
      await tester.enterText(newCategoryNameField, 'School');
      await tester.pump();

      await pressAndroidBack(tester);
      expect(find.text('Discard this expense?'), findsOneWidget);
    });
  });

  group('motion', () {
    testWidgets('the form slides up', (tester) async {
      await pumpTestApp(tester, location: AppRoutes.expenses);

      await tester.tap(addExpenseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.getTopLeft(find.byType(ExpenseForm)).dy, greaterThan(0));

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(ExpenseForm)).dy, 0);
    });

    testWidgets('reduced motion: the form opens with no transition', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpTestApp(tester, location: AppRoutes.expenses);

      await tester.tap(addExpenseButton);
      await tester.pump();

      expect(find.byType(ExpenseForm), findsOneWidget);
      expect(tester.getTopLeft(find.byType(ExpenseForm)).dy, 0);
    });
  });

  testWidgets(
    '320dp, text scale 2.0, keyboard open: Save visible, no overflow',
    (tester) async {
      setScreenSize(tester, const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openAddForm(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final save = tester.getRect(saveButton('Save expense'));
      expect(save.top, greaterThan(0));
      expect(save.bottom, lessThanOrEqualTo(640 - 300));

      // The tallest the form gets: every message and the open panel.
      await tester.enterText(amountField, '1000000.01');
      await tester.tap(saveButton('Save expense'));
      await tester.pumpAndSettle();
      await tapInForm(tester, find.text('New category'));
      await tapInForm(tester, find.text('Add category'));
      expect(find.text('Enter a category name.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(saveButton('Save expense')).bottom,
        lessThanOrEqualTo(640 - 300),
      );
    },
  );
}
