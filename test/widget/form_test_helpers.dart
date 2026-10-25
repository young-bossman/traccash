import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/features/categories/presentation/category_picker.dart';
import 'package:traccash/features/categories/presentation/new_category_panel.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expense_form.dart';
import 'package:traccash/features/expenses/presentation/expense_form_fields.dart';

import 'test_app.dart';

Finder get amountField => find.byKey(ExpenseForm.amountKey);

Finder get noteField => find.byKey(ExpenseForm.noteKey);

Finder get newCategoryNameField => find.byKey(NewCategoryPanel.nameKey);

Finder get addExpenseButton =>
    find.widgetWithText(FloatingActionButton, 'Add expense');

Finder saveButton(String label) => find.widgetWithText(FilledButton, label);

/// The picker option labelled [name].
Finder categoryOption(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(OptionSurface));

/// Whether [name]'s option shows the selected check.
bool isChosen(String name) => find
    .descendant(of: categoryOption(name), matching: find.byIcon(Icons.check))
    .evaluate()
    .isNotEmpty;

String fieldText(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

bool hasFocus(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

const String storageBannerMessage = SaveErrorBanner.storageMessage;

/// Scrolls the form until [finder] is on screen, then taps it.
Future<void> tapInForm(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Opens Expenses, then the add form through the Add expense button.
Future<TestApp> openAddForm(
  WidgetTester tester, {
  List<ExpenseDraft> seed = const [],
}) async {
  final app = await pumpTestApp(
    tester,
    location: AppRoutes.expenses,
    seed: seed,
  );
  await tester.tap(addExpenseButton);
  await tester.pumpAndSettle();
  return app;
}

/// Opens Expenses, then the edit form for expense [id] on top of it.
Future<TestApp> openEditForm(
  WidgetTester tester, {
  required List<ExpenseDraft> seed,
  int id = 1,
}) async {
  final app = await pumpTestApp(
    tester,
    location: AppRoutes.expenses,
    seed: seed,
  );
  // Completes only when the form closes, so it isn't awaited here.
  unawaited(app.container.read(routerProvider).push(AppRoutes.editExpense(id)));
  await tester.pumpAndSettle();
  return app;
}

/// Picks [day] in the month before today's in the open date picker.
Future<void> pickDayLastMonth(WidgetTester tester, String day) async {
  await tester.tap(find.byTooltip('Previous month'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(CalendarDatePicker),
      matching: find.text(day),
    ),
  );
  await tester.tap(find.text('OK'));
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
