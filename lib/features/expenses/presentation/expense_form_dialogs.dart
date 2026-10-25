import 'dart:async';

import 'package:flutter/material.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

/// How long a snackbar with Undo or View stays up (DESIGN_SPEC §7).
const Duration snackBarActionWindow = Duration(seconds: 5);

/// Asks before throwing away unsaved input. True means discard.
Future<bool> confirmDiscard(
  BuildContext context, {
  required bool editing,
}) async {
  final discard = await showDialog<bool>(
    context: context,
    animationStyle: _dialogAnimation(context),
    builder: (context) => AlertDialog(
      title: Text(editing ? 'Discard changes?' : 'Discard this expense?'),
      content: Text(
        editing
            ? 'Your edits to this expense won’t be saved.'
            : 'What you entered hasn’t been saved.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep editing'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  return discard ?? false;
}

/// Asks before deleting [expense], naming its stored amount, category and
/// date (not any unsaved edits in the form). True means delete.
Future<bool> confirmDelete(
  BuildContext context,
  Expense expense, {
  required LocalDate today,
}) async {
  final amount = formatGhs(expense.amountPesewas);
  final date = formatDayAndMonth(expense.occurredOn, today: today);
  final delete = await showDialog<bool>(
    context: context,
    animationStyle: _dialogAnimation(context),
    builder: (context) => AlertDialog(
      title: const Text('Delete this expense?'),
      content: Text(
        '$amount for ${expense.category.name} on $date will be removed from '
        'your records.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return delete ?? false;
}

AnimationStyle? _dialogAnimation(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ? AnimationStyle.noAnimation : null;

// The snackbars below are shown after the form has closed, so they take the
// messenger, repository and callbacks captured beforehand and never touch
// the form's context or ref.

// Snackbars with an action (Undo, View) time out after
// [snackBarActionWindow], except with a screen reader (TalkBack), when
// [screenReader] keeps them up until dismissed or actioned: 5 s may not be
// enough to reach the action. Flutter's own default for an action snackbar
// is to stay up always, so `persist` is set either way.

/// "Expense saved" / "Changes saved", or "… saved to September 2026" with
/// View when the expense landed outside the month on screen.
void showSavedSnackBar(
  ScaffoldMessengerState messenger, {
  required bool editing,
  required CalendarMonth? otherMonth,
  required VoidCallback onView,
  required bool reduceMotion,
  required bool screenReader,
}) {
  final saved = editing ? 'Changes saved' : 'Expense saved';
  _show(
    messenger,
    otherMonth == null
        ? SnackBar(content: Text(saved))
        : SnackBar(
            content: Text('$saved to ${otherMonth.label}'),
            duration: snackBarActionWindow,
            persist: screenReader,
            action: SnackBarAction(label: 'View', onPressed: onView),
          ),
    reduceMotion: reduceMotion,
  );
}

/// "Expense deleted" with Undo, which puts back the same record: same id
/// and creation time.
void showDeletedSnackBar(
  ScaffoldMessengerState messenger, {
  required ExpenseRepository repository,
  required Expense deleted,
  required bool reduceMotion,
  required bool screenReader,
}) {
  Future<void> undo() async {
    try {
      await repository.restore(deleted);
    } on AppError {
      _show(
        messenger,
        const SnackBar(content: Text('Couldn’t restore the expense.')),
        reduceMotion: reduceMotion,
      );
    }
  }

  _show(
    messenger,
    SnackBar(
      content: const Text('Expense deleted'),
      duration: snackBarActionWindow,
      persist: screenReader,
      action: SnackBarAction(label: 'Undo', onPressed: () => unawaited(undo())),
    ),
    reduceMotion: reduceMotion,
  );
}

/// Replaces whatever snackbar is showing, so feedback is about the latest
/// action.
void _show(
  ScaffoldMessengerState messenger,
  SnackBar snackBar, {
  required bool reduceMotion,
}) {
  if (!messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      snackBar,
      snackBarAnimationStyle: reduceMotion ? AnimationStyle.noAnimation : null,
    );
}
