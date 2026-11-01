import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/router.dart';

import 'form_test_helpers.dart';
import 'screen_scenarios.dart';
import 'test_app.dart';

// Flutter's own checks, on every screen, sheet and dialog in both themes:
// - androidTapTargetGuideline: everything tappable is at least 48 × 48.
// - labeledTapTargetGuideline: everything tappable has a label or tooltip.
// - textContrastGuideline: rendered text meets WCAG AA (4.5:1, or 3:1 for
//   large text) against what is actually drawn behind it.
// Disabled controls are exempt from contrast, as in WCAG 1.4.3.
// test/unit/color_contrast_test.dart checks the same pairs as tokens.

void main() {
  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    group('${theme.name} theme', () {
      for (final scenario in scenarios) {
        testWidgets('$scenario meets the tap target, label and contrast '
            'guidelines', (tester) async {
          final semantics = tester.ensureSemantics();
          // Tall, so most of each page is on screen and checked at once.
          setScreenSize(tester, const Size(412, 1400));
          await scenario.open(tester, theme);
          expect(scenario.shows, findsWidgets);

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      }
    });
  }

  group('icon-only buttons are announced by name', () {
    testWidgets('Expenses header', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpTestApp(tester, location: AppRoutes.expenses, seed: busySeed);
      await tester.enterText(find.byType(TextField), 'Food');
      await tester.pumpAndSettle();

      for (final name in [
        'Previous month',
        'Next month',
        'Filter by category',
        'Clear search',
      ]) {
        expect(
          tester.getSemantics(find.byTooltip(name)),
          isSemantics(tooltip: name, isButton: true),
          reason: name,
        );
      }
      semantics.dispose();
    });

    testWidgets('edit form app bar', (tester) async {
      final semantics = tester.ensureSemantics();
      await openEditForm(tester, seed: busySeed, id: largeExpenseId);

      for (final name in ['Close', 'Delete expense']) {
        expect(
          tester.getSemantics(find.byTooltip(name)),
          isSemantics(tooltip: name, isButton: true),
          reason: name,
        );
      }
      semantics.dispose();
    });
  });
}
