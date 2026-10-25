import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_theme.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expense_tile.dart';

// Layout decisions depend on real glyph widths, so this file loads the
// bundled IBM Plex Sans instead of the Ahem test font. Each test file runs
// separately, so other widget tests keep Ahem.
Future<void> _loadPlex() async {
  final loader = FontLoader(AppTypography.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    loader.addFont(rootBundle.load('assets/fonts/IBMPlexSans-$weight.ttf'));
  }
  await loader.load();
}

const String _longNote =
    'A very long note about a very large payment for the new shop roof';

Expense _expense(int pesewas) => Expense(
  id: 1,
  amountPesewas: pesewas,
  category: Category(
    id: 3,
    name: 'Bills',
    iconKey: 'bills',
    sortOrder: 2,
    isPreset: true,
    isArchived: false,
    createdAt: DateTime.utc(2026),
  ),
  occurredOn: LocalDate(2026, 10, 21),
  note: _longNote,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// Pumps one full-width tile on a [width]dp screen at [scale] text scale.
Future<void> _pumpTile(
  WidgetTester tester,
  int pesewas, {
  required double width,
  required double scale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [ExpenseTile(expense: _expense(pesewas), onTap: () {})],
        ),
      ),
    ),
  );
}

Rect _amount(WidgetTester tester, int pesewas) =>
    tester.getRect(find.text(formatGhs(pesewas)));

Rect _category(WidgetTester tester) => tester.getRect(find.text('Bills'));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadPlex();
  });

  group('at 360dp and text scale 1.0 the amount sits on the category row', () {
    for (final pesewas in [480000, 100000000]) {
      testWidgets(formatGhs(pesewas), (tester) async {
        await _pumpTile(tester, pesewas, width: 360, scale: 1);

        expect(tester.takeException(), isNull);
        expect(
          _amount(tester, pesewas).left,
          greaterThan(_category(tester).right),
        );
        expect(
          tester.getSize(find.byType(ExpenseTile)).height,
          AppSizes.ledgerRowMinHeight,
        );
        // The note still truncates rather than pushing the amount.
        final note = tester.widget<Text>(find.text(_longNote));
        expect(note.maxLines, 1);
      });
    }
  });

  testWidgets('at 320dp and text scale 1.0 GH₵ 1,000,000.00 moves to its own '
      'line', (tester) async {
    await _pumpTile(tester, 100000000, width: 320, scale: 1);

    expect(tester.takeException(), isNull);
    final amount = _amount(tester, 100000000);
    final category = _category(tester);
    expect(amount.top, greaterThanOrEqualTo(category.bottom));
    expect(amount.left, category.left);
  });

  group('at 320dp and text scale 2.0 every amount moves to its own line', () {
    for (final pesewas in [1200, 480000, 100000000]) {
      testWidgets(formatGhs(pesewas), (tester) async {
        await _pumpTile(tester, pesewas, width: 320, scale: 2);

        expect(tester.takeException(), isNull);
        final amount = _amount(tester, pesewas);
        final category = _category(tester);
        expect(amount.top, greaterThanOrEqualTo(category.bottom));
        expect(amount.left, category.left);
      });
    }
  });
}
