import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expense_form_screen.dart';
import 'package:traccash/features/expenses/presentation/expenses_screen.dart';
import 'package:traccash/features/home/presentation/home_breakdown.dart';
import 'package:traccash/features/home/presentation/home_screen.dart';
import 'package:traccash/features/reports/presentation/reports_screen.dart';
import 'package:traccash/shared/widgets/expense_tile.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_expense_repository.dart';
import 'home_seed.dart';
import 'test_app.dart';

/// A fake whose month or range streams can be replaced. A function that
/// returns null keeps the normal fake stream.
class _StreamOverride extends FakeExpenseRepository {
  _StreamOverride(super.categories, {this.month, this.between})
    : super(today: () => testToday);

  final Stream<List<Expense>>? Function(CalendarMonth month)? month;
  final Stream<List<Expense>>? Function()? between;

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) =>
      this.month?.call(month) ?? super.watchMonth(month);

  @override
  Stream<List<Expense>> watchBetween(LocalDate from, LocalDate to) =>
      between?.call() ?? super.watchBetween(from, to);
}

Future<TestApp> pumpHome(
  WidgetTester tester, {
  List<ExpenseDraft> seed = const [],
  FakeExpenseRepository Function(FakeCategoryRepository categories)?
  expenseRepository,
  bool settle = true,
}) {
  // Tall enough that every section is on screen at once.
  setScreenSize(tester, const Size(412, 1600));
  return pumpTestApp(
    tester,
    seed: seed,
    expenseRepository: expenseRepository,
    settle: settle,
  );
}

/// Tab labels also appear as screen titles, so tap inside the nav bar only.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

/// Sends the same platform message Android's back button does.
Future<void> pressAndroidBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

Finder inBreakdown(Finder finder) =>
    find.descendant(of: find.byType(HomeBreakdown), matching: finder);

/// The comparison line's icon, whichever way it points.
Finder get comparisonIcon => find.byWidgetPredicate(
  (w) =>
      w is Icon &&
      const [
        Icons.trending_down,
        Icons.trending_up,
        Icons.trending_flat,
      ].contains(w.icon),
);

