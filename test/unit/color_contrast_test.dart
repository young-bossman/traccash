import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_theme.dart';

// WCAG 2.1 AA for normal-size text.
const double aaText = 4.5;

// Exempt from this test (WCAG 1.4.3 excludes inactive components):
// - disabled button and field text: onSurface at 38% opacity
// - disabled button fills: onSurface at 12% opacity
// - disabled field outline: outlineVariant
// Non-text colours (outline, outlineVariant, chart ramp c1-c4, barMuted) are
// out of scope here.

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  final themes = <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  };

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    group('$name theme text contrast', () {
      final s = theme.colorScheme;
      final card = theme.extension<AppPalette>()!.card;
      final dialog = theme.dialogTheme.backgroundColor!;
      final sheet = theme.bottomSheetTheme.backgroundColor!;

      final backgrounds = <String, Color>{
        'surface (bg)': s.surface,
        'card': card,
        'dialog': dialog,
        'sheet': sheet,
        'surfaceContainerLowest': s.surfaceContainerLowest,
        'surfaceContainerLow': s.surfaceContainerLow,
        'surfaceContainer': s.surfaceContainer,
        'surfaceContainerHigh': s.surfaceContainerHigh,
        'surfaceContainerHighest': s.surfaceContainerHighest,
      };

      // Text colours that can appear on any neutral surface.
      final neutralText = <String, Color>{
        'onSurface': s.onSurface,
        'onSurfaceVariant': s.onSurfaceVariant,
      };

      // Accent and error text: links, text buttons, validation messages,
      // destructive dialog actions. These sit on the screen, card and
      // overlay surfaces only.
      final accentText = <String, Color>{
        'primary': s.primary,
        'error': s.error,
      };
      final accentBackgrounds = <String, Color>{
        'surface (bg)': s.surface,
        'card': card,
        'dialog': dialog,
        'sheet': sheet,
      };

      final pairs = <String, (Color, Color)>{
        for (final fg in neutralText.entries)
          for (final bg in backgrounds.entries)
            '${fg.key} on ${bg.key}': (fg.value, bg.value),
        for (final fg in accentText.entries)
          for (final bg in accentBackgrounds.entries)
            '${fg.key} on ${bg.key}': (fg.value, bg.value),
        'onPrimary on primary': (s.onPrimary, s.primary),
        'onPrimaryContainer on primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'onSecondaryContainer on secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        // Derived colours (not in the design board).
        'onError on error': (s.onError, s.error),
        'onErrorContainer on errorContainer': (
          s.onErrorContainer,
          s.errorContainer,
        ),
        'onInverseSurface on inverseSurface': (
          s.onInverseSurface,
          s.inverseSurface,
        ),
        'inversePrimary on inverseSurface': (
          s.inversePrimary,
          s.inverseSurface,
        ),
      };

      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () {
          final ratio = contrastRatio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(aaText),
            reason: '$label is ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    });
  }
}
