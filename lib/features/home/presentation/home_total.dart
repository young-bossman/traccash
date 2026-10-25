import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/calculations/comparison.dart';
import 'package:traccash/features/home/presentation/home_providers.dart';
import 'package:traccash/shared/widgets/total_amount.dart';

/// "Spent so far this month", the month's total and the comparison line.
/// Not a card (DESIGN_SPEC §4).
class HomeTotal extends StatelessWidget {
  const HomeTotal({required this.view, super.key});

  final HomeView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final comparison = view.comparison;
    final comparisonText = view.comparisonText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          view.totalLabel,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.s4),
        TotalAmount(pesewas: view.totalPesewas),
        if (comparison != null && comparisonText != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decorative: the words say which way.
              Icon(
                switch (comparison.change) {
                  SpendingChange.less => Icons.trending_down,
                  SpendingChange.more => Icons.trending_up,
                  SpendingChange.same => Icons.trending_flat,
                },
                size: AppSizes.inlineIcon,
                color: muted,
              ),
              const SizedBox(width: AppSpacing.s8),
              Flexible(
                child: Text(
                  comparisonText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
