import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';

/// Icon tile, title, explanation and an optional tonal action, centred.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  /// A tonal button, per DESIGN_SPEC §4 ("Tonal inside empty states").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSizes.emptyStateTile,
          height: AppSizes.emptyStateTile,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.all(AppRadius.r16),
          ),
          child: Icon(
            icon,
            size: AppSizes.emptyStateGlyph,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.s20),
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[
          const SizedBox(height: AppSpacing.s24),
          action!,
        ],
      ],
    );
  }
}
