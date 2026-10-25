import 'package:traccash/core/errors/amount_error.dart';

/// A failure the app expects and can explain to the user.
///
/// Repositories throw only these, never raw database exceptions, so
/// controllers can map each case to a message without knowing about SQLite.
sealed class AppError implements Exception {
  const AppError();

  /// User-facing text. Never contains record contents or database details.
  String get message;
}

final class InvalidAmountError extends AppError {
  const InvalidAmountError(this.reason);

  final AmountError reason;

  @override
  String get message => reason.message;
}

final class InvalidDateError extends AppError {
  const InvalidDateError();

  @override
  String get message => 'Choose a date from 1 January 2000 to today.';
}

final class NoteTooLongError extends AppError {
  const NoteTooLongError();

  @override
  String get message => 'Keep the note to 200 characters or fewer.';
}

enum CategoryNameProblem { empty, tooLong }

final class CategoryNameError extends AppError {
  const CategoryNameError(this.problem);

  final CategoryNameProblem problem;

  @override
  String get message => switch (problem) {
    CategoryNameProblem.empty => 'Enter a category name.',
    CategoryNameProblem.tooLong => 'Keep the name to 20 characters or fewer.',
  };
}

final class InvalidCategoryIconError extends AppError {
  const InvalidCategoryIconError();

  @override
  String get message => 'Choose one of the icons shown.';
}

final class DuplicateCategoryError extends AppError {
  const DuplicateCategoryError(this.existingName);

  /// The stored spelling, so the message names what the user will see above.
  final String existingName;

  @override
  String get message => '“$existingName” already exists. Choose it above.';
}

/// The category is missing or archived, so it can't be given to an expense.
final class CategoryUnavailableError extends AppError {
  const CategoryUnavailableError();

  @override
  String get message => 'That category is no longer available. Choose another.';
}

final class CategoryNotFoundError extends AppError {
  const CategoryNotFoundError();

  @override
  String get message => 'That category no longer exists.';
}

/// The expense was deleted elsewhere (or never existed).
final class ExpenseNotFoundError extends AppError {
  const ExpenseNotFoundError();

  @override
  String get message => 'This expense no longer exists.';
}

/// Any other storage failure: disk full, constraint the repository did not
/// anticipate, corrupted row. Details stay out of the message on purpose.
final class StorageError extends AppError {
  const StorageError();

  @override
  String get message => 'Couldn’t read or save on this device. Try again.';
}
