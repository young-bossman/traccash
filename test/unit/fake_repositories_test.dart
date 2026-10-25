import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_expense_repository.dart';

// The fakes must fail the same way as the Drift repositories, or widget tests
// would pass against looser rules than the app enforces.
void main() {
  final today = LocalDate(2026, 10, 25);
  late FakeCategoryRepository categories;
  late FakeExpenseRepository expenses;

  setUp(() {
    categories = FakeCategoryRepository();
    expenses = FakeExpenseRepository(categories, today: () => today);
  });

  tearDown(() async {
    await expenses.dispose();
    await categories.dispose();
  });

  ExpenseDraft draft({int amount = 1250, int categoryId = 1, String? note}) =>
      ExpenseDraft(
        amountPesewas: amount,
        categoryId: categoryId,
        occurredOn: today,
        note: note,
      );

  test('expense rules match the repository', () async {
    await expectLater(
      expenses.add(draft(amount: 0)),
      throwsA(
        isA<InvalidAmountError>().having(
          (e) => e.reason,
          'reason',
          AmountError.zero,
        ),
      ),
    );
    await expectLater(
      expenses.add(draft(note: 'a' * 201)),
      throwsA(isA<NoteTooLongError>()),
    );
    await expectLater(
      expenses.add(draft(categoryId: 999)),
      throwsA(isA<CategoryUnavailableError>()),
    );
    await categories.archive(2);
    await expectLater(
      expenses.add(draft(categoryId: 2)),
      throwsA(isA<CategoryUnavailableError>()),
    );
    await expectLater(
      expenses.update(999, draft()),
      throwsA(isA<ExpenseNotFoundError>()),
    );
    await expectLater(
      expenses.delete(999),
      throwsA(isA<ExpenseNotFoundError>()),
    );
  });

  test('category rules match the repository', () async {
    await categories.create('School fees', 'education');

    await expectLater(
      categories.create('school FEES', 'tag'),
      throwsA(
        isA<DuplicateCategoryError>().having(
          (e) => e.existingName,
          'existingName',
          'School fees',
        ),
      ),
    );
    await expectLater(
      categories.create('  ', 'tag'),
      throwsA(isA<CategoryNameError>()),
    );
  });

  test('restore keeps the id; new ids never reuse a deleted one', () async {
    final first = await expenses.add(draft(note: '  Lunch '));
    expect(first.note, 'Lunch');
    final deleted = await expenses.delete(first.id);

    final next = await expenses.add(draft());
    await expenses.restore(deleted);

    expect(next.id, isNot(first.id));
    expect(await expenses.getById(first.id), first);
  });

  test('failNextWrite fails one write with StorageError', () async {
    expenses.failNextWrite = true;

    await expectLater(expenses.add(draft()), throwsA(isA<StorageError>()));
    await expenses.add(draft());
    expect(await expenses.watchRecent().first, hasLength(1));
  });

  test('clearAll keeps the presets', () async {
    final gifts = await categories.create('Gifts', 'gifts');
    await expenses.add(draft(categoryId: gifts.id));

    await expenses.clearAll();

    expect(await expenses.watchRecent().first, isEmpty);
    expect(await categories.watchAll().first, hasLength(8));
  });
}
