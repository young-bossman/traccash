import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/categories/presentation/category_picker.dart';
import 'package:traccash/features/categories/presentation/new_category_panel.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/shared/widgets/form_field_text.dart';

/// The form's Category section: the picker, the inline new-category panel
/// while it is open, and the field's message.
class ExpenseCategoryField extends ConsumerWidget {
  const ExpenseCategoryField({
    required this.selectedId,
    required this.currentCategoryId,
    required this.onSelected,
    required this.newCategoryOpen,
    required this.onOpenNewCategory,
    required this.newCategoryName,
    required this.onCreated,
    required this.onCancelNewCategory,
    this.error,
    super.key,
  });

  final int? selectedId;

  /// The category a stored expense already has, which stays choosable even
  /// if it was archived since. Null when adding.
  final int? currentCategoryId;
  final ValueChanged<int> onSelected;
  final bool newCategoryOpen;
  final VoidCallback onOpenNewCategory;

  /// Owned by the form, which counts a typed name as an unsaved change.
  final TextEditingController newCategoryName;
  final ValueChanged<Category> onCreated;
  final VoidCallback onCancelNewCategory;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider);
    final all = categories.value;
    final error = this.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Category'),
        const SizedBox(height: AppSpacing.s12),
        if (all != null)
          CategoryPicker(
            // Archived categories can't be chosen, but an expense may keep
            // the one it already has.
            categories: [
              for (final c in all)
                if (!c.isArchived || c.id == currentCategoryId) c,
            ],
            selectedId: selectedId,
            onSelected: onSelected,
            onNewCategory: newCategoryOpen ? null : onOpenNewCategory,
          )
        else if (categories.hasError)
          Row(
            children: [
              const Expanded(child: FieldError('Couldn’t load categories.')),
              TextButton(
                onPressed: () => ref.invalidate(allCategoriesProvider),
                child: const Text('Try again'),
              ),
            ],
          )
        else
          const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading categories',
            ),
          ),
        if (newCategoryOpen) ...[
          const SizedBox(height: AppSpacing.s8),
          NewCategoryPanel(
            name: newCategoryName,
            activeCategories: [
              for (final c in all ?? const <Category>[])
                if (!c.isArchived) c,
            ],
            onCreated: onCreated,
            onCancel: onCancelNewCategory,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpacing.s8),
          FieldError(error),
        ],
      ],
    );
  }
}
