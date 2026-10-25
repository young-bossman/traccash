import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/shared/selected_month.dart';
import 'package:traccash/shared/widgets/expense_tile.dart';

/// The month's expenses grouped by day, each day's header pinned while its
/// rows scroll beneath it.
///
/// A month has at most 31 groups, and rows inside a group are built lazily,
/// so long months stay cheap.
class ExpenseLedger extends ConsumerWidget {
  const ExpenseLedger({required this.groups, super.key});

  final List<DayGroup> groups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);

    return CustomScrollView(
      slivers: [
        for (final group in groups)
          SliverMainAxisGroup(
            key: ValueKey(group.date),
            slivers: [
              // Sized by its content, unlike SliverPersistentHeader, so it
              // grows with the text scale.
              PinnedHeaderSliver(
                child: _DayHeader(
                  label: ledgerDayLabel(group.date, today: today),
                  totalPesewas: group.totalPesewas,
                ),
              ),
              SliverList.builder(
                itemCount: group.expenses.length,
                itemBuilder: (context, index) {
                  final expense = group.expenses[index];
                  return ExpenseTile(
                    key: ValueKey(expense.id),
                    expense: expense,
                    showDivider: index < group.expenses.length - 1,
                    onTap: () =>
                        context.push(AppRoutes.editExpense(expense.id)),
                  );
                },
              ),
            ],
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.fabClearance),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.totalPesewas});

  final String label;
  final int totalPesewas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.titleSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final divider = BorderSide(color: scheme.outlineVariant);

    return Semantics(
      header: true,
      label: '$label, ${formatGhs(totalPesewas)}',
      excludeSemantics: true,
      child: DecoratedBox(
        // Opaque, so rows scrolling under the pinned header don't show
        // through.
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: divider, bottom: divider),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s8,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(child: Text(label, style: style)),
                const SizedBox(width: AppSpacing.s12),
                // Keeps room for the label; the total only scales down at
                // text sizes where it would take more than half the row.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth / 2,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      formatGhs(totalPesewas),
                      style: style?.copyWith(
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
