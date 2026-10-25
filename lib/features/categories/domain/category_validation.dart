import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/features/categories/domain/category.dart';

/// Counted in code points, the same unit as SQLite's `length()`, so this rule
/// and the table's CHECK agree on every name.
const int maxCategoryNameLength = 20;

final RegExp _whitespaceRun = RegExp(r'\s+');

/// Trims and collapses inner whitespace, so "  School   fees " and
/// "School fees" are the same name.
String normalizeCategoryName(String input) =>
    input.trim().replaceAll(_whitespaceRun, ' ');

/// The rules for a new category. [name] must already be normalized.
///
/// Shared by the Drift repository and the test fakes, so widget tests run
/// against the same rules as the real app.
AppError? validateNewCategory(String name, String iconKey) {
  if (name.isEmpty) return const CategoryNameError(CategoryNameProblem.empty);
  if (name.runes.length > maxCategoryNameLength) {
    return const CategoryNameError(CategoryNameProblem.tooLong);
  }
  if (!userIconKeys.contains(iconKey)) return const InvalidCategoryIconError();
  return null;
}

/// The category whose name matches [name] ignoring case, if any.
///
/// SQLite's NOCASE only folds ASCII letters; this check also catches
/// "École" against "école". The database constraint stays as the backstop.
Category? findCategoryNamed(String name, Iterable<Category> categories) {
  final wanted = name.toLowerCase();
  for (final category in categories) {
    if (category.name.toLowerCase() == wanted) return category;
  }
  return null;
}
