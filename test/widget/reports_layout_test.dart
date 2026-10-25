import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/reports/presentation/reports_providers.dart';
import 'package:traccash/features/reports/presentation/reports_summary.dart';

import 'home_seed.dart';
import 'plex_font.dart';
import 'test_app.dart';

// Where things sit depends on real glyph widths, so this file runs in IBM
// Plex Sans; reports_screen_test checks content and overflow in Ahem.

Finder _inStats(String text) =>
    find.descendant(of: find.byType(ReportsStats), matching: find.text(text));

const List<String> _statValues = ['12', 'GH₵ 110.19', '−GH₵ 3,257.10'];

Future<void> _pumpReports(
  WidgetTester tester, {
  required double width,
  double scale = 1,
}) async {
  setScreenSize(tester, Size(width, 2600));
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpTestApp(
    tester,
    location: AppRoutes.reports,
    seed: [...september, ...october],
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadPlex();
  });

  testWidgets('390dp, text scale 1.0 (10 and 11): the three stats share one '
      'line inside the page padding', (tester) async {
    await _pumpReports(tester, width: 390);
    expect(tester.takeException(), isNull);

    final rects = [for (final v in _statValues) tester.getRect(_inStats(v))];
    for (final rect in rects.skip(1)) {
      expect(rect.center.dy, moreOrLessEquals(rects.first.center.dy));
    }
    expect(rects[1].left, greaterThan(rects[0].right));
    expect(rects[2].left, greaterThan(rects[1].right));
    expect(rects.first.left, AppSpacing.s20);
    expect(rects.last.right, lessThanOrEqualTo(390 - AppSpacing.s20));
  });

  testWidgets('320dp, text scale 2.0: the stats stack, one per line, '
      'nothing clipped', (tester) async {
    await _pumpReports(tester, width: 320, scale: 2);
    expect(tester.takeException(), isNull);

    final rects = [for (final v in _statValues) tester.getRect(_inStats(v))];
    expect(rects[1].top, greaterThan(rects[0].bottom));
    expect(rects[2].top, greaterThan(rects[1].bottom));
    for (final rect in rects) {
      expect(rect.left, AppSpacing.s20);
      expect(rect.right, lessThanOrEqualTo(320 - AppSpacing.s20));
    }
  });

  testWidgets('390dp: By category amounts and shares sit in aligned '
      'columns beside the names', (tester) async {
    await _pumpReports(tester, width: 390);

    const rows = [
      ('Bills · 2 expenses', 'GH₵ 769.00', '33.2%'),
      ('Health · 1 expense', 'GH₵ 120.00', '5.2%'),
      ('Transport · 2 expenses', 'GH₵ 47.00', '2.0%'),
    ];
    final shareRight = tester.getRect(find.text('33.2%')).right;
    final amountRight = tester.getRect(find.text('GH₵ 769.00').last).right;
    for (final (name, amount, share) in rows) {
      final nameRect = tester.getRect(find.text(name));
      final amountRect = tester.getRect(find.text(amount).last);
      final shareRect = tester.getRect(find.text(share));
      expect(amountRect.left, greaterThan(nameRect.right), reason: name);
      expect(shareRect.right, moreOrLessEquals(shareRight), reason: name);
      expect(amountRect.right, moreOrLessEquals(amountRight), reason: name);
    }
  });

  testWidgets('390dp: "Spending trend" on the left, the toggle at the end of '
      'the same line', (tester) async {
    await _pumpReports(tester, width: 390);

    final heading = tester.getRect(find.text('Spending trend'));
    final toggle = tester.getRect(find.byType(SegmentedButton<TrendPeriod>));
    expect(heading.left, AppSpacing.s20);
    expect(toggle.right, moreOrLessEquals(390 - AppSpacing.s20));
    expect(toggle.center.dy, moreOrLessEquals(heading.center.dy, epsilon: 1));
  });
}
