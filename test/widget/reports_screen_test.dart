import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expense_form_screen.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/features/reports/presentation/reports_providers.dart';
import 'package:traccash/features/reports/presentation/reports_screen.dart';
import 'package:traccash/features/reports/presentation/reports_summary.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_expense_repository.dart';
import 'home_seed.dart';
import 'test_app.dart';

/// The first day the October trend reads: May 1st.
final LocalDate _trendStart = LocalDate(2026, 5, 1);

/// The first day of the compared days for October: September 1st.
final LocalDate _comparedStart = LocalDate(2026, 9, 1);

/// A fake whose streams or first-date read can be replaced. A function
/// that returns null keeps the normal fake behaviour.
class _Override extends FakeExpenseRepository {
  _Override(super.categories, {this.month, this.between, this.firstDate})
    : super(today: () => testToday);

  final Stream<List<Expense>>? Function(CalendarMonth month)? month;
  final Stream<List<Expense>>? Function(LocalDate from, LocalDate to)? between;
  final Future<LocalDate?>? Function()? firstDate;

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) =>
      this.month?.call(month) ?? super.watchMonth(month);

  @override
  Stream<List<Expense>> watchBetween(LocalDate from, LocalDate to) =>
      between?.call(from, to) ?? super.watchBetween(from, to);

  @override
  Future<LocalDate?> firstExpenseDate() =>
      firstDate?.call() ?? super.firstExpenseDate();
}

Future<TestApp> pumpReports(
  WidgetTester tester, {
  List<ExpenseDraft> seed = const [],
  FakeExpenseRepository Function(FakeCategoryRepository categories)?
  expenseRepository,
  bool settle = true,
}) {
  // Tall enough that every section is on screen at once.
  setScreenSize(tester, const Size(412, 2600));
  return pumpTestApp(
    tester,
    location: AppRoutes.reports,
    seed: seed,
    expenseRepository: expenseRepository,
    settle: settle,
  );
}

/// Inside the Reports page, not the navigation bar's labels.
Finder inReports(Finder finder) =>
    find.descendant(of: find.byType(ReportsScreen), matching: finder);

Finder inChart(Finder finder) =>
    find.descendant(of: find.byType(BarChart), matching: finder);

BarChartData chartData(WidgetTester tester) =>
    tester.widget<BarChart>(find.byType(BarChart)).data;

List<BarChartRodData> rods(WidgetTester tester) => [
  for (final group in chartData(tester).barGroups) group.barRods.single,
];

Future<void> showTrend(WidgetTester tester, String period) async {
  await tester.tap(find.text(period));
  await tester.pumpAndSettle();
}

Future<void> previousMonth(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Previous month'));
  await tester.pumpAndSettle();
}

/// A text's top edge, for checking the order rows appear in.
double top(WidgetTester tester, String text) =>
    tester.getTopLeft(inReports(find.text(text))).dy;

