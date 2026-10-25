import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/domain/expense_validation.dart';

/// Shown under the category picker when Save is pressed with none chosen.
const String chooseCategoryMessage = 'Choose a category.';

/// What the expense form holds, exactly as entered.
final class ExpenseFormValues {
  const ExpenseFormValues({
    required this.amountText,
    required this.categoryId,
    required this.date,
    required this.noteText,
  });

  final String amountText;
  final int? categoryId;
  final LocalDate date;
  final String noteText;

  /// Whether saving now would store something different from [initial].
  ///
  /// Compares what would be saved, not the raw text: "12.5" and "12.50" are
  /// the same amount, and spaces around a note are trimmed on save, so
  /// neither alone asks to discard.
  bool differsFrom(ExpenseFormValues initial) =>
      !_sameAmount(amountText, initial.amountText) ||
      categoryId != initial.categoryId ||
      date != initial.date ||
      normalizeNote(noteText) != normalizeNote(initial.noteText);

  static bool _sameAmount(String a, String b) {
    final parsedA = parsePesewas(a);
    final parsedB = parsePesewas(b);
    if (parsedA is ValidAmount && parsedB is ValidAmount) {
      return parsedA == parsedB;
    }
    return a.trim() == b.trim();
  }
}

/// The message to show under each field; null where the field is fine.
final class ExpenseFormErrors {
  const ExpenseFormErrors({this.amount, this.category, this.date, this.note});

  final String? amount;
  final String? category;
  final String? date;
  final String? note;

  bool get isEmpty =>
      amount == null && category == null && date == null && note == null;
}

/// The outcome of [validateExpenseForm].
sealed class ExpenseFormResult {
  const ExpenseFormResult();
}

final class ValidExpenseForm extends ExpenseFormResult {
  const ValidExpenseForm(this.draft);

  /// Ready for the repository: amount parsed, note trimmed or null.
  final ExpenseDraft draft;
}

final class InvalidExpenseForm extends ExpenseFormResult {
  const InvalidExpenseForm(this.errors);

  final ExpenseFormErrors errors;
}

/// Checks every field at once against the rules the repository enforces
/// (DESIGN_SPEC §5), so the form can show all its messages together.
ExpenseFormResult validateExpenseForm(
  ExpenseFormValues values, {
  required LocalDate today,
}) {
  final amount = parsePesewas(values.amountText);
  final categoryId = values.categoryId;
  final note = normalizeNote(values.noteText);
  final dateInRange =
      values.date.compareTo(earliestExpenseDate) >= 0 &&
      values.date.compareTo(today) <= 0;

  final errors = ExpenseFormErrors(
    amount: switch (amount) {
      InvalidAmount(:final error) => error.message,
      ValidAmount() => null,
    },
    category: categoryId == null ? chooseCategoryMessage : null,
    date: dateInRange ? null : const InvalidDateError().message,
    note: note != null && note.runes.length > maxNoteLength
        ? const NoteTooLongError().message
        : null,
  );

  if (amount is ValidAmount && categoryId != null && errors.isEmpty) {
    return ValidExpenseForm(
      ExpenseDraft(
        amountPesewas: amount.pesewas,
        categoryId: categoryId,
        occurredOn: values.date,
        note: note,
      ),
    );
  }
  return InvalidExpenseForm(errors);
}
