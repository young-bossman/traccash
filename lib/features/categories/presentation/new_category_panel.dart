import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/features/categories/data/category_repository.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/categories/domain/category_validation.dart';
import 'package:traccash/features/categories/presentation/category_icons.dart';
import 'package:traccash/features/categories/presentation/category_picker.dart';
import 'package:traccash/shared/rune_length_limit.dart';
import 'package:traccash/shared/widgets/form_field_text.dart';

/// Creates a category from inside the expense form (DESIGN_SPEC §5b): a name
/// and one of the user icons.
///
/// Messages appear after the first Add, then follow the typing. The live
/// duplicate check only covers active categories; the repository has the
/// final say, and brings back an archived category of the same name.
class NewCategoryPanel extends ConsumerStatefulWidget {
  const NewCategoryPanel({
    required this.name,
    required this.activeCategories,
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  static const Key nameKey = ValueKey<String>('new-category-name');

  /// Owned by the form, which counts a typed name as an unsaved change.
  final TextEditingController name;

  final List<Category> activeCategories;
  final ValueChanged<Category> onCreated;
  final VoidCallback onCancel;

  @override
  ConsumerState<NewCategoryPanel> createState() => _NewCategoryPanelState();
}

class _NewCategoryPanelState extends ConsumerState<NewCategoryPanel> {
  String _iconKey = userIconKeys.first;
  bool _submitted = false;
  AsyncValue<void> _create = const AsyncData(null);

  /// Why the repository refused the last Add, shown until the name changes.
  String? _rejection;
  late String _lastName = widget.name.text;
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.name.addListener(_onNameChanged);
    // Not `autofocus`, which yields to a field that already has focus (the
    // amount, usually). Opening the panel means the user wants to type a
    // name now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(NewCategoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      oldWidget.name.removeListener(_onNameChanged);
      widget.name.addListener(_onNameChanged);
    }
  }

  @override
  void dispose() {
    widget.name.removeListener(_onNameChanged);
    _nameFocus.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    // The controller also notifies when only the cursor moves.
    if (widget.name.text == _lastName) return;
    _lastName = widget.name.text;
    setState(() => _rejection = null);
  }

  String? get _error {
    if (!_submitted) return null;
    final name = normalizeCategoryName(widget.name.text);
    final invalid = validateNewCategory(name, _iconKey);
    if (invalid != null) return invalid.message;
    final existing = findCategoryNamed(name, widget.activeCategories);
    if (existing != null) return DuplicateCategoryError(existing.name).message;
    return _rejection;
  }

  Future<void> _add() async {
    if (_create.isLoading) return;
    setState(() {
      _submitted = true;
      _rejection = null;
    });
    if (_error != null) return;

    setState(() => _create = const AsyncLoading());
    final Category category;
    try {
      category = await ref
          .read(categoryRepositoryProvider)
          .create(widget.name.text, _iconKey);
    } catch (error) {
      if (mounted) {
        setState(() {
          _create = const AsyncData(null);
          _rejection = error is AppError
              ? error.message
              : const StorageError().message;
        });
      }
      // Anything but an AppError is a bug: report it, don't hide it.
      if (error is! AppError) rethrow;
      return;
    }
    if (!mounted) return;
    setState(() => _create = const AsyncData(null));
    widget.onCreated(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = _error;
    final busy = _create.isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.of(context).card,
        border: Border.all(color: scheme.outline),
        borderRadius: const BorderRadius.all(AppRadius.r12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('New category', style: theme.textTheme.titleSmall),
            ),
            const SizedBox(height: AppSpacing.s12),
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('Name'),
                  const SizedBox(height: AppSpacing.s8),
                  TextField(
                    key: NewCategoryPanel.nameKey,
                    controller: widget.name,
                    focusNode: _nameFocus,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    inputFormatters: const [
                      RuneLengthLimitingTextInputFormatter(
                        maxCategoryNameLength,
                      ),
                    ],
                    buildCounter: runeCounter(
                      widget.name,
                      maxCategoryNameLength,
                    ),
                    decoration: InputDecoration(
                      hintText: 'For example, School fees',
                      error: error == null ? null : FieldError(error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            const FieldLabel('Icon'),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final key in userIconKeys)
                  _IconChoice(
                    iconKey: key,
                    selected: key == _iconKey,
                    onTap: () => setState(() => _iconKey = key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                TextButton(
                  onPressed: busy ? null : widget.onCancel,
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : _add,
                  child: Text(busy ? 'Adding…' : 'Add category'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = userIconLabel(iconKey);

    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: label,
        child: SizedBox.square(
          dimension: AppSizes.buttonHeight,
          child: OptionSurface(
            selected: selected,
            onTap: onTap,
            child: Icon(
              categoryIcon(iconKey),
              size: AppSizes.iconTileGlyph,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