void main() {
  group('the month in 10 and 11', () {
    testWidgets('header, total split into cedis and pesewas, and the stats '
        'row', (tester) async {
      await pumpReports(tester, seed: [...september, ...october]);

      expect(inReports(find.text('Reports')), findsOneWidget);
      expect(find.text('Oct 2026'), findsOneWidget);
      expect(find.text('Total spent · October 2026'), findsOneWidget);

      final total = tester.widget<Text>(find.text('GH₵ 2,313.90'));
      final spans = (total.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect([for (final span in spans) span.text], ['GH₵ ', '2,313', '.90']);

      for (final (label, value) in const [
        ('Expenses', '12'),
        ('Daily average', 'GH₵ 110.19'),
        ('vs 1–21 Sep', '−GH₵ 3,257.10'),
      ]) {
        expect(inReports(find.text(label)), findsOneWidget, reason: label);
        expect(inReports(find.text(value)), findsOneWidget, reason: value);
      }
    });

    testWidgets('the comparison is read in words', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpReports(tester, seed: [...september, ...october]);

      expect(
        find.bySemanticsLabel('GH₵ 3,257.10 less than 1–21 Sep'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('the largest category card', (tester) async {
      await pumpReports(tester, seed: [...september, ...october]);

      final card = find.byType(LargestCategoryCard);
      for (final text in const [
        'Largest category',
        'Bills',
        'GH₵ 769.00',
        '33.2% of total',
      ]) {
        expect(
          find.descendant(of: card, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
    });

    testWidgets('By category: every category, largest first, with counts, '
        'amounts and shares totalling 100.0%', (tester) async {
      await pumpReports(tester, seed: [...september, ...october]);

      expect(find.text('By category'), findsOneWidget);
      const rows = [
        ('Bills · 2 expenses', 'GH₵ 769.00', '33.2%'),
        ('Shopping · 2 expenses', 'GH₵ 578.00', '25.0%'),
        ('Food · 2 expenses', 'GH₵ 575.50', '24.9%'),
        ('Health · 1 expense', 'GH₵ 120.00', '5.2%'),
        ('Other · 1 expense', 'GH₵ 94.40', '4.1%'),
        ('Entertainment · 1 expense', 'GH₵ 80.00', '3.4%'),
        ('Data & Airtime · 1 expense', 'GH₵ 50.00', '2.2%'),
        ('Transport · 2 expenses', 'GH₵ 47.00', '2.0%'),
      ];
      for (final (name, _, share) in rows) {
        expect(inReports(find.text(name)), findsOneWidget, reason: name);
        expect(inReports(find.text(share)), findsOneWidget, reason: name);
      }
      final tops = [for (final (name, _, _) in rows) top(tester, name)];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(
        rows
            .map((r) => int.parse(r.$3.replaceAll(RegExp(r'[.%]'), '')))
            .fold<int>(0, (sum, s) => sum + s),
        1000,
      );
    });

    testWidgets('Spending trend opens on Daily: a bar per day, the tallest '
        'is the biggest day in Expenses', (tester) async {
      final app = await pumpReports(tester, seed: [...september, ...october]);

      expect(find.text('Spending trend'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      // The list the Expenses tab groups into days for the same month.
      final ledger = app.container.read(monthExpensesProvider).requireValue;
      final days = groupByDay(ledger);
      final biggest = days.reduce(
        (a, b) => a.totalPesewas >= b.totalPesewas ? a : b,
      );
      final bars = rods(tester);

      expect(bars, hasLength(31));
      final tallest = bars.map((r) => r.toY).reduce(max);
      expect(tallest, biggest.totalPesewas.toDouble());
      expect(bars.indexWhere((r) => r.toY == tallest), biggest.date.day - 1);
      expect(chartData(tester).maxY, 100000);
    });

    testWidgets('Daily: every bar is accent; days after today have none', (
      tester,
    ) async {
      await pumpReports(tester, seed: [...september, ...october]);
      final context = tester.element(find.byType(ReportsScreen));
      final accent = Theme.of(context).colorScheme.primary;

      final bars = rods(tester);
      for (final bar in bars.where((r) => r.toY > 0)) {
        expect(bar.color, accent);
      }
      for (final bar in bars.sublist(21)) {
        expect(bar.toY, 0);
      }
    });

    testWidgets('Daily axes: days 1, 8, 15, 22 and 29 only, money labels '
        'from the money formatter', (tester) async {
      await pumpReports(tester, seed: [...september, ...october]);

      for (final day in ['1', '8', '15', '22', '29']) {
        expect(inChart(find.text(day)), findsOneWidget, reason: day);
      }
      for (final day in ['2', '7', '21', '30', '31']) {
        expect(inChart(find.text(day)), findsNothing, reason: day);
      }
      for (final label in ['GH₵ 0', 'GH₵ 500', 'GH₵ 1,000']) {
        expect(inChart(find.text(label)), findsOneWidget, reason: label);
      }
    });

    testWidgets('touch is off', (tester) async {
      await pumpReports(tester, seed: [...september, ...october]);

      expect(chartData(tester).barTouchData.enabled, isFalse);
      await showTrend(tester, 'Monthly');
      expect(chartData(tester).barTouchData.enabled, isFalse);
    });

    testWidgets('Monthly: a bar per month from the first record, the '
        'selected month in accent and bold', (tester) async {
      await pumpReports(tester, seed: [...september, ...october]);
      final context = tester.element(find.byType(ReportsScreen));
      final accent = Theme.of(context).colorScheme.primary;
      final muted = AppPalette.of(context).barMuted;

      await showTrend(tester, 'Monthly');

      final bars = rods(tester);
      expect([for (final r in bars) r.toY], [657100, 231390]);
      expect([for (final r in bars) r.color], [muted, accent]);
      expect(chartData(tester).maxY, 1000000);
      expect(
        tester.widget<Text>(inChart(find.text('Oct'))).style?.fontWeight,
        FontWeight.w600,
      );
      expect(
        tester.widget<Text>(inChart(find.text('Sep'))).style?.fontWeight,
        isNot(FontWeight.w600),
      );
      for (final label in ['GH₵ 0', 'GH₵ 5,000', 'GH₵ 10,000']) {
        expect(inChart(find.text(label)), findsOneWidget, reason: label);
      }
      expect(
        find.text(
          'Monthly totals in cedis, ending October 2026. Months before your '
          'first record are not shown.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('each chart has a text summary for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpReports(tester, seed: [...september, ...october]);

      expect(
        find.bySemanticsLabel(
          'Daily spending for October 2026. Highest day: 8 October, '
          'GH₵ 530.50.',
        ),
        findsOneWidget,
      );

      await showTrend(tester, 'Monthly');
      expect(
        find.bySemanticsLabel(
          'Monthly spending: September GH₵ 6,571.00, October GH₵ 2,313.90.',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('comparison stat', () {
    testWidgets('"No data" when last month has nothing to compare', (
      tester,
    ) async {
      await pumpReports(tester, seed: october);

      expect(inReports(find.text('vs 1–21 Sep')), findsOneWidget);
      expect(inReports(find.text('No data')), findsOneWidget);
    });

    testWidgets('more reads +GH₵, equal reads GH₵ 0.00', (tester) async {
      final app = await pumpReports(
        tester,
        seed: [
          draft(1000, PresetIds.food, date: sep(3)),
          ...october,
        ],
      );
      expect(inReports(find.text('+GH₵ 2,303.90')), findsOneWidget);

      await app.expenses.add(draft(230390, PresetIds.bills, date: sep(4)));
      await tester.pumpAndSettle();
      expect(inReports(find.text('GH₵ 0.00')), findsOneWidget);
    });

    testWidgets('a past month names the previous month', (tester) async {
      await pumpReports(
        tester,
        seed: [
          draft(600000, PresetIds.food, date: LocalDate(2026, 8, 15)),
          ...september,
        ],
      );

      await previousMonth(tester);

      expect(find.text('Total spent · September 2026'), findsOneWidget);
      expect(inReports(find.text('vs Aug 2026')), findsOneWidget);
      expect(inReports(find.text('+GH₵ 571.00')), findsOneWidget);
      // GH₵ 6,571.00 ÷ 30 days.
      expect(inReports(find.text('GH₵ 219.03')), findsOneWidget);
    });
  });

  group('monthly trend window', () {
    testWidgets('6-month cut-off: 8 months of records show the last 6', (
      tester,
    ) async {
      await pumpReports(
        tester,
        seed: [
          for (var month = 3; month <= 10; month++)
            draft(
              1000 * month,
              PresetIds.food,
              date: LocalDate(2026, month, 2),
            ),
        ],
      );

      await showTrend(tester, 'Monthly');

      expect(
        [for (final r in rods(tester)) r.toY],
        [5000, 6000, 7000, 8000, 9000, 10000],
      );
      for (final label in ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct']) {
        expect(inChart(find.text(label)), findsOneWidget, reason: label);
      }
      expect(inChart(find.text('Apr')), findsNothing);
      expect(inChart(find.text('Mar')), findsNothing);
    });

    testWidgets('an earlier first record extends the trend without a '
        'refresh', (tester) async {
      final app = await pumpReports(
        tester,
        seed: [
          draft(2000, PresetIds.food, date: LocalDate(2026, 7, 14)),
          draft(3000, PresetIds.bills, date: LocalDate(2026, 10, 10)),
        ],
      );
      await showTrend(tester, 'Monthly');
      expect(rods(tester), hasLength(4));

      // 8 months back: before the 6 months the trend reads.
      await app.expenses.add(
        draft(1000, PresetIds.food, date: LocalDate(2026, 2, 10)),
      );
      await tester.pumpAndSettle();

      expect(rods(tester), hasLength(6));
      expect([for (final r in rods(tester)) r.toY], [0, 0, 2000, 0, 0, 3000]);
    });

    testWidgets('moving an expense to another month updates the table and '
        'both charts', (tester) async {
      final app = await pumpReports(tester, seed: [...september, ...october]);
      // September is ids 1–4; October's first, Bills GH₵ 450.00 on the 5th,
      // is id 5.
      final ecg = (await app.expenses.getById(5))!;

      await app.expenses.update(
        ecg.id,
        ecg.toDraft().copyWith(occurredOn: sep(5)),
      );
      await tester.pumpAndSettle();

      expect(find.text('GH₵ 1,863.90'), findsOneWidget);
      expect(inReports(find.text('Bills · 1 expense')), findsOneWidget);
      expect(rods(tester)[4].toY, 0);

      await showTrend(tester, 'Monthly');
      expect([for (final r in rods(tester)) r.toY], [702100, 186390]);

      await app.expenses.delete(ecg.id);
      await tester.pumpAndSettle();
      expect([for (final r in rods(tester)) r.toY], [657100, 186390]);
    });
  });

  group('states', () {
    testWidgets('no data (15): a past month with nothing shows the state, '
        'not a chart', (tester) async {
      await pumpReports(tester, seed: october);

      await previousMonth(tester);

      expect(find.text('Sep 2026'), findsOneWidget);
      expect(find.text('No spending to report'), findsOneWidget);
      expect(
        find.text(
          'Reports appear once September 2026 has at least one '
          'expense.',
        ),
        findsOneWidget,
      );
      expect(find.byType(BarChart), findsNothing);
      expect(find.text('Spending trend'), findsNothing);
      expect(find.text('By category'), findsNothing);
      expect(inReports(find.textContaining('GH₵')), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Add expense'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseFormScreen), findsOneWidget);
    });

    testWidgets('no data (15) on first use', (tester) async {
      await pumpReports(tester);

      expect(find.text('No spending to report'), findsOneWidget);
      expect(
        find.text(
          'Reports appear once October 2026 has at least one '
          'expense.',
        ),
        findsOneWidget,
      );
      expect(find.byType(BarChart), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Add expense'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseFormScreen), findsOneWidget);
    });

    testWidgets('loading shows a spinner and no figures', (tester) async {
      final semantics = tester.ensureSemantics();
      final never = StreamController<List<Expense>>();
      addTearDown(never.close);
      await pumpReports(
        tester,
        seed: october,
        expenseRepository: (categories) =>
            _Override(categories, month: (_) => never.stream),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading expenses'), findsOneWidget);
      expect(inReports(find.textContaining('GH₵')), findsNothing);
      expect(find.text('Oct 2026'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a failed month shows the error, and Try again reads again', (
      tester,
    ) async {
      var failuresLeft = 1;
      await pumpReports(
        tester,
        seed: october,
        expenseRepository: (categories) => _Override(
          categories,
          month: (_) =>
              failuresLeft-- > 0 ? Stream.error(const StorageError()) : null,
        ),
      );

      expect(find.text('Couldn’t load expenses'), findsOneWidget);
      expect(find.text(const StorageError().message), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t load expenses'), findsNothing);
      expect(find.text('GH₵ 2,313.90'), findsOneWidget);
    });

    testWidgets('if only the trend fails, Monthly says so and the rest '
        'shows; Try again reads it again', (tester) async {
      var failuresLeft = 1;
      await pumpReports(
        tester,
        seed: [...september, ...october],
        expenseRepository: (categories) => _Override(
          categories,
          between: (from, _) => from == _trendStart && failuresLeft-- > 0
              ? Stream.error(const StorageError())
              : null,
        ),
      );

      expect(find.text('GH₵ 2,313.90'), findsOneWidget);
      expect(inReports(find.text('−GH₵ 3,257.10')), findsOneWidget);
      expect(find.text('By category'), findsOneWidget);
      expect(rods(tester), hasLength(31));
      expect(find.text('Couldn’t load expenses'), findsNothing);

      await showTrend(tester, 'Monthly');
      expect(find.text('Couldn’t load expenses'), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t load expenses'), findsNothing);
      expect(rods(tester), hasLength(2));
    });

    testWidgets('if the first record date can’t be read, Monthly says so', (
      tester,
    ) async {
      await pumpReports(
        tester,
        seed: [...september, ...october],
        expenseRepository: (categories) => _Override(
          categories,
          firstDate: () => Future.error(const StorageError()),
        ),
      );

      expect(rods(tester), hasLength(31));
      await showTrend(tester, 'Monthly');
      expect(find.text('Couldn’t load expenses'), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('if only the compared days fail, the comparison is left out', (
      tester,
    ) async {
      await pumpReports(
        tester,
        seed: [...september, ...october],
        expenseRepository: (categories) => _Override(
          categories,
          between: (from, _) => from == _comparedStart
              ? Stream.error(const StorageError())
              : null,
        ),
      );

      expect(inReports(find.text('Expenses')), findsOneWidget);
      expect(inReports(find.text('Daily average')), findsOneWidget);
      expect(inReports(find.text('vs 1–21 Sep')), findsNothing);
      expect(inReports(find.text('No data')), findsNothing);
      expect(find.text('GH₵ 2,313.90'), findsOneWidget);
    });

    testWidgets('the toggle survives a month change', (tester) async {
      await pumpReports(tester, seed: [...september, ...october]);
      await showTrend(tester, 'Monthly');

      await previousMonth(tester);

      final toggle = tester.widget<SegmentedButton<TrendPeriod>>(
        find.byType(SegmentedButton<TrendPeriod>),
      );
      expect(toggle.selected, {TrendPeriod.monthly});
      // September is the first record's month: one bar.
      expect([for (final r in rods(tester)) r.toY], [657100]);
    });

    testWidgets('changing month on Reports moves Home too', (tester) async {
      await pumpReports(tester, seed: [...september, ...october]);

      await previousMonth(tester);
      expect(find.text('Total spent · September 2026'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Home'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Spent in September 2026'), findsOneWidget);
    });

    testWidgets('reduced motion: the chart does not animate', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpReports(tester, seed: [...september, ...october]);

      expect(
        tester.widget<BarChart>(find.byType(BarChart)).duration,
        Duration.zero,
      );
      await showTrend(tester, 'Monthly');
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).duration,
        Duration.zero,
      );
    });

    testWidgets('without reduced motion the bars animate to new totals', (
      tester,
    ) async {
      await pumpReports(tester, seed: [...september, ...october]);

      expect(
        tester.widget<BarChart>(find.byType(BarChart)).duration,
        greaterThan(Duration.zero),
      );
    });
  });

  group('layout', () {
    testWidgets('320dp at text scale 2.0 with large amounts: no overflow, '
        'and the stats stack', (tester) async {
      setScreenSize(tester, const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final app = await pumpTestApp(
        tester,
        location: AppRoutes.reports,
        seed: [
          ...september,
          ...october,
          for (final id in [PresetIds.bills, PresetIds.food, PresetIds.other])
            draft(100000000, id),
        ],
      );
      expect(tester.takeException(), isNull);

      // GH₵ 3,002,313.90 in 15 expenses: ÷ 21 days, and less 1–21 Sep's
      // GH₵ 5,571.00.
      final values = [
        for (final text in ['15', 'GH₵ 142,967.33', '+GH₵ 2,996,742.90'])
          tester.getRect(
            find.descendant(
              of: find.byType(ReportsStats),
              matching: find.text(text),
            ),
          ),
      ];
      expect(values[1].top, greaterThan(values[0].bottom));
      expect(values[2].top, greaterThan(values[1].bottom));
      for (final rect in values) {
        expect(rect.right, lessThanOrEqualTo(320 - 20 + 0.01));
      }
      // The biggest day is GH₵ 3,000,057.00: the axis label shrinks to fit
      // but keeps every digit.
      expect(inChart(find.text('GH₵ 5,000,000')), findsOneWidget);
      final chartLeft = tester.getRect(find.byType(BarChart)).left;
      expect(
        tester.getRect(inChart(find.text('GH₵ 5,000,000'))).left,
        greaterThanOrEqualTo(chartLeft),
      );

      app.container
          .read(trendPeriodProvider.notifier)
          .select(TrendPeriod.monthly);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(rods(tester), hasLength(2));
    });

    testWidgets('dark theme builds without errors', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await pumpReports(tester, seed: [...september, ...october]);
      await showTrend(tester, 'Monthly');

      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(ReportsScreen));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });
}
