import 'dart:math';

import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/features/categories/presentation/category_icons.dart';
import 'package:traccash/features/reports/presentation/reports_providers.dart';
import 'package:traccash/shared/text_measure.dart';
import 'package:traccash/shared/widgets/section_card.dart';
import 'package:traccash/shared/widgets/total_amount.dart';

/// "Total spent · October 2026" over the month's total. Not a card.
class ReportsTotal extends StatelessWidget {
  const ReportsTotal({required this.view, super.key});

  final ReportsView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          view.totalLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        TotalAmount(pesewas: view.totalPesewas),
      ],
    );
  }
}

/// One figure in the stats row. [spoken] replaces what a screen reader
/// would otherwise read from the label and value.
typedef _Stat = ({String label, String value, String? spoken});

/// Expenses, Daily average and the comparison, between dividers.
///
/// The columns share the width when every figure fits on one line beside
/// the others; otherwise each stat takes a line of its own, so no figure is
/// ever clipped.
class ReportsStats extends StatelessWidget {
  const ReportsStats({required this.view, super.key});

  final ReportsView view;

  // Each column's text sits this far from the dividers around it.
  static const double _afterDivider = AppSpacing.s16;
  static const double _beforeDivider = AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = AppTypography.bodyMedium.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = AppTypography.titleSmall.copyWith(
      color: scheme.onSurface,
      fontFeatures: AppTypography.tabularFigures,
    );
    final comparison = view.comparisonValue;
    final stats = <_Stat>[
      (label: 'Expenses', value: view.expenseCountText, spoken: null),
      (label: 'Daily average', value: view.averageText, spoken: null),
      if (comparison != null)
        (
          label: view.comparisonLabel,
          value: comparison,
          spoken: view.comparisonSpoken,
        ),
    ];

    Widget statText(_Stat stat, {bool scaleDown = false}) => _StatText(
      stat: stat,
      labelStyle: labelStyle,
      valueStyle: valueStyle,
      scaleDown: scaleDown,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        LayoutBuilder(
          builder: (context, constraints) {
            final last = stats.length - 1;
            final widths = [
              for (final (i, stat) in stats.indexed)
                max(
                      singleLineWidth(context, stat.label, labelStyle),
                      singleLineWidth(context, stat.value, valueStyle),
                    ) +
                    (i > 0 ? _afterDivider : 0) +
                    (i < last ? _beforeDivider : 0),
            ];
            final spare =
                constraints.maxWidth -
                widths.fold(0.0, (sum, w) => sum + w) -
                last * theme.dividerTheme.space!;

            if (spare < 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, stat) in stats.indexed) ...[
                    if (i > 0) const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s12,
                      ),
                      child: statText(stat, scaleDown: true),
                    ),
                  ],
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, stat) in stats.indexed) ...[
                    if (i > 0) const VerticalDivider(),
                    // The spare width is shared out; the last column takes
                    // what is left, so rounding can't overflow the row.
                    if (i < last)
                      SizedBox(
                        width: widths[i] + spare / stats.length,
                        child: _cell(i, last, statText(stat)),
                      )
                    else
                      Expanded(child: _cell(i, last, statText(stat))),
                  ],
                ],
              ),
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _cell(int index, int last, Widget child) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: index > 0 ? _afterDivider : 0,
      end: index < last ? _beforeDivider : 0,
      top: AppSpacing.s16,
      bottom: AppSpacing.s16,
    ),
    child: child,
  );
}

class _StatText extends StatelessWidget {
  const _StatText({
    required this.stat,
    required this.labelStyle,
    required this.valueStyle,
    required this.scaleDown,
  });

  final _Stat stat;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  /// On a line of its own, the value shrinks only if even that line can't
  /// hold it.
  final bool scaleDown;

  @override
  Widget build(BuildContext context) {
    final value = Text(stat.value, style: valueStyle, softWrap: false);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(stat.label, style: labelStyle),
        const SizedBox(height: AppSpacing.s4),
        if (scaleDown)
          FittedBox(fit: BoxFit.scaleDown, child: value)
        else
          value,
      ],
    );
    final spoken = stat.spoken;
    return spoken == null
        ? MergeSemantics(child: content)
        : Semantics(label: spoken, excludeSemantics: true, child: content);
  }
}

/// The category with the largest total, its amount and share; on a tie,
/// every tied category and the amount each.
class LargestCategoryCard extends StatelessWidget {
  const LargestCategoryCard({required this.view, super.key});

  final ReportsView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = AppTypography.bodySmall.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final amountStyle = AppTypography.titleSmall.copyWith(
      color: scheme.onSurface,
      fontFeatures: AppTypography.tabularFigures,
    );
    final largest = view.largest;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: MergeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final figuresWidth = max(
              singleLineWidth(context, view.largestAmount, amountStyle),
              singleLineWidth(context, view.largestDetail, muted),
            );
            final nameWidth =
                constraints.maxWidth -
                AppSizes.iconTile -
                AppSpacing.s16 -
                AppSpacing.s12 -
                figuresWidth;
            // Same rule as the ledger: the figures move under the name
            // before the name gets too narrow to read.
            final stacked = nameWidth < scaledMinTextWidth(context);
            final amount = Text(
              view.largestAmount,
              style: amountStyle,
              softWrap: false,
            );
            final figures = Column(
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (stacked)
                  FittedBox(fit: BoxFit.scaleDown, child: amount)
                else
                  amount,
                Text(view.largestDetail, style: muted),
              ],
            );

            return Row(
              children: [
                Container(
                  width: AppSizes.iconTile,
                  height: AppSizes.iconTile,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: const BorderRadius.all(AppRadius.r12),
                  ),
                  child: Icon(
                    largest.length > 1
                        ? Icons.leaderboard_outlined
                        : categoryIcon(largest.single.iconKey),
                    size: AppSizes.iconTileGlyph,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(view.largestLabel, style: muted),
                      Text(view.largestName, style: theme.textTheme.bodyLarge),
                      if (stacked) ...[
                        const SizedBox(height: AppSpacing.s4),
                        figures,
                      ],
                    ],
                  ),
                ),
                if (!stacked) ...[
                  const SizedBox(width: AppSpacing.s12),
                  figures,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
