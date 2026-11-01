import 'dart:async';
import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traccash/app/app.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/data/database/database_provider.dart';
import 'package:traccash/features/categories/presentation/category_picker.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/presentation/expense_form.dart';

// Runs on a device or emulator, not in `flutter test`:
//   flutter test integration_test -d <device id>
//
// The real app on real SQLite, through the same drift_flutter connection
// main() uses. Only the file differs: a new temporary one, so the test never
// reads or changes the expenses already on the phone.

/// One run of the app: its providers and its own database connection.
class _Launch {
  _Launch(this.database)
    : container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );

  final AppDatabase database;
  final ProviderContainer container;

  /// What closing the app does to the database: the widgets go (and with
  /// them every stream query), then the connection closes.
  Future<void> quit(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await database.close();
  }
}

Future<_Launch> _launch(WidgetTester tester, String path) async {
  final launch = _Launch(
    AppDatabase(
      driftDatabase(
        name: 'traccash',
        native: DriftNativeOptions(databasePath: () async => path),
      ),
    ),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: launch.container,
      child: const TracCashApp(),
    ),
  );
  await tester.pumpAndSettle();
  return launch;
}

/// Pumps until [finder] finds something. Drift answers from a background
/// isolate, so a result can arrive after the frames have settled.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Never found $finder', timeout);
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder _categoryOption(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(OptionSurface));

String _fieldText(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!.text;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an expense added before a restart is still there after it, '
      'with the same amount, category and date', (tester) async {
    // As main() does before runApp.
    await initializeDateFormatting(dateLocale);
    final directory = await Directory.systemTemp.createTemp('traccash_');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}traccash.sqlite';
    final today = LocalDate.today();
    const note = 'Trotro, Madina to Circle';

    // First launch: a new install. Add an expense through the form.
    final first = await _launch(tester, path);
    await _tap(tester, _tab('Expenses'));
    await _tap(
      tester,
      find.widgetWithText(FloatingActionButton, 'Add expense'),
    );
    await _waitFor(tester, find.byKey(ExpenseForm.amountKey));
    await tester.enterText(find.byKey(ExpenseForm.amountKey), '12.50');
    await _tap(tester, _categoryOption('Transport'));
    await tester.ensureVisible(find.byKey(ExpenseForm.noteKey));
    await tester.enterText(find.byKey(ExpenseForm.noteKey), note);
    await _tap(tester, find.widgetWithText(FilledButton, 'Save expense'));
    // Shown only once the write has succeeded.
    await _waitFor(tester, find.text('Expense saved'));
    await first.quit(tester);

    // Second launch: a new connection to the same file.
    final second = await _launch(tester, path);
    addTearDown(() => second.quit(tester));
    await _tap(tester, _tab('Expenses'));
    await _waitFor(tester, find.text(note));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    // The row's amount and the day's total.
    expect(find.text('GH₵ 12.50'), findsNWidgets(2));

    // The form shows exactly what was saved.
    await _tap(tester, find.text(note));
    await _waitFor(tester, find.byKey(ExpenseForm.amountKey));
    expect(_fieldText(tester, ExpenseForm.amountKey), '12.50');
    expect(
      find.descendant(
        of: _categoryOption('Transport'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(find.text(formatNumericDate(today)), findsOneWidget);
    expect(_fieldText(tester, ExpenseForm.noteKey), note);

    // And so does the stored record, read back on the new connection.
    final stored = await second.container
        .read(expenseRepositoryProvider)
        .watchRecent(limit: 10)
        .first;
    expect(stored, hasLength(1));
    expect(stored.single.amountPesewas, 1250);
    expect(stored.single.category.name, 'Transport');
    expect(stored.single.occurredOn, today);
    expect(stored.single.note, note);
  });
}
