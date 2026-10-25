import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/categories/domain/category.dart';

/// A saved expense.
///
/// It carries its whole [category], so a label is available even after the
/// category is archived and hidden from the picker.
final class Expense {
  const Expense({
    required this.id,
    required this.amountPesewas,
    required this.category,
    required this.occurredOn,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int amountPesewas;
  final Category category;
  final LocalDate occurredOn;

  /// Trimmed; null when the user left it blank.
  final String? note;

  /// UTC.
  final DateTime createdAt;

  /// UTC.
  final DateTime updatedAt;

  /// The editable fields, ready to pass back to `update`.
  ExpenseDraft toDraft() => ExpenseDraft(
    amountPesewas: amountPesewas,
    categoryId: category.id,
    occurredOn: occurredOn,
    note: note,
  );

  Expense copyWith({
    int? id,
    int? amountPesewas,
    Category? category,
    LocalDate? occurredOn,
    String? Function()? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amountPesewas: amountPesewas ?? this.amountPesewas,
      category: category ?? this.category,
      occurredOn: occurredOn ?? this.occurredOn,
      // A function, so copyWith can set the note back to null.
      note: note == null ? this.note : note(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.amountPesewas == amountPesewas &&
      other.category == category &&
      other.occurredOn == occurredOn &&
      other.note == note &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    amountPesewas,
    category,
    occurredOn,
    note,
    createdAt,
    updatedAt,
  );

  // No amount or note: these strings can end up in test output and logs.
  @override
  String toString() => 'Expense($id, $occurredOn)';
}

/// The values the user enters for an expense, before it has an id.
final class ExpenseDraft {
  const ExpenseDraft({
    required this.amountPesewas,
    required this.categoryId,
    required this.occurredOn,
    this.note,
  });

  final int amountPesewas;
  final int categoryId;
  final LocalDate occurredOn;
  final String? note;

  ExpenseDraft copyWith({
    int? amountPesewas,
    int? categoryId,
    LocalDate? occurredOn,
    String? Function()? note,
  }) {
    return ExpenseDraft(
      amountPesewas: amountPesewas ?? this.amountPesewas,
      categoryId: categoryId ?? this.categoryId,
      occurredOn: occurredOn ?? this.occurredOn,
      note: note == null ? this.note : note(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExpenseDraft &&
      other.amountPesewas == amountPesewas &&
      other.categoryId == categoryId &&
      other.occurredOn == occurredOn &&
      other.note == note;

  @override
  int get hashCode => Object.hash(amountPesewas, categoryId, occurredOn, note);

  @override
  String toString() => 'ExpenseDraft($occurredOn)';
}
