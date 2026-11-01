import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_scenarios.dart';
import 'test_app.dart';

/// Android's "Large" font size. The screen tests already cover 2.0; layouts
/// that switch at a width can still break in between.
const double largeTextScale = 1.3;

/// The narrowest supported phone and a common one.
const List<Size> _screens = [Size(320, 640), Size(360, 800)];

/// Roughly a phone keyboard at these sizes.
const double _keyboardHeight = 300;

/// Every scenario at [largeTextScale] on each screen, then again with the
/// keyboard open where a field can have focus. An overflow is reported as
/// an exception, which fails the test.
void defineTextScaleTests() {
  for (final size in _screens) {
    final label = '${size.width.toInt()}×${size.height.toInt()}dp';

    group('$label at text scale $largeTextScale', () {
      for (final scenario in scenarios) {
        testWidgets('$scenario: no overflow', (tester) async {
          _setUp(tester, size);
          await scenario.open(tester, ThemeMode.light);

          expect(scenario.shows, findsWidgets);
          expect(tester.takeException(), isNull);
        });
      }
    });

    group('$label at text scale $largeTextScale, keyboard open', () {
      for (final scenario in scenarios.where((s) => s.typing)) {
        testWidgets('$scenario: no overflow', (tester) async {
          _setUp(tester, size);
          await scenario.open(tester, ThemeMode.light);
          tester.view.viewInsets = const FakeViewPadding(
            bottom: _keyboardHeight,
          );
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}

void _setUp(WidgetTester tester, Size size) {
  setScreenSize(tester, size);
  tester.platformDispatcher.textScaleFactorTestValue = largeTextScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
