import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/calculations/breakdown.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/core/formatting/percent.dart';
import 'package:traccash/features/home/presentation/home_providers.dart';
import 'package:traccash/features/home/presentation/home_section.dart';
import 'package:traccash/shared/text_measure.dart';

/// The largest-share sentence, the bar and its legend.
class HomeBreakdown extends StatelessWidget {
  const HomeBreakdown({required this.view, super.key});

  final HomeView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    // Strongest to weakest; a fourth named category shares the "others"
    // colour, as it is the smallest slice either way.
    Color colorOf(int index) =>
        [palette.c1, palette.c2, palette.c3].elementAtOrNull(index) ??
        palette.c4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeading(
          title: 'Breakdown',
          actionLabel: 'Reports',
          onAction: () => context.go(AppRoutes.reports),
        ),
        Text(
          view.largestShareSentence ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Semantics(
          container: true,
          label: view.breakdownSummary,
          child: _BreakdownBar(slices: view.slices, colorOf: colorOf),
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final (index, slice) in view.slices.indexed)
          _LegendRow(
            label: view.sliceLabel(slice),
            slice: slice,
            color: colorOf(index),
          ),
      ],
    );
  }
}

/// One segment per slice, each as wide as its share of the pesewas. Shapes
/// only: the legend below names and sizes every slice.
class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({required this.slices, required this.colorOf});

  final List<BreakdownSlice> slices;
  final Color Function(int index) colorOf;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(AppSizes.breakdownBarHeight / 2),
      ),
      child: SizedBox(
        height: AppSizes.breakdownBarHeight,
        child: Row(
          children: [
            for (final (index, slice) in slices.indexed) ...[
              if (index > 0) const SizedBox(width: AppSizes.breakdownBarGap),
              Expanded(
                flex: slice.totalPesewas,
                child: ColoredBox(color: colorOf(index)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Swatch, name, amount and share. Shares sit in a column as wide as
/// "100.0%", so amounts line up across rows.
///
/// When the figures would leave the name narrower than the ledger's minimum
/// text width (scaled with the text), they move to a line under the name.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.slice,
    required this.color,
  });

  final String label;
  final BreakdownSlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amountStyle = AppTypography.amount.copyWith(color: scheme.onSurface);
    final shareStyle = AppTypography.amount.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w400,
    );
    final amount = formatGhs(slice.totalPesewas);
    final share = formatShare(slice.shareTenths);
    final name = Text(
      label,
      style: theme.textTheme.bodyLarge,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shareWidth = singleLineWidth(
              context,
              formatShare(1000),
              shareStyle,
            );
            final nameWidth =
                constraints.maxWidth -
                AppSizes.legendSwatch -
                AppSpacing.s12 -
                AppSpacing.s12 -
                singleLineWidth(context, amount, amountStyle) -
                AppSpacing.s16 -
                shareWidth;
            final stacked = nameWidth < scaledMinTextWidth(context);

            return Row(
              children: [
                _Swatch(color),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            name,
                            Wrap(
                              spacing: AppSpacing.s16,
                              children: [
                                // Scales down only where one line can't
                                // hold it at all.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(amount, style: amountStyle),
                                ),
                                Text(share, style: shareStyle),
                              ],
                            ),
                          ],
                        )
                      : name,
                ),
                if (!stacked) ...[
                  const SizedBox(width: AppSpacing.s12),
                  Text(amount, style: amountStyle, softWrap: false),
                  const SizedBox(width: AppSpacing.s16),
                  SizedBox(
                    width: shareWidth,
                    child: Text(
                      share,
                      style: shareStyle,
                      textAlign: TextAlign.end,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.legendSwatch,
      height: AppSizes.legendSwatch,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(AppRadius.swatch),
      ),
    );
  }
}
