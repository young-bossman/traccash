import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';

// The states below are shared so Home and Expenses always word them alike.

/// First use: nothing saved in any month yet.
class FirstUseState extends StatelessWidget {
  const FirstUseState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No expenses yet',
      message:
          'Add what you spend and TracCash will total it by month and '
          'category. Your records stay on this device.',
      action: FilledButton.tonalIcon(
        onPressed: () => context.push(AppRoutes.addExpense),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}

/// [month] has no expenses, though other months do.
class EmptyMonthState extends StatelessWidget {
  const EmptyMonthState({required this.month, super.key});

  final CalendarMonth month;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.calendar_month_outlined,
      title: 'No expenses in ${month.label}',
      message: 'Nothing was recorded for this month.',
    );
  }
}

/// Expenses couldn't be read. Shows the error's own message when it is an
/// [AppError], never internals; [onRetry] reads again.
class LoadErrorState extends StatelessWidget {
  const LoadErrorState({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Couldn’t load expenses',
      message: error is AppError ? error.message : const StorageError().message,
      action: FilledButton.tonal(
        onPressed: onRetry,
        child: const Text('Try again'),
      ),
    );
  }
}

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
