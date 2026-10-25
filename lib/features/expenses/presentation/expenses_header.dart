import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/presentation/category_filter_sheet.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/shared/widgets/month_switcher.dart';

/// Title, month switcher, summary line, search and the active filter chip.
class ExpensesHeader extends ConsumerWidget {
  const ExpensesHeader({
    required this.search,
    required this.onClearFilters,
    super.key,
  });

  final TextEditingController search;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final view = ref.watch(expensesViewProvider).value;
    // Hidden only once we know nothing has ever been saved, so the row
    // doesn't flicker away while a month loads.
    final showSearch = view == null || view.hasAnyExpenses;
    // Read directly rather than from the view, so the chip stays put while
    // a month loads.
    final filterCategory = ref.watch(filterCategoryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s20,
        AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wraps the switcher under the title when large text leaves no
          // room beside it. Full width because a Wrap given a loose width
          // shrinks to its children, leaving spaceBetween nothing to spread.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  header: true,
                  child: Text('Expenses', style: theme.textTheme.titleLarge),
                ),
                const MonthSwitcher(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          // While loading, the line keeps its height but shows no figures,
          // so a new month's label never sits over the old month's total.
          Text(
            view?.summary ?? ' ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (showSearch) ...[
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(child: _SearchField(controller: search)),
                const SizedBox(width: AppSpacing.s8),
                _FilterButton(
                  active: filterCategory != null,
                  enabled: view != null,
                ),
              ],
            ),
          ],
          if (filterCategory != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CategoryChip(category: filterCategory),
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.read(expenseFiltersProvider.notifier);

    // Rebuilt on each keystroke only to show or hide the clear button.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextField(
        controller: controller,
        onChanged: filters.setQuery,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search notes or categories',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    filters.clearQuery();
                  },
                ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.enabled});

  /// A category is selected: tonal fill and accent border, as in the design.
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: active,
      child: IconButton(
        onPressed: enabled ? () => showCategoryFilterSheet(context) : null,
        tooltip: 'Filter by category',
        icon: const Icon(Icons.filter_list),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.buttonHeight),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadius.r12),
          ),
          backgroundColor: active
              ? scheme.primaryContainer
              : AppPalette.of(context).card,
          foregroundColor: active
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
          side: BorderSide(color: active ? scheme.primary : scheme.outline),
        ),
      ),
    );
  }
}

class _CategoryChip extends ConsumerWidget {
  const _CategoryChip({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InputChip(
      label: Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      labelStyle: theme.textTheme.bodyLarge?.copyWith(
        color: scheme.onPrimaryContainer,
      ),
      backgroundColor: scheme.primaryContainer,
      side: BorderSide(color: scheme.primary),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(AppRadius.r8),
      ),
      deleteIcon: const Icon(Icons.close),
      deleteIconColor: scheme.onPrimaryContainer,
      deleteButtonTooltipMessage: 'Remove ${category.name} filter',
      onDeleted: () =>
          ref.read(expenseFiltersProvider.notifier).setCategory(null),
    );
  }
}
