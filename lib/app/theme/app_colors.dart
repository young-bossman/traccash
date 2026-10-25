import 'package:flutter/painting.dart';

// Colour tokens from DESIGN_SPEC §1. This is the only file with hex values;
// widgets read them through Theme.of(context) and AppPalette.

/// Light theme tokens.
abstract final class AppColorsLight {
  static const Color bg = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFEEF1F5);
  static const Color border = Color(0xFFD0D5DD);
  static const Color divider = Color(0xFFEAECF0);
  static const Color text = Color(0xFF101828);
  static const Color text2 = Color(0xFF5B6577);

  // #20C997 from the original brief is only ~2.1:1 on white; this passes AA.
  static const Color accent = Color(0xFF0F7B5F);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentTonal = Color(0xFFE3F4EE);
  static const Color onTonal = Color(0xFF0B5C47);

  static const Color error = Color(0xFFB42318);
  // Not in the spec: white on error is ~6.6:1.
  static const Color onError = Color(0xFFFFFFFF);
  // Not in the spec: pale red fill with deep red text, ~7.2:1.
  static const Color errorTonal = Color(0xFFFEE4E2);
  static const Color onErrorTonal = Color(0xFF912018);

  static const Color inverse = Color(0xFF1D2939);
  // Not in the spec: reuses the dark theme's text colour, ~14:1 on inverse.
  static const Color onInverse = Color(0xFFF9FAFB);
  // Not in the spec: the dark theme's accent reads ~6.9:1 on the light inverse.
  static const Color inverseAccent = Color(0xFF20C997);

  static const Color c1 = Color(0xFF0F7B5F);
  static const Color c2 = Color(0xFF3D9A7E);
  static const Color c3 = Color(0xFFA3D7C5);
  static const Color c4 = Color(0xFFC4CAD4);
  static const Color barMuted = Color(0xFF8A94A6);
}

/// Dark theme tokens.
abstract final class AppColorsDark {
  static const Color bg = Color(0xFF101827);
  static const Color surface = Color(0xFF182230);
  static const Color surface2 = Color(0xFF202C3C);
  static const Color border = Color(0xFF344054);
  static const Color divider = Color(0xFF263244);
  static const Color text = Color(0xFFF9FAFB);
  static const Color text2 = Color(0xFFAAB4C3);

  static const Color accent = Color(0xFF20C997);
  // Dark text on the bright accent, ~8.3:1.
  static const Color onAccent = Color(0xFF101827);
  static const Color accentTonal = Color(0xFF123A30);
  static const Color onTonal = Color(0xFF8BE6C8);

  static const Color error = Color(0xFFF97066);
  // Not in the spec: mirrors onAccent, ~6.3:1 on error.
  static const Color onError = Color(0xFF101827);
  // Not in the spec: deep red fill with pale red text, ~9.9:1.
  static const Color errorTonal = Color(0xFF55160C);
  static const Color onErrorTonal = Color(0xFFFECDCA);

  static const Color inverse = Color(0xFFE4E7EC);
  // Not in the spec: reuses the light theme's text colour, ~14:1 on inverse.
  static const Color onInverse = Color(0xFF101828);
  // Not in the spec: the light on-tonal green, ~6.4:1 on the pale inverse
  // (the light accent #0F7B5F falls just short of AA there).
  static const Color inverseAccent = Color(0xFF0B5C47);

  static const Color c1 = Color(0xFF20C997);
  static const Color c2 = Color(0xFF16916E);
  static const Color c3 = Color(0xFF0E5A46);
  static const Color c4 = Color(0xFF475467);
  static const Color barMuted = Color(0xFF63718A);
}
