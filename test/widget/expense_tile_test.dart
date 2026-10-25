import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_theme.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/shared/widgets/expense_tile.dart';

import 'plex_font.dart';

// Layout decisions depend on real glyph widths, so this file runs in IBM
// Plex Sans instead of the Ahem test font.

const String _longNote =
    'A very long note about a very large payment for the new shop roof';

Expense _expense(int pesewas, String? note) => Expense(
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
  note: note,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// Pumps one full-width tile on a [width]dp screen at [scale] text scale.
Future<void> _pumpTile(
  WidgetTester tester,
  int pesewas, {
  required double width,
  required double scale,
  String? note = _longNote,
  String? dateLabel,
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
          children: [
            ExpenseTile(
              expense: _expense(pesewas, note),
              dateLabel: dateLabel,
              onTap: () {},
            ),
          ],
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
    await loadPlex();
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

  group('with a date after the note, as on Home', () {
    const note = 'Waakye and egg, lunch';
    const subtitle = 'Waakye and egg, lunch · Today';

    // The category, subtitle and (when stacked) amount column.
    Rect textColumn(WidgetTester tester) => tester.getRect(
      find
          .ancestor(of: find.text(subtitle), matching: find.byType(Column))
          .first,
    );

    for (final pesewas in [4500, 100000000]) {
      testWidgets('360dp, text scale 1.0, ${formatGhs(pesewas)}: the amount '
          'stays beside a text column of at least 96dp', (tester) async {
        await _pumpTile(
          tester,
          pesewas,
          width: 360,
          scale: 1,
          note: note,
          dateLabel: 'Today',
        );

        expect(tester.takeException(), isNull);
        final text = tester.widget<Text>(find.text(subtitle));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);

        final amount = _amount(tester, pesewas);
        final column = textColumn(tester);
        expect(amount.left, greaterThan(_category(tester).right));
        expect(column.width, greaterThanOrEqualTo(AppSizes.ledgerMinTextWidth));
        expect(column.right + AppSpacing.s12, moreOrLessEquals(amount.left));
        expect(
          tester.getSize(find.byType(ExpenseTile)).height,
          AppSizes.ledgerRowMinHeight,
        );
      });

      testWidgets('320dp, text scale 2.0, ${formatGhs(pesewas)}: the amount '
          'moves under the date and the text keeps 96dp, scaled', (
        tester,
      ) async {
        await _pumpTile(
          tester,
          pesewas,
          width: 320,
          scale: 2,
          note: note,
          dateLabel: 'Today',
        );

        expect(tester.takeException(), isNull);
        final amount = _amount(tester, pesewas);
        final category = _category(tester);
        expect(
          amount.top,
          greaterThanOrEqualTo(tester.getRect(find.text(subtitle)).bottom),
        );
        expect(amount.left, category.left);
        expect(
          textColumn(tester).width,
          greaterThanOrEqualTo(AppSizes.ledgerMinTextWidth * 2),
        );
      });
    }

    testWidgets('without a note the date stands alone', (tester) async {
      await _pumpTile(
        tester,
        4500,
        width: 360,
        scale: 1,
        note: null,
        dateLabel: 'Yesterday',
      );

      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.textContaining('·'), findsNothing);
    });

    testWidgets('without a note or a date there is no second line', (
      tester,
    ) async {
      await _pumpTile(tester, 4500, width: 360, scale: 1, note: null);

      // Category and amount only.
      expect(find.byType(Text), findsNWidgets(2));
    });
  });
}
