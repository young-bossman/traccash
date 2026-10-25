import 'package:flutter/painting.dart';

/// Spacing scale (unit 4) from DESIGN_SPEC §3.
abstract final class AppSpacing {
  /// Label to value.
  static const double s4 = 4;

  /// Grid gaps, chips.
  static const double s8 = 8;

  /// Row gap, row vertical padding.
  static const double s12 = 12;

  /// Container inset.
  static const double s16 = 16;

  /// Screen gutter.
  static const double s20 = 20;

  /// Dialog padding.
  static const double s24 = 24;

  /// Between sections.
  static const double s28 = 28;

  /// Major breaks.
  static const double s32 = 32;
}

/// Corner radii from DESIGN_SPEC §3.
abstract final class AppRadius {
  /// Fields, chips, snackbar.
  static const Radius r8 = Radius.circular(8);

  /// Buttons, tiles, containers.
  static const Radius r12 = Radius.circular(12);

  /// Add button, dialog, sheet.
  static const Radius r16 = Radius.circular(16);

  /// Icon buttons and the nav indicator pill.
  static const OutlinedBorder full = StadiumBorder();
}

/// Fixed component sizes from DESIGN_SPEC §4.
abstract final class AppSizes {
  static const double navBarHeight = 80;

  /// Also the minimum touch target.
  static const double buttonHeight = 48;
}

/// The design allows a single shadow level, reserved for floating layers
/// (add button, snackbar, dialog, sheet); everything else separates with
/// 1px borders.
abstract final class AppElevation {
  static const double none = 0;
  static const double floating = 3;
}
