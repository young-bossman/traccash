import 'package:flutter/services.dart';
import 'package:traccash/app/theme/app_typography.dart';

/// Loads the bundled IBM Plex Sans in place of the Ahem test font, for
/// layout tests that depend on real glyph widths. Once loaded it stays for
/// the rest of the test file; each file runs separately, so other files
/// keep Ahem.
Future<void> loadPlex() async {
  final loader = FontLoader(AppTypography.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    loader.addFont(rootBundle.load('assets/fonts/IBMPlexSans-$weight.ttf'));
  }
  await loader.load();
}
