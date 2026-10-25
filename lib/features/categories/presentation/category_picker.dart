import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/categories/presentation/category_icons.dart';
import 'package:traccash/shared/widgets/dashed_border.dart';

/// The form's category choice: two columns of options, then "+ New
/// category".
///
/// Selection shows as a thicker accent border, a tonal fill and a check icon,
/// never by colour alone. Rows rather than a fixed-height grid, so options
/// grow with the text scale instead of clipping their labels.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onNewCategory,
    super.key,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  /// Opens the new-category panel. Null while the panel is open, which hides
  /// the option.
  final VoidCallback? onNewCategory;

  @override
  Widget build(BuildContext context) {
    final onNewCategory = this.onNewCategory;
    final options = <Widget>[
      for (final category in categories)
        _CategoryOption(
          category: category,
          selected: category.id == selectedId,
          onTap: () => onSelected(category.id),
        ),
      if (onNewCategory != null) _NewCategoryOption(onTap: onNewCategory),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.s8),
            // Both options in a row take the taller one's height.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: options[i]),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: i + 1 < options.length
                        ? options[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The bordered, tappable box behind a category or icon choice: 1px outline
/// when unselected; 2px accent border and tonal fill when selected.
class OptionSurface extends StatelessWidget {
  const OptionSurface({
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : AppPalette.of(context).card,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(AppRadius.r12),
        side: selected
            ? BorderSide(color: scheme.primary, width: AppSizes.selectedBorder)
            : BorderSide(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: OptionSurface(
        selected: selected,
        onTap: onTap,
        child: _OptionContent(
          children: [
            Icon(
              categoryIcon(category.iconKey),
              size: AppSizes.iconTileGlyph,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: AppSpacing.s8),
              Icon(
                Icons.check,
                size: AppSizes.iconTileGlyph,
                color: scheme.onPrimaryContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewCategoryOption extends StatelessWidget {
  const _NewCategoryOption({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      button: true,
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: scheme.outline,
          radius: AppRadius.r12,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(AppRadius.r12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: _OptionContent(
              children: [
                Icon(
                  Icons.add,
                  size: AppSizes.iconTileGlyph,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    'New category',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
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

class _OptionContent extends StatelessWidget {
  const _OptionContent({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSizes.categoryOptionMinHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        child: Row(children: children),
      ),
    );
  }
}