void main() {
  group('a month with data, as in 01-home-light', () {
    testWidgets('header, month, total split into cedis and pesewas, and '
        'the comparison line', (tester) async {
      await pumpHome(tester, seed: [...september, ...october]);

      expect(find.text('TracCash'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Spent so far this month'), findsOneWidget);

      final total = tester.widget<Text>(find.text('GH₵ 2,313.90'));
      final spans = (total.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect([for (final span in spans) span.text], ['GH₵ ', '2,313', '.90']);

      expect(find.text('GH₵ 3,257.10 less than 1–21 Sep'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('breakdown: sentence, top 3 by name, "5 other categories", '
        'shares totalling 100.0%', (tester) async {
      await pumpHome(tester, seed: [...september, ...october]);

      expect(find.text('Breakdown'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Reports'), findsOneWidget);
      expect(
        find.text('Bills is the largest share of this month, at 33.2%.'),
        findsOneWidget,
      );

      for (final (name, amount, share) in const [
        ('Bills', 'GH₵ 769.00', '33.2%'),
        ('Shopping', 'GH₵ 578.00', '25.0%'),
        ('Food', 'GH₵ 575.50', '24.9%'),
        ('5 other categories', 'GH₵ 391.40', '16.9%'),
      ]) {
        expect(inBreakdown(find.text(name)), findsOneWidget, reason: name);
        expect(inBreakdown(find.text(amount)), findsOneWidget, reason: name);
        expect(inBreakdown(find.text(share)), findsOneWidget, reason: name);
      }
      expect(inBreakdown(find.text('Transport')), findsNothing);

      final shares = tester
          .widgetList<Text>(inBreakdown(find.byType(Text)))
          .map((t) => t.data ?? '')
          .where(RegExp(r'^\d+\.\d%$').hasMatch)
          .map((s) => int.parse(s.replaceAll(RegExp(r'[.%]'), '')));
      expect(shares.fold<int>(0, (sum, s) => sum + s), 1000);

      // Bar segments, as wide as each slice's pesewas.
      final flexes = tester
          .widgetList<Expanded>(inBreakdown(find.byType(Expanded)))
          .map((e) => e.flex)
          .where((flex) => flex != 1);
      expect(flexes, [76900, 57800, 57550, 39140]);
    });

    testWidgets('the bar has a text summary for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester, seed: october);

      expect(
        find.bySemanticsLabel(
          'Bills 33.2%, Shopping 25.0%, Food 24.9%, 5 other categories 16.9%',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('Recent: the 5 latest in the month, newest first, and '
        'View all', (tester) async {
      await pumpHome(tester, seed: october);

      expect(find.text('Recent'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'View all'), findsOneWidget);
      expect(find.byType(ExpenseTile), findsNWidgets(5));

      const subtitles = [
        'Waakye and egg, lunch · Today',
        'Trotro, Madina to Circle · Today',
        'MTN data bundle · Yesterday',
        'Ride to Airport City · 19 Oct',
        '18 Oct',
      ];
      final tops = [
        for (final s in subtitles) tester.getTopLeft(find.text(s)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      // Rows are keyed by expense id: the last five entered.
      for (var id = 8; id <= 12; id++) {
        expect(find.byKey(ValueKey(id)), findsOneWidget);
      }
      expect(find.text('Cinema · 17 Oct'), findsNothing);
    });

    testWidgets('with exactly 4 categories the fourth is named, not '
        '"1 other category"', (tester) async {
      await pumpHome(
        tester,
        seed: [
          draft(4000, PresetIds.food),
          draft(3000, PresetIds.transport),
          draft(2000, PresetIds.bills),
          draft(1000, PresetIds.health),
        ],
      );

      for (final (name, share) in const [
        ('Food', '40.0%'),
        ('Transport', '30.0%'),
        ('Bills', '20.0%'),
        ('Health', '10.0%'),
      ]) {
        expect(inBreakdown(find.text(name)), findsOneWidget);
        expect(inBreakdown(find.text(share)), findsOneWidget);
      }
      expect(find.textContaining('other categor'), findsNothing);
    });

    testWidgets('two categories tied for the largest share', (tester) async {
      await pumpHome(
        tester,
        seed: [
          draft(5000, PresetIds.transport),
          draft(5000, PresetIds.food),
          draft(1200, PresetIds.bills),
        ],
      );

      expect(
        find.text(
          'Food and Transport share the largest amount, GH₵ 50.00 each.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a single category is all of the month', (tester) async {
      await pumpHome(tester, seed: [draft(4500, PresetIds.food)]);

      expect(
        find.text('Food is all of this month’s spending.'),
        findsOneWidget,
      );
      expect(inBreakdown(find.text('100.0%')), findsOneWidget);
    });
  });

  group('the shared month', () {
    testWidgets('Home and Expenses show the same total for the month', (
      tester,
    ) async {
      await pumpHome(tester, seed: [...september, ...october]);
      expect(find.text('GH₵ 2,313.90'), findsOneWidget);

      await tapTab(tester, 'Expenses');

      expect(find.text('GH₵ 2,313.90 · 12 expenses'), findsOneWidget);
    });

    testWidgets('changing month on Home moves Expenses, and back', (
      tester,
    ) async {
      await pumpHome(tester, seed: [...september, ...october]);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Spent in September 2026'), findsOneWidget);
      expect(find.text('GH₵ 6,571.00'), findsOneWidget);
      expect(
        find.text('Bills is the largest share of September 2026, at 45.7%.'),
        findsOneWidget,
      );
      // Nothing in August to compare with.
      expect(comparisonIcon, findsNothing);

      await tapTab(tester, 'Expenses');
      expect(find.text('Sep 2026'), findsOneWidget);
      expect(find.text('GH₵ 6,571.00 · 4 expenses'), findsOneWidget);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tapTab(tester, 'Home');

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('GH₵ 2,313.90'), findsOneWidget);
      expect(find.text('GH₵ 3,257.10 less than 1–21 Sep'), findsOneWidget);
    });

    testWidgets('a past month compares with the whole month before it', (
      tester,
    ) async {
      await pumpHome(
        tester,
        seed: [
          draft(600000, PresetIds.food, date: LocalDate(2026, 8, 15)),
          ...september,
        ],
      );

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text('GH₵ 571.00 more than 1–31 Aug'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('equal spending reads "Same as"', (tester) async {
      await pumpHome(
        tester,
        seed: [
          draft(4500, PresetIds.food, date: sep(20)),
          draft(4500, PresetIds.food),
        ],
      );

      expect(find.text('Same as 1–21 Sep'), findsOneWidget);
      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('first use (03): a zero total and a tonal Add expense that '
        'opens the form', (tester) async {
      await pumpHome(tester);

      expect(find.text('Spent so far this month'), findsOneWidget);
      expect(find.text('GH₵ 0.00'), findsOneWidget);
      expect(find.text('No expenses yet'), findsOneWidget);
      expect(
        find.text(
          'Add what you spend and TracCash will total it by month and '
          'category. Your records stay on this device.',
        ),
        findsOneWidget,
      );
      expect(comparisonIcon, findsNothing);
      expect(find.text('Breakdown'), findsNothing);
      expect(find.text('Recent'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Add expense'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseFormScreen), findsOneWidget);
    });

    testWidgets('an empty month says so, with no comparison even though '
        'last month has data', (tester) async {
      await pumpHome(tester, seed: september);

      expect(find.text('GH₵ 0.00'), findsOneWidget);
      expect(find.text('No expenses in October 2026'), findsOneWidget);
      expect(find.text('Nothing was recorded for this month.'), findsOneWidget);
      expect(comparisonIcon, findsNothing);
      expect(find.text('Breakdown'), findsNothing);
      expect(find.text('Recent'), findsNothing);
      expect(find.text('No expenses yet'), findsNothing);
    });

    testWidgets('loading shows a spinner and no figures', (tester) async {
      final semantics = tester.ensureSemantics();
      final never = StreamController<List<Expense>>();
      addTearDown(never.close);
      await pumpHome(
        tester,
        seed: october,
        expenseRepository: (categories) =>
            _StreamOverride(categories, month: (_) => never.stream),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading expenses'), findsOneWidget);
      expect(find.textContaining('GH₵'), findsNothing);
      expect(find.text('TracCash'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a failed month shows the error, and Try again reads again', (
      tester,
    ) async {
      var failuresLeft = 1;
      await pumpHome(
        tester,
        seed: october,
        expenseRepository: (categories) => _StreamOverride(
          categories,
          month: (_) =>
              failuresLeft-- > 0 ? Stream.error(const StorageError()) : null,
        ),
      );

      expect(find.text('Couldn’t load expenses'), findsOneWidget);
      expect(find.text(const StorageError().message), findsOneWidget);
      expect(find.textContaining('GH₵'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t load expenses'), findsNothing);
      expect(find.text('GH₵ 2,313.90'), findsOneWidget);
    });

    testWidgets('if only last month fails, everything but the comparison '
        'shows', (tester) async {
      await pumpHome(
        tester,
        seed: [...september, ...october],
        expenseRepository: (categories) => _StreamOverride(
          categories,
          between: () => Stream.error(const StorageError()),
        ),
      );

      expect(find.text('Couldn’t load expenses'), findsNothing);
      expect(find.textContaining('less than'), findsNothing);
      expect(comparisonIcon, findsNothing);
      expect(find.text('GH₵ 2,313.90'), findsOneWidget);
      expect(
        find.text('Bills is the largest share of this month, at 33.2%.'),
        findsOneWidget,
      );
      expect(inBreakdown(find.text('5 other categories')), findsOneWidget);
      expect(find.byType(ExpenseTile), findsNWidgets(5));
    });
  });

  group('navigation', () {
    testWidgets('Reports opens the Reports tab; back returns Home', (
      tester,
    ) async {
      await pumpHome(tester, seed: october);

      await tester.tap(find.widgetWithText(TextButton, 'Reports'));
      await tester.pumpAndSettle();

      expect(selectedTab(tester), 2);
      expect(find.byType(ReportsScreen), findsOneWidget);

      await pressAndroidBack(tester);
      expect(selectedTab(tester), 0);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('View all opens the Expenses tab on the same month', (
      tester,
    ) async {
      await pumpHome(tester, seed: [...september, ...october]);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'View all'));
      await tester.pumpAndSettle();

      expect(selectedTab(tester), 1);
      expect(find.byType(ExpensesScreen), findsOneWidget);
      expect(find.text('Sep 2026'), findsOneWidget);
    });

    testWidgets('tapping a Recent row opens its edit form', (tester) async {
      await pumpHome(tester, seed: october);

      await tester.tap(find.text('MTN data bundle · Yesterday'));
      await tester.pumpAndSettle();

      final form = tester.widget<ExpenseFormScreen>(
        find.byType(ExpenseFormScreen),
      );
      expect(form.expenseId, 10);
      expect(find.text('Edit expense'), findsOneWidget);
    });

    testWidgets('Add expense shows on Home and opens the form', (tester) async {
      await pumpHome(tester, seed: october);
      final fab = find.widgetWithText(FloatingActionButton, 'Add expense');
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseFormScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await pressAndroidBack(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a saved expense updates Home without a refresh', (
      tester,
    ) async {
      final app = await pumpHome(tester, seed: october);

      await app.expenses.add(draft(10000, PresetIds.health, note: 'Clinic'));
      await tester.pumpAndSettle();

      expect(find.text('GH₵ 2,413.90'), findsOneWidget);
      expect(find.text('Clinic · Today'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('320dp at text scale 2.0 with large amounts: no overflow', (
      tester,
    ) async {
      setScreenSize(tester, const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpTestApp(
        tester,
        seed: [
          ...october,
          for (final id in [PresetIds.bills, PresetIds.food, PresetIds.other])
            draft(
              100000000,
              id,
              note: 'A very long note about a very large payment ' * 4,
            ),
          ...september,
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('GH₵ 3,002,313.90'), findsOneWidget);
    });

    testWidgets('a total too wide for the screen scales down but reads in '
        'full', (tester) async {
      final semantics = tester.ensureSemantics();
      setScreenSize(tester, const Size(320, 640));
      await pumpTestApp(
        tester,
        seed: [for (var i = 0; i < 10; i++) draft(100000000, PresetIds.bills)],
      );

      expect(tester.takeException(), isNull);
      // The rich total, not the single legend row with the same amount.
      final total = find.byWidgetPredicate(
        (w) => w is Text && w.textSpan?.toPlainText() == 'GH₵ 10,000,000.00',
      );
      expect(
        tester.getRect(total).width,
        lessThan(tester.getSize(total).width),
      );
      expect(find.bySemanticsLabel('GH₵ 10,000,000.00'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('dark theme builds without errors', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await pumpHome(tester, seed: [...september, ...october]);

      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(HomeBreakdown));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });
}
