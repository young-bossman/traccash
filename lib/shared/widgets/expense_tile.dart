import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/categories/presentation/category_icons.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/shared/text_measure.dart';
import 'package:traccash/shared/widgets/icon_tile.dart';

/// One ledger row: category icon, category name, note, amount.
///
/// The amount is never squeezed or wrapped. When it would leave the category
/// and note narrower than [AppSizes.ledgerMinTextWidth] (scaled with the
/// text), it moves to its own line under the category instead.
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    required this.expense,
    required this.onTap,
    this.dateLabel,
    this.showDivider = false,
    super.key,
  });

  final Expense expense;
  final VoidCallback onTap;

  /// Follows the note ("Waakye and egg, lunch · Today") where no day header
  /// says when, as in Home's Recent list.
  final String? dateLabel;

  /// Draws the inset divider under this row; off for the last row of a day.
  final bool showDivider;

  static const double _sidePadding = AppSpacing.s20;

  /// Between the icon tile and the text, and between the text and the
  /// amount.
  static const double _gap = AppSpacing.s12;

  /// Where the text column starts, so dividers line up with it.
  static const double textInset = _sidePadding + AppSizes.iconTile + _gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amountStyle = AppTypography.amount.copyWith(color: scheme.onSurface);
    final amount = formatGhs(expense.amountPesewas);
    final subtitle = [?expense.note, ?dateLabel].join(' · ');

    final categoryAndNote = [
      Text(
        expense.category.name,
        style: theme.textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      if (subtitle.isNotEmpty)
        Text(
          subtitle,
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
                    horizontal: _sidePadding,
                    vertical: AppSpacing.s12,
                  ),
                  // Inside the padding, so the width is what this row really
                  // has, wherever it is placed.
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final textColumn =
                          constraints.maxWidth - AppSizes.iconTile - _gap;
                      final stacked =
                          singleLineWidth(context, amount, amountStyle) >
                          textColumn - _gap - scaledMinTextWidth(context);
                      return Row(
                        children: [
                          IconTile(categoryIcon(expense.category.iconKey)),
                          const SizedBox(width: _gap),
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
                            const SizedBox(width: _gap),
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
}
