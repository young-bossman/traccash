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
  /// Breakdown legend swatches; too small for r8, and not on the design
  /// board's scale.
  static const Radius swatch = Radius.circular(2);

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

  /// Ledger row (`ExpenseTile`).
  static const double ledgerRowMinHeight = 64;

  /// Neutral square behind a category icon in a ledger row.
  static const double iconTile = 40;

  static const double iconTileGlyph = 20;

  /// Narrowest the category and note may get beside a ledger amount (at text
  /// scale 1.0) before the amount moves to its own line.
  static const double ledgerMinTextWidth = 96;

  /// The app mark beside "TracCash" on Home.
  static const double logoTile = 28;

  static const double logoGlyph = 18;

  /// Home's category breakdown bar.
  static const double breakdownBarHeight = 8;

  /// Between the bar's segments.
  static const double breakdownBarGap = 2;

  /// Colour square at the start of a breakdown legend row.
  static const double legendSwatch = 10;

  /// Icon square at the top of an empty state.
  static const double emptyStateTile = 56;

  static const double emptyStateGlyph = 28;

  /// Keeps the last ledger row scrollable clear of the add button.
  static const double fabClearance = 88;

  /// Category option in the form's picker. A minimum: it grows with the
  /// text scale.
  static const double categoryOptionMinHeight = 52;

  /// Border of a selected category or icon choice; unselected ones use 1.
  static const double selectedBorder = 2;

  /// Line under the amount, the form's main input.
  static const double amountUnderline = 2;

  /// Dashes on the "New category" option's border.
  static const double dash = 4;

  static const double dashGap = 3;

  /// Icon at the start of an inline error message.
  static const double inlineIcon = 18;
}

/// The design allows a single shadow level, reserved for floating layers
/// (add button, snackbar, dialog, sheet); everything else separates with
/// 1px borders.
abstract final class AppElevation {
  static const double none = 0;
  static const double floating = 3;
}
