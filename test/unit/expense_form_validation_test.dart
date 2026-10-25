import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';
import 'package:traccash/features/expenses/presentation/expense_form_validation.dart';

final LocalDate today = LocalDate(2026, 10, 21);

ExpenseFormValues values({
  String amount = '45',
  int? categoryId = 1,
  LocalDate? date,
  String note = '',
}) => ExpenseFormValues(
  amountText: amount,
  categoryId: categoryId,
  date: date ?? today,
  noteText: note,
);

ExpenseFormErrors errorsFor(ExpenseFormValues values) =>
    switch (validateExpenseForm(values, today: today)) {
      InvalidExpenseForm(:final errors) => errors,
      ValidExpenseForm() => const ExpenseFormErrors(),
    };

void main() {
  group('validateExpenseForm', () {
    test('valid input becomes a draft in pesewas with a trimmed note', () {
      final result = validateExpenseForm(
        values(amount: ' 1,000.50 ', note: '  Lunch at the office  '),
        today: today,
      );
      expect(result, isA<ValidExpenseForm>());
      expect(
        (result as ValidExpenseForm).draft,
        ExpenseDraft(
          amountPesewas: 100050,
          categoryId: 1,
          occurredOn: today,
          note: 'Lunch at the office',
        ),
      );
    });

    test('a blank note is saved as null', () {
      final result = validateExpenseForm(values(note: '   '), today: today);
      expect((result as ValidExpenseForm).draft.note, isNull);
    });

    test('reports every failing field at once', () {
      final errors = errorsFor(values(amount: '', categoryId: null));
      expect(errors.amount, 'Enter an amount.');
      expect(errors.category, 'Choose a category.');
      expect(errors.date, isNull);
      expect(errors.note, isNull);
    });

    test('amount messages come from the parser', () {
      const cases = {
        '0': AmountError.zero,
        '0.00': AmountError.zero,
        '12,50': AmountError.misplacedComma,
        '1000000.01': AmountError.overMax,
        '1.234': AmountError.tooManyDecimals,
        '12.': AmountError.invalidFormat,
      };
      for (final MapEntry(key: input, value: error) in cases.entries) {
        expect(errorsFor(values(amount: input)).amount, error.message);
      }
    });

    test('accepts 1 January 2000 and today, nothing outside', () {
      expect(errorsFor(values(date: LocalDate(2000, 1, 1))).isEmpty, isTrue);
      expect(errorsFor(values(date: today)).isEmpty, isTrue);

      const message = 'Choose a date from 1 January 2000 to today.';
      expect(errorsFor(values(date: today.addDays(1))).date, message);
      expect(errorsFor(values(date: LocalDate(1999, 12, 31))).date, message);
    });

    test('a note over 200 code points is rejected', () {
      expect(errorsFor(values(note: 'a' * 200)).isEmpty, isTrue);
      expect(
        errorsFor(values(note: 'a' * 201)).note,
        const NoteTooLongError().message,
      );
    });
  });

  group('differsFrom', () {
    final initial = values(amount: '12.50', note: 'Lunch');

    test('the same values do not differ', () {
      expect(
        values(amount: '12.50', note: 'Lunch').differsFrom(initial),
        false,
      );
    });

    test('the same amount written differently does not differ', () {
      expect(values(amount: '12.5', note: 'Lunch').differsFrom(initial), false);
      expect(
        values(amount: '1,000').differsFrom(values(amount: '1000')),
        isFalse,
      );
    });

    test('spaces around the note do not differ', () {
      expect(
        values(amount: '12.50', note: '  Lunch ').differsFrom(initial),
        isFalse,
      );
    });

    test('a change to any field differs', () {
      expect(values(amount: '13', note: 'Lunch').differsFrom(initial), true);
      expect(
        values(
          amount: '12.50',
          note: 'Lunch',
          categoryId: 2,
        ).differsFrom(initial),
        isTrue,
      );
      expect(
        values(
          amount: '12.50',
          note: 'Lunch',
          date: today.addDays(-1),
        ).differsFrom(initial),
        isTrue,
      );
      expect(
        values(amount: '12.50', note: 'Dinner').differsFrom(initial),
        true,
      );
    });

    test('invalid amounts compare as text', () {
      final empty = values(amount: '');
      expect(values(amount: '0').differsFrom(empty), isTrue);
      expect(values(amount: '  ').differsFrom(empty), isFalse);
      expect(
        values(amount: '12,50').differsFrom(values(amount: '12,50')),
        false,
      );
    });
  });
}
