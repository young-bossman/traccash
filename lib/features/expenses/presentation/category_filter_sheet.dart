import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/calculations/ledger.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';

/// Opens the single-choice category filter for the selected month.
Future<void> showCategoryFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => const CategoryFilterSheet(),
  );
}

/// "All categories", then every active category and any archived one used
/// in the selected month, each with its count for that month. Choosing one
/// applies it and closes the sheet.
class CategoryFilterSheet extends ConsumerWidget {
  const CategoryFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expenses = ref.watch(monthExpensesProvider).value ?? const [];
    final categories = ref.watch(allCategoriesProvider).value ?? const [];
    final selected = ref.watch(expenseFiltersProvider).categoryId;
    final counts = categoryCounts(expenses, categories);

    void choose(int? categoryId) {
      ref.read(expenseFiltersProvider.notifier).setCategory(categoryId);
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.s24,
              end: AppSpacing.s8,
              top: AppSpacing.s8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Filter by category',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const CloseButton(),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: RadioGroup<int?>(
                groupValue: selected,
                onChanged: choose,
                child: Column(
                  children: [
                    _Option(
                      value: null,
                      label: 'All categories',
                      count: expenses.length,
                    ),
                    for (final (:category, :count) in counts)
                      _Option(
                        value: category.id,
                        label: category.name,
                        count: count,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.value,
    required this.label,
    required this.count,
  });

  /// Null for "All categories".
  final int? value;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RadioListTile<int?>(
      value: value,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      title: Text(label),
      secondary: Semantics(
        label: count == 1 ? '1 expense' : '$count expenses',
        excludeSemantics: true,
        child: Text(
          '$count',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
