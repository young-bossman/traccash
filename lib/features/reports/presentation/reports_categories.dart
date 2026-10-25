import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/core/formatting/percent.dart';
import 'package:traccash/features/categories/presentation/category_icons.dart';
import 'package:traccash/features/reports/presentation/reports_providers.dart';
import 'package:traccash/shared/text_measure.dart';
import 'package:traccash/shared/widgets/section_card.dart';

/// "By category": every category with spending this month, largest first.
///
/// A user has a handful of categories, so the rows are built directly
/// rather than lazily.
class ReportsCategories extends StatelessWidget {
  const ReportsCategories({required this.view, super.key});

  final ReportsView view;

  @override
  Widget build(BuildContext context) {
    final rows = view.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'By category',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        SectionCard(
          child: Column(
            children: [
              for (final (index, row) in rows.indexed)
                _CategoryRow(
                  key: ValueKey(row.total.category.id),
                  view: view,
                  row: row,
                  showDivider: index < rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon, "Bills · 3 expenses", amount and share, over a bar as long as the
/// share. Shares sit in a column as wide as "100.0%", so amounts line up.
///
/// When the figures would leave the name narrower than the ledger's minimum
/// text width (scaled with the text), they move to a line under the name.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.view,
    required this.row,
    required this.showDivider,
    super.key,
  });

  final ReportsView view;
  final CategoryShare row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amountStyle = AppTypography.amount.copyWith(color: scheme.onSurface);
    final shareStyle = AppTypography.amount.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w400,
    );
    final category = row.total.category;
    final amount = formatGhs(row.total.totalPesewas);
    final share = formatShare(row.shareTenths);
    final name = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: category.name,
            style: AppTypography.bodyLarge.copyWith(color: scheme.onSurface),
          ),
          TextSpan(
            text: ' · ${view.expenseCountLabel(row)}',
            style: AppTypography.bodyLarge.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final shareWidth = singleLineWidth(
                      context,
                      formatShare(1000),
                      shareStyle,
                    );
                    final nameWidth =
                        constraints.maxWidth -
                        AppSizes.iconTileGlyph -
                        AppSpacing.s12 -
                        AppSpacing.s12 -
                        singleLineWidth(context, amount, amountStyle) -
                        AppSpacing.s16 -
                        shareWidth;
                    final stacked = nameWidth < scaledMinTextWidth(context);

                    return Row(
                      children: [
                        Icon(
                          categoryIcon(category.iconKey),
                          size: AppSizes.iconTileGlyph,
                          color: scheme.onSurfaceVariant,
                        ),
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
                                        // Scales down only where one line
                                        // can't hold it at all.
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            amount,
                                            style: amountStyle,
                                          ),
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
                const SizedBox(height: AppSpacing.s8),
                _ShareBar(tenths: row.shareTenths),
              ],
            ),
          ),
          if (showDivider) const Divider(indent: AppSpacing.s16),
        ],
      ),
    );
  }
}

/// A track with the category's share filled in. Shapes only: the share is
/// written beside the amount.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.tenths});

  /// Tenths of a percent: 1000 fills the track.
  final int tenths;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(
      Radius.circular(AppSizes.shareBarHeight / 2),
    );
    return ExcludeSemantics(
      child: Container(
        height: AppSizes.shareBarHeight,
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: radius,
        ),
        child: FractionallySizedBox(
          widthFactor: tenths / 1000,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: radius,
            ),
          ),
        ),
      ),
    );
  }
}
