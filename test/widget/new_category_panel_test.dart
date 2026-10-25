import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/categories/presentation/new_category_panel.dart';
import 'package:traccash/features/expenses/presentation/expense_form.dart';

import 'form_test_helpers.dart';
import 'test_app.dart';

Future<void> openPanel(WidgetTester tester) =>
    tapInForm(tester, find.text('New category'));

Future<void> typeName(WidgetTester tester, String name) async {
  await tester.enterText(newCategoryNameField, name);
  await tester.pump();
}

Future<void> tapAdd(WidgetTester tester) =>
    tapInForm(tester, find.text('Add category'));

Category? named(TestApp app, String name) {
  for (final category in app.categories.categories) {
    if (category.name == name) return category;
  }
  return null;
}

void main() {
  testWidgets('New category opens the panel with its name focused', (
    tester,
  ) async {
    await openAddForm(tester);

    await openPanel(tester);

    expect(find.byType(NewCategoryPanel), findsOneWidget);
    expect(find.text('For example, School fees'), findsOneWidget);
    expect(find.text('0 / 20'), findsOneWidget);
    expect(hasFocus(tester, newCategoryNameField), isTrue);
    // The dashed option is replaced by the panel while it is open.
    expect(find.text('New category'), findsOneWidget);
    for (final icon in [
      'Tag',
      'Home',
      'Family',
      'Education',
      'Gifts',
      'Fuel',
      'Personal care',
      'Work',
    ]) {
      expect(find.byTooltip(icon), findsOneWidget, reason: icon);
    }
  });

  testWidgets(
    'new category: an empty name says "Enter a category name." after Add, '
    'then live',
    (tester) async {
      final app = await openAddForm(tester);
      await openPanel(tester);
      await typeName(tester, '   ');
      expect(find.text('Enter a category name.'), findsNothing);

      await tapAdd(tester);
      expect(find.text('Enter a category name.'), findsOneWidget);
      expect(app.categories.categories, hasLength(8));

      await typeName(tester, 'School');
      expect(find.text('Enter a category name.'), findsNothing);
    },
  );

  testWidgets(
    'new category: success selects it; "school FEES" is then a duplicate',
    (tester) async {
      final app = await openAddForm(tester);
      await openPanel(tester);
      await typeName(tester, '  School   fees ');
      await tapAdd(tester);

      final school = named(app, 'School fees');
      expect(school, isNotNull);
      expect(school?.iconKey, 'tag');
      expect(find.byType(NewCategoryPanel), findsNothing);
      expect(isChosen('School fees'), isTrue);

      await openPanel(tester);
      await typeName(tester, 'school FEES');
      await tapAdd(tester);
      expect(
        find.text('“School fees” already exists. Choose it above.'),
        findsOneWidget,
      );
      expect(app.categories.categories, hasLength(9));

      // Presets count too, and the message now follows the typing.
      await typeName(tester, 'food');
      expect(
        find.text('“Food” already exists. Choose it above.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('the chosen icon is saved, and the expense uses the category', (
    tester,
  ) async {
    final app = await openAddForm(tester);
    await tester.enterText(amountField, '450');
    await openPanel(tester);
    await typeName(tester, 'School fees');
    await tapInForm(tester, find.byTooltip('Education'));
    await tapAdd(tester);

    final school = named(app, 'School fees')!;
    expect(school.iconKey, 'education');

    await tester.tap(saveButton('Save expense'));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseForm), findsNothing);
    expect((await app.expenses.getById(1))?.category.id, school.id);
  });

  testWidgets('the name stops at 20 code points', (tester) async {
    await openAddForm(tester);
    await openPanel(tester);

    await typeName(tester, 'Personal development fund');

    expect(fieldText(tester, newCategoryNameField), 'Personal development');
    expect(find.text('20 / 20'), findsOneWidget);
  });

  testWidgets('Cancel closes the panel and clears the name', (tester) async {
    final app = await openAddForm(tester);
    await openPanel(tester);
    await typeName(tester, 'School');

    await tapInForm(tester, find.text('Cancel'));
    expect(find.byType(NewCategoryPanel), findsNothing);
    expect(app.categories.categories, hasLength(8));

    await openPanel(tester);
    expect(fieldText(tester, newCategoryNameField), isEmpty);
  });

  testWidgets('a storage failure shows under the name and keeps it', (
    tester,
  ) async {
    final app = await openAddForm(tester);
    await openPanel(tester);
    await typeName(tester, 'School fees');
    app.categories.failNextWrite = true;

    await tapAdd(tester);

    expect(
      find.text('Couldn’t read or save on this device. Try again.'),
      findsOneWidget,
    );
    expect(fieldText(tester, newCategoryNameField), 'School fees');
    expect(find.byType(NewCategoryPanel), findsOneWidget);

    await tapAdd(tester);
    expect(named(app, 'School fees'), isNotNull);
    expect(find.byType(NewCategoryPanel), findsNothing);
  });

  testWidgets('a name matching an archived category brings it back', (
    tester,
  ) async {
    final app = await openAddForm(tester);
    final old = await app.categories.create('Church', 'gifts');
    await app.categories.archive(old.id);
    await tester.pumpAndSettle();
    expect(find.text('Church'), findsNothing);

    await openPanel(tester);
    await typeName(tester, 'church');
    await tapAdd(tester);

    expect(app.categories.categories, hasLength(9));
    expect(named(app, 'Church')?.isArchived, isFalse);
    expect(isChosen('Church'), isTrue);
  });
}
