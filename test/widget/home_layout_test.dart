import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/home/presentation/home_breakdown.dart';
import 'package:traccash/shared/widgets/month_switcher.dart';

import 'home_seed.dart';
import 'plex_font.dart';
import 'test_app.dart';

// Where things sit depends on real glyph widths, so this file runs in IBM
// Plex Sans; home_screen_test checks content and overflow in Ahem.

Finder _inBreakdown(String text) =>
    find.descendant(of: find.byType(HomeBreakdown), matching: find.text(text));

const List<(String, String, String)> _legend = [
  ('Bills', 'GH₵ 769.00', '33.2%'),
  ('Shopping', 'GH₵ 578.00', '25.0%'),
  ('Food', 'GH₵ 575.50', '24.9%'),
  ('5 other categories', 'GH₵ 391.40', '16.9%'),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadPlex();
  });

  testWidgets('360dp, text scale 1.0: legend figures beside the names, in '
      'aligned columns', (tester) async {
    setScreenSize(tester, const Size(360, 1400));
    await pumpTestApp(tester, seed: [...september, ...october]);
    expect(tester.takeException(), isNull);
    const right = 360 - AppSpacing.s20;

    for (final (name, amount, share) in _legend) {
      final nameRect = tester.getRect(_inBreakdown(name));
      final amountRect = tester.getRect(_inBreakdown(amount));
      final shareRect = tester.getRect(_inBreakdown(share));
      expect(amountRect.center.dy, moreOrLessEquals(nameRect.center.dy));
      expect(amountRect.left, greaterThan(nameRect.right));
      expect(shareRect.right, moreOrLessEquals(right), reason: share);
      expect(
        amountRect.right,
        moreOrLessEquals(tester.getRect(_inBreakdown('GH₵ 769.00')).right),
        reason: amount,
      );
    }
  });

  testWidgets('360dp: headings carry their link at the end of the same line', (
    tester,
  ) async {
    setScreenSize(tester, const Size(360, 1400));
    await pumpTestApp(tester, seed: october);
    const right = 360 - AppSpacing.s20;

    for (final (heading, link) in const [
      ('Breakdown', 'Reports'),
      ('Recent', 'View all'),
    ]) {
      final headingRect = tester.getRect(find.text(heading));
      final linkRect = tester.getRect(find.widgetWithText(TextButton, link));
      expect(headingRect.left, AppSpacing.s20);
      expect(linkRect.right, moreOrLessEquals(right), reason: link);
      expect(linkRect.center.dy, moreOrLessEquals(headingRect.center.dy));
    }
  });

  testWidgets('360dp: the month row has the label at the start and the '
      'arrows at the end, one button high', (tester) async {
    setScreenSize(tester, const Size(360, 1400));
    await pumpTestApp(tester, seed: october);

    final row = tester.getRect(find.byType(MonthSwitcher));
    expect(row.left, AppSpacing.s20);
    expect(row.right, 360 - AppSpacing.s20);
    expect(row.height, AppSizes.buttonHeight);
    expect(tester.getRect(find.text('October 2026')).left, AppSpacing.s20);
    // Next is the row's last 48dp tap target.
    final next = find.ancestor(
      of: find.byTooltip('Next month'),
      matching: find.byType(IconButton),
    );
    expect(tester.getRect(next).right, row.right);
  });

  testWidgets('320dp, text scale 2.0: legend figures move under the names', (
    tester,
  ) async {
    setScreenSize(tester, const Size(320, 1600));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpTestApp(tester, seed: [...september, ...october]);

    expect(tester.takeException(), isNull);
    for (final (name, amount, share) in _legend) {
      final nameRect = tester.getRect(_inBreakdown(name));
      expect(
        tester.getRect(_inBreakdown(amount)).top,
        greaterThanOrEqualTo(nameRect.bottom),
      );
      expect(tester.getRect(_inBreakdown(amount)).left, nameRect.left);
      expect(_inBreakdown(share), findsOneWidget);
    }
  });
}
