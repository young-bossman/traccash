import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_colors.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';

/// Light and dark themes built from explicit ColorSchemes (not fromSeed) so
/// every token stays exactly as specified in DESIGN_SPEC §1.
abstract final class AppTheme {
  static final ThemeData light = _build(
    scheme: _lightScheme,
    palette: AppPalette.light,
    // Light dialogs and sheets sit on the card surface.
    overlaySurface: AppColorsLight.surface,
  );

  static final ThemeData dark = _build(
    scheme: _darkScheme,
    palette: AppPalette.dark,
    // DESIGN_SPEC: surface-2 for dialogs and sheets in dark, so they stand
    // out from the card surface below.
    overlaySurface: AppColorsDark.surface2,
  );

  // One accent: secondary and tertiary repeat the primary family so no
  // Material default can introduce a second hue.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColorsLight.accent,
    onPrimary: AppColorsLight.onAccent,
    primaryContainer: AppColorsLight.accentTonal,
    onPrimaryContainer: AppColorsLight.onTonal,
    secondary: AppColorsLight.accent,
    onSecondary: AppColorsLight.onAccent,
    secondaryContainer: AppColorsLight.accentTonal,
    onSecondaryContainer: AppColorsLight.onTonal,
    tertiary: AppColorsLight.accent,
    onTertiary: AppColorsLight.onAccent,
    tertiaryContainer: AppColorsLight.accentTonal,
    onTertiaryContainer: AppColorsLight.onTonal,
    error: AppColorsLight.error,
    onError: AppColorsLight.onError,
    errorContainer: AppColorsLight.errorTonal,
    onErrorContainer: AppColorsLight.onErrorTonal,
    surface: AppColorsLight.bg,
    onSurface: AppColorsLight.text,
    onSurfaceVariant: AppColorsLight.text2,
    // Dim is the greyest token, bright the whitest.
    surfaceDim: AppColorsLight.surface2,
    surfaceBright: AppColorsLight.surface,
    // Spec maps surface (white) here.
    surfaceContainerLowest: AppColorsLight.surface,
    // Cards and sheets default to this role; spec puts cards on surface.
    surfaceContainerLow: AppColorsLight.surface,
    // Nav bar and menus default to this role; spec puts nav on surface.
    surfaceContainer: AppColorsLight.surface,
    // Spec maps surface-2 here (icon tiles, tracks).
    surfaceContainerHigh: AppColorsLight.surface2,
    // No darker token; border would drop text-2 below AA.
    surfaceContainerHighest: AppColorsLight.surface2,
    outline: AppColorsLight.border,
    outlineVariant: AppColorsLight.divider,
    inverseSurface: AppColorsLight.inverse,
    onInverseSurface: AppColorsLight.onInverse,
    inversePrimary: AppColorsLight.inverseAccent,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColorsDark.accent,
    onPrimary: AppColorsDark.onAccent,
    primaryContainer: AppColorsDark.accentTonal,
    onPrimaryContainer: AppColorsDark.onTonal,
    secondary: AppColorsDark.accent,
    onSecondary: AppColorsDark.onAccent,
    secondaryContainer: AppColorsDark.accentTonal,
    onSecondaryContainer: AppColorsDark.onTonal,
    tertiary: AppColorsDark.accent,
    onTertiary: AppColorsDark.onAccent,
    tertiaryContainer: AppColorsDark.accentTonal,
    onTertiaryContainer: AppColorsDark.onTonal,
    error: AppColorsDark.error,
    onError: AppColorsDark.onError,
    errorContainer: AppColorsDark.errorTonal,
    onErrorContainer: AppColorsDark.onErrorTonal,
    surface: AppColorsDark.bg,
    onSurface: AppColorsDark.text,
    onSurfaceVariant: AppColorsDark.text2,
    // Dim is the darkest token, bright the lightest.
    surfaceDim: AppColorsDark.bg,
    surfaceBright: AppColorsDark.surface2,
    // Nothing sits below the app background in dark.
    surfaceContainerLowest: AppColorsDark.bg,
    // Cards and sheets default to this role; spec puts cards on surface.
    surfaceContainerLow: AppColorsDark.surface,
    // Nav bar and menus default to this role; spec puts nav on surface.
    surfaceContainer: AppColorsDark.surface,
    // Spec maps surface-2 here (tiles, dialogs, sheets).
    surfaceContainerHigh: AppColorsDark.surface2,
    // No lighter surface token exists.
    surfaceContainerHighest: AppColorsDark.surface2,
    outline: AppColorsDark.border,
    outlineVariant: AppColorsDark.divider,
    inverseSurface: AppColorsDark.inverse,
    onInverseSurface: AppColorsDark.onInverse,
    inversePrimary: AppColorsDark.inverseAccent,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required AppPalette palette,
    required Color overlaySurface,
  }) {
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(AppRadius.r12),
    );
    const buttonMinSize = Size(64, AppSizes.buttonHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.s16);

    OutlineInputBorder inputBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: const BorderRadius.all(AppRadius.r8),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [palette],
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navBarHeight,
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.none,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: AppRadius.full,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppTypography.labelSmall.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                )
              : AppTypography.labelSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: AppElevation.floating,
        focusElevation: AppElevation.floating,
        hoverElevation: AppElevation.floating,
        highlightElevation: AppElevation.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.r16),
        ),
        extendedTextStyle: AppTypography.labelLarge,
      ),
      // Shape and size only, so FilledButton and FilledButton.tonal keep
      // their own primary / secondaryContainer colours.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: AppTypography.labelLarge,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: palette.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: AppTypography.bodySmall.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: scheme.error),
        errorMaxLines: 2,
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        disabledBorder: inputBorder(scheme.outlineVariant),
        focusedBorder: inputBorder(scheme.primary, width: 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, width: 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: overlaySurface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.r16),
        ),
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: overlaySurface,
        modalBackgroundColor: overlaySurface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.floating,
        modalElevation: AppElevation.floating,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.r16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: AppElevation.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.r8),
        ),
      ),
    );
  }
}
