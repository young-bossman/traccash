import 'package:flutter/widgets.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';

/// Width of [text] in [style] on one line, at the user's text size.
double singleLineWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// [AppSizes.ledgerMinTextWidth] grown with the user's text size: the
/// narrowest a name may get beside an amount before the amount moves to its
/// own line.
///
/// The factor is read at the row title's font size: Android 14+ scales large
/// font sizes less than small ones, so passing 96 to the scaler as if it
/// were a font size would understate it.
double scaledMinTextWidth(BuildContext context) {
  final fontSize = AppTypography.bodyLarge.fontSize!;
  final factor = MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;
  return AppSizes.ledgerMinTextWidth * factor;
}
