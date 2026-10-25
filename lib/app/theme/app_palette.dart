import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_colors.dart';

/// Design tokens that have no ColorScheme role: the card surface, the chart
/// ramp and the muted bar colour.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.card,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.c4,
    required this.barMuted,
  });

  static const AppPalette light = AppPalette(
    card: AppColorsLight.surface,
    c1: AppColorsLight.c1,
    c2: AppColorsLight.c2,
    c3: AppColorsLight.c3,
    c4: AppColorsLight.c4,
    barMuted: AppColorsLight.barMuted,
  );

  static const AppPalette dark = AppPalette(
    card: AppColorsDark.surface,
    c1: AppColorsDark.c1,
    c2: AppColorsDark.c2,
    c3: AppColorsDark.c3,
    c4: AppColorsDark.c4,
    barMuted: AppColorsDark.barMuted,
  );

  /// Ledger, cards, nav and form surface.
  final Color card;

  /// Chart ramp, strongest to weakest; c4 is "other".
  final Color c1;
  final Color c2;
  final Color c3;
  final Color c4;

  /// Unselected chart bars.
  final Color barMuted;

  /// Both app themes register this extension, so a missing one is a bug.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    Color? card,
    Color? c1,
    Color? c2,
    Color? c3,
    Color? c4,
    Color? barMuted,
  }) {
    return AppPalette(
      card: card ?? this.card,
      c1: c1 ?? this.c1,
      c2: c2 ?? this.c2,
      c3: c3 ?? this.c3,
      c4: c4 ?? this.c4,
      barMuted: barMuted ?? this.barMuted,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      card: Color.lerp(card, other.card, t)!,
      c1: Color.lerp(c1, other.c1, t)!,
      c2: Color.lerp(c2, other.c2, t)!,
      c3: Color.lerp(c3, other.c3, t)!,
      c4: Color.lerp(c4, other.c4, t)!,
      barMuted: Color.lerp(barMuted, other.barMuted, t)!,
    );
  }
}
