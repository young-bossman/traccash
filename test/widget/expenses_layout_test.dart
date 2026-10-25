import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/expenses/presentation/expenses_header.dart';
import 'package:traccash/shared/widgets/month_switcher.dart';

import 'home_seed.dart';
import 'plex_font.dart';
import 'test_app.dart';

// Where things sit depends on real glyph widths, so this file runs in IBM
// Plex Sans; expenses_screen_test checks content and overflow in Ahem.

/// The header's title, not the nav bar label with the same text.
Finder get _title => find.descendant(
  of: find.byType(ExpensesHeader),
  matching: find.text('Expenses'),
);

Future<void> _pumpExpenses(
  WidgetTester tester, {
  required double width,
  required double scale,
}) async {
  setScreenSize(tester, Size(width, 900));
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpTestApp(tester, location: AppRoutes.expenses, seed: october);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadPlex();
  });

  for (final width in [412.0, 360.0]) {
    testWidgets('${width.toInt()}dp, text scale 1.0: the month switcher ends '
        'at the page padding, on the title line', (tester) async {
      await _pumpExpenses(tester, width: width, scale: 1);

      expect(tester.takeException(), isNull);
      final title = tester.getRect(_title);
      final switcher = tester.getRect(find.byType(MonthSwitcher));
      expect(title.left, AppSpacing.s20);
      expect(switcher.right, width - AppSpacing.s20);
      expect(switcher.center.dy, moreOrLessEquals(title.center.dy));
    });
  }

  testWidgets('360dp, text scale 2.0: the month switcher wraps below the '
      'title without overflow', (tester) async {
    await _pumpExpenses(tester, width: 360, scale: 2);

    expect(tester.takeException(), isNull);
    final title = tester.getRect(_title);
    final switcher = tester.getRect(find.byType(MonthSwitcher));
    expect(switcher.top, greaterThanOrEqualTo(title.bottom));
    expect(switcher.left, AppSpacing.s20);
    expect(switcher.right, lessThanOrEqualTo(360 - AppSpacing.s20));
  });
}
