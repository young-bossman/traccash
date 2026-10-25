import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';

import 'plex_font.dart';
import 'test_app.dart';

// Where things sit, and whether labels fit, depends on real glyph widths,
// so this file runs in IBM Plex Sans; settings_screen_test checks content
// and behaviour in Ahem.

Future<void> _pumpSettings(
  WidgetTester tester, {
  required double width,
  required double scale,
  double height = 900,
}) async {
  setScreenSize(tester, Size(width, height));
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpTestApp(tester, location: AppRoutes.settings);
}

Axis _themeDirection(WidgetTester tester) => tester
    .widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>))
    .direction;

/// Whether [text] was laid out on a single line (not broken or wrapped).
bool _onOneLine(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  final oneLine = paragraph.getMaxIntrinsicHeight(double.infinity);
  return paragraph.size.height <= oneLine + 0.01;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadPlex();
  });

  testWidgets('390dp (16-settings.png), text scale 1.0: the theme choices '
      'share one row across the page; Version sits beside its value', (
    tester,
  ) async {
    await _pumpSettings(tester, width: 390, scale: 1);

    expect(tester.takeException(), isNull);
    expect(_themeDirection(tester), Axis.horizontal);
    final choices = tester.getRect(find.byType(SegmentedButton<ThemeMode>));
    expect(choices.left, AppSpacing.s20);
    expect(choices.right, 390 - AppSpacing.s20);
    // Drawn at the button height, which is also the touch target.
    expect(choices.height, AppSizes.buttonHeight);
    expect(tester.getSize(find.text('Dark')).height, lessThan(choices.height));
    for (final label in ['System', 'Light', 'Dark']) {
      expect(_onOneLine(tester, label), isTrue, reason: label);
    }

    final title = tester.getRect(find.text('Version'));
    final value = tester.getRect(find.text('0.1.0 (1)'));
    expect(value.center.dy, moreOrLessEquals(title.center.dy, epsilon: 1));
    // The card's inner padding from its right edge.
    expect(value.right, 390 - AppSpacing.s20 - AppSpacing.s16);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('320dp, text scale $scale: no overflow, no theme label broken '
        'mid-word, and the page scrolls to the Developer tools and dialog', (
      tester,
    ) async {
      await _pumpSettings(tester, width: 320, height: 640, scale: scale);

      expect(tester.takeException(), isNull);
      for (final label in ['System', 'Light', 'Dark']) {
        expect(_onOneLine(tester, label), isTrue, reason: label);
      }
      if (scale == 2.0) expect(_themeDirection(tester), Axis.vertical);

      await tester.scrollUntilVisible(
        find.text('Fail the next save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.text('Clear all data'));
      await tester.pumpAndSettle();
      expect(find.text('Clear all data?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
