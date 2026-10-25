import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

/// Counted in code points, the same unit as SQLite's `length()`. Dart's
/// `String.length` counts UTF-16 units and would disagree on emoji.
const int maxNoteLength = 200;

final LocalDate earliestExpenseDate = LocalDate(2000, 1, 1);

/// Trimmed note, or null when nothing but whitespace was entered.
String? normalizeNote(String? note) {
  final trimmed = note?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// The rules every stored expense must meet, apart from its category.
///
/// Shared by the Drift repository and the test fakes, so widget tests run
/// against the same rules as the real app. Pass the note already normalized.
AppError? validateExpenseDraft(ExpenseDraft draft, {required LocalDate today}) {
  if (draft.amountPesewas < 1) {
    return const InvalidAmountError(AmountError.zero);
  }
  if (draft.amountPesewas > maxPesewas) {
    return const InvalidAmountError(AmountError.overMax);
  }
  if (draft.occurredOn.compareTo(earliestExpenseDate) < 0 ||
      draft.occurredOn.compareTo(today) > 0) {
    return const InvalidDateError();
  }
  final note = draft.note;
  if (note != null && note.runes.length > maxNoteLength) {
    return const NoteTooLongError();
  }
  return null;
}

/// Whether [category] may be given to an expense.
///
/// [currentCategoryId] is the category the expense already has when editing:
/// an old expense may keep a category that was archived after it was saved,
/// but nothing may move to an archived one.
AppError? validateExpenseCategory(
  Category? category, {
  int? currentCategoryId,
}) {
  if (category == null) return const CategoryUnavailableError();
  if (category.isArchived && category.id != currentCategoryId) {
    return const CategoryUnavailableError();
  }
  return null;
}
