import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/home/presentation/home_providers.dart';
import 'package:traccash/features/home/presentation/home_section.dart';
import 'package:traccash/shared/widgets/expense_tile.dart';
import 'package:traccash/shared/widgets/section_card.dart';

/// The selected month's latest expenses, on one card.
///
/// At most [recentCount] rows, so they are built directly rather than
/// lazily.
class HomeRecent extends StatelessWidget {
  const HomeRecent({required this.view, super.key});

  final HomeView view;

  @override
  Widget build(BuildContext context) {
    final recent = view.recent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeading(
          title: 'Recent',
          actionLabel: 'View all',
          onAction: () => context.go(AppRoutes.expenses),
        ),
        const SizedBox(height: AppSpacing.s8),
        SectionCard(
          child: Column(
            children: [
              for (final (index, expense) in recent.indexed)
                ExpenseTile(
                  key: ValueKey(expense.id),
                  expense: expense,
                  dateLabel: view.recentDateLabel(expense),
                  showDivider: index < recent.length - 1,
                  onTap: () => context.push(AppRoutes.editExpense(expense.id)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
