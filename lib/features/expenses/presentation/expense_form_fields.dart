import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense_validation.dart';
import 'package:traccash/shared/rune_length_limit.dart';
import 'package:traccash/shared/widgets/form_field_text.dart';

/// Read-only date box that opens the date picker (1 January 2000 to today),
/// with "Today · …" under it.
class ExpenseDateField extends StatelessWidget {
  const ExpenseDateField({
    required this.date,
    required this.today,
    required this.onChanged,
    this.error,
    super.key,
  });

  final LocalDate date;
  final LocalDate today;
  final ValueChanged<LocalDate> onChanged;
  final String? error;

  Future<void> _pick(BuildContext context) async {
    // A phone clock set back can leave a stored date after "today", and the
    // picker asserts that its starting date is inside the range.
    final initial = date.compareTo(today) > 0
        ? today
        : date.compareTo(earliestExpenseDate) < 0
        ? earliestExpenseDate
        : date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toLocalDateTime(),
      firstDate: earliestExpenseDate.toLocalDateTime(),
      lastDate: today.toLocalDateTime(),
    );
    if (picked != null && context.mounted) {
      onChanged(LocalDate.fromDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = this.error;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Date'),
          const SizedBox(height: AppSpacing.s8),
          Semantics(
            button: true,
            hint: 'Choose a date',
            child: InkWell(
              onTap: () => _pick(context),
              borderRadius: const BorderRadius.all(AppRadius.r8),
              child: InputDecorator(
                decoration: InputDecoration(
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  helperText: dateFieldHelper(date, today: today),
                  error: error == null ? null : FieldError(error),
                ),
                child: Text(
                  formatNumericDate(date),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional note, up to [maxNoteLength] code points, with an `N / 200`
/// counter.
class NoteField extends StatelessWidget {
  const NoteField({
    required this.controller,
    required this.fieldKey,
    this.error,
    super.key,
  });

  final TextEditingController controller;

  /// Put on the TextField itself, for tests.
  final Key fieldKey;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final error = this.error;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Note', trailing: 'Optional'),
          const SizedBox(height: AppSpacing.s8),
          TextField(
            key: fieldKey,
            controller: controller,
            minLines: 3,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: const [
              RuneLengthLimitingTextInputFormatter(maxNoteLength),
            ],
            buildCounter: runeCounter(controller, maxNoteLength),
            decoration: InputDecoration(
              hintText: 'What was it for? For example, lunch at the office',
              hintMaxLines: 3,
              error: error == null ? null : FieldError(error),
            ),
          ),
        ],
      ),
    );
  }
}

/// The form's one primary action, pinned under the content.
///
/// Scaffold places `bottomNavigationBar` at the bottom of the screen even
/// with the keyboard open, so this pads itself by the keyboard height to sit
/// just above it.
class SaveBar extends StatelessWidget {
  const SaveBar({required this.label, required this.onPressed, super.key});

  final String label;

  /// Null while a write is running, which disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppPalette.of(context).card,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s20,
              vertical: AppSpacing.s12,
            ),
            child: FilledButton(onPressed: onPressed, child: Text(label)),
          ),
        ),
      ),
    );
  }
}

/// Shown at the top of the form when a save or delete fails. Every value
/// stays as entered; screen readers announce the banner when it appears.
class SaveErrorBanner extends StatelessWidget {
  const SaveErrorBanner({required this.error, super.key});

  static const String title = 'Couldn’t save this expense';

  static const String storageMessage =
      'Nothing was written to the device. Your entry is still here, so you '
      'can try again.';

  final Object error;

  /// A typed error's own message (for example "This expense no longer
  /// exists."), or [storageMessage] for a storage failure or anything
  /// unexpected.
  String get message => switch (error) {
    StorageError() => storageMessage,
    final AppError appError => appError.message,
    _ => storageMessage,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: const BorderRadius.all(AppRadius.r12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: scheme.onErrorContainer),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
