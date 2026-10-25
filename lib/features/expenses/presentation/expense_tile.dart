import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/categories/presentation/category_icons.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

/// One ledger row: category icon, category name, note, amount.
///
/// The amount is never squeezed or wrapped. When it would leave the category
/// and note narrower than [AppSizes.ledgerMinTextWidth] (scaled with the
/// text), it moves to its own line under the category instead.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    required this.expense,
    required this.onTap,
    this.showDivider = false,
    super.key,
  });

  final Expense expense;
  final VoidCallback onTap;

  /// Draws the inset divider under this row; off for the last row of a day.
  final bool showDivider;

  /// Where the text column starts, so dividers line up with it.
  static const double textInset =
      AppSpacing.s20 + AppSizes.iconTile + AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amountStyle = AppTypography.amount.copyWith(color: scheme.onSurface);
    final amount = formatGhs(expense.amountPesewas);
    final note = expense.note;

    final categoryAndNote = [
      Text(
        expense.category.name,
        style: theme.textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      if (note != null)
        Text(
          note,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
    ];

    return Material(
      color: AppPalette.of(context).card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MergeSemantics(
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.ledgerRowMinHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                    vertical: AppSpacing.s12,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textColumn =
                          constraints.maxWidth -
                          AppSizes.iconTile -
                          AppSpacing.s12;
                      final stacked =
                          _textWidth(context, amount, amountStyle) >
                          textColumn - AppSpacing.s12 - _minTextWidth(context);
                      return Row(
                        children: [
                          _IconTile(categoryIcon(expense.category.iconKey)),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...categoryAndNote,
                                if (stacked)
                                  // Scales down only at extreme text sizes,
                                  // where one line can't fit otherwise.
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(amount, style: amountStyle),
                                  ),
                              ],
                            ),
                          ),
                          if (!stacked) ...[
                            const SizedBox(width: AppSpacing.s12),
                            Text(amount, style: amountStyle, softWrap: false),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (showDivider) const Divider(indent: textInset),
        ],
      ),
    );
  }

  /// [AppSizes.ledgerMinTextWidth] grown with the user's text size. The
  /// factor is read at the row title's font size: Android 14+ scales large
  /// font sizes less than small ones, so passing 96 to the scaler as if it
  /// were a font size would understate it.
  static double _minTextWidth(BuildContext context) {
    final fontSize = AppTypography.bodyLarge.fontSize!;
    final factor = MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;
    return AppSizes.ledgerMinTextWidth * factor;
  }

  static double _textWidth(BuildContext context, String text, TextStyle style) {
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
}

/// Neutral square with a monochrome icon; the category is named in text, so
/// the icon is decorative.
class _IconTile extends StatelessWidget {
  const _IconTile(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppSizes.iconTile,
      height: AppSizes.iconTile,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(AppRadius.r12),
      ),
      child: Icon(
        icon,
        size: AppSizes.iconTileGlyph,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
