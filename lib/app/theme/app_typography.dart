import 'package:flutter/material.dart';

/// Type ramp from DESIGN_SPEC §2, set in bundled IBM Plex Sans.
///
/// Letter spacing is set to 0 explicitly because Material's defaults (e.g.
/// 0.5 on bodyLarge) would otherwise survive the merge with this theme.
abstract final class AppTypography {
  static const String fontFamily = 'IBMPlexSans';

  /// Add to any style that shows money so digits line up in columns.
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// Monthly total.
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 48 / 40,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    fontFeatures: tabularFigures,
  );

  /// The "GH₵" and pesewas beside the monthly total's cedis, which are
  /// displaySmall. Not on the design board's ramp: sized from 01-home.
  static const TextStyle totalMinor = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  /// Screen titles.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  /// Form and dialog titles.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  /// Section headings.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  /// Row titles and amounts.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  /// Body copy.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  /// Meta, notes, helper text.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  /// Buttons.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  /// Nav labels.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  /// Ledger and table amounts: bodyLarge with tabular figures.
  static const TextStyle amount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  /// Chart axis labels; Material has no role this small.
  static const TextStyle axis = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    fontFeatures: tabularFigures,
  );

  /// Roles not listed here keep Material's defaults (in Plex via
  /// ThemeData.fontFamily).
  static const TextTheme textTheme = TextTheme(
    displaySmall: displaySmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelSmall: labelSmall,
  );
}
