import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/features/expenses/data/drift_expense_repository.dart';
import 'package:traccash/features/settings/data/drift_settings_repository.dart';

import 'data_test_helpers.dart';

void main() {
  late AppDatabase db;
  late DriftExpenseRepository repo;

  setUp(() {
    db = openTestDatabase();
    repo = expenseRepo(db);
  });

  tearDown(() => db.close());

  group('add, update, delete, restore', () {
    test('add stores a valid expense and returns it', () async {
      final added = await repo.add(draft(amountPesewas: 3500, note: 'Waakye'));

      expect(added.amountPesewas, 3500);
      expect(added.category.name, 'Food');
      expect(added.occurredOn, testToday);
      expect(added.note, 'Waakye');
      expect(await repo.getById(added.id), added);
    });

    test('add trims the note and stores blank notes as null', () async {
      final trimmed = await repo.add(draft(note: '  Trotro  '));
      final blank = await repo.add(draft(note: '   '));

      expect((await repo.getById(trimmed.id))!.note, 'Trotro');
      expect((await repo.getById(blank.id))!.note, isNull);
    });

    test('createdAt and updatedAt are read back as UTC', () async {
      final added = await repo.add(draft());
      final read = (await repo.getById(added.id))!;

      expect(read.createdAt.isUtc, isTrue);
      expect(read.updatedAt.isUtc, isTrue);
    });

    test(
      'update replaces the fields, changes updatedAt, keeps createdAt',
      () async {
        final added = await repo.add(draft(amountPesewas: 1000, note: 'Old'));

        final updated = await repo.update(
          added.id,
          draft(
            amountPesewas: 2000,
            categoryId: transportId,
            on: testToday.addDays(-1),
          ),
        );
        final read = (await repo.getById(added.id))!;

        expect(read, updated);
        expect(read.id, added.id);
        expect(read.amountPesewas, 2000, reason: 'replaced, never added to');
        expect(read.category.name, 'Transport');
        expect(read.occurredOn, testToday.addDays(-1));
        expect(read.note, isNull);
        expect(read.createdAt, added.createdAt);
        expect(read.updatedAt.isAfter(added.updatedAt), isTrue);
        expect(read.createdAt.isUtc && read.updatedAt.isUtc, isTrue);
      },
    );

    test('delete removes the expense and returns it', () async {
      final added = await repo.add(draft());

      final deleted = await repo.delete(added.id);

      expect(deleted, added);
      expect(await repo.getById(added.id), isNull);
    });

    test('restore brings back the same id, timestamps and fields', () async {
      final keep = await repo.add(draft(amountPesewas: 500));
      final added = await repo.add(draft(amountPesewas: 900, note: 'Lunch'));
      final deleted = await repo.delete(added.id);

      await repo.restore(deleted);

      final restored = await repo.getById(added.id);
      expect(restored, added);
      expect(ids(await repo.watchRecent().first), [added.id, keep.id]);
    });

    test('restore twice does nothing the second time', () async {
      final deleted = await repo.delete((await repo.add(draft())).id);

      await repo.restore(deleted);
      await repo.restore(deleted);

      expect(await repo.watchRecent().first, hasLength(1));
    });

    test(
      'a new expense after deleting the newest gets a different id',
      () async {
        await repo.add(draft());
        final newest = await repo.add(draft());
        await repo.delete(newest.id);

        final next = await repo.add(draft());

        expect(next.id, isNot(newest.id));
        expect(next.id, greaterThan(newest.id));
      },
    );

    test('update of a missing id throws ExpenseNotFoundError', () async {
      await expectLater(
        repo.update(999, draft()),
        throwsA(isA<ExpenseNotFoundError>()),
      );
    });

    test('delete of a missing id throws ExpenseNotFoundError', () async {
      await expectLater(repo.delete(999), throwsA(isA<ExpenseNotFoundError>()));
    });
  });

  group('validation at the repository', () {
    Matcher amountError(AmountError reason) => throwsA(
      isA<InvalidAmountError>().having((e) => e.reason, 'reason', reason),
    );

    test('rejects amounts of 0 and over 100,000,000 pesewas', () async {
      await expectLater(
        repo.add(draft(amountPesewas: 0)),
        amountError(AmountError.zero),
      );
      await expectLater(
        repo.add(draft(amountPesewas: -5)),
        amountError(AmountError.zero),
      );
      await expectLater(
        repo.add(draft(amountPesewas: 100000001)),
        amountError(AmountError.overMax),
      );
      expect(await repo.watchRecent().first, isEmpty);
    });

    test('accepts the limits 1 and 100,000,000 pesewas', () async {
      await repo.add(draft(amountPesewas: 1));
      await repo.add(draft(amountPesewas: 100000000));

      expect(await repo.watchRecent().first, hasLength(2));
    });

    test('rejects a note over 200 characters', () async {
      await expectLater(
        repo.add(draft(note: 'a' * 201)),
        throwsA(isA<NoteTooLongError>()),
      );
    });

    test('counts the note in code points, as SQLite does', () async {
      // Each emoji is 2 UTF-16 units in Dart but 1 character to SQLite.
      final added = await repo.add(draft(note: '🙂' * 200));

      expect((await repo.getById(added.id))!.note, '🙂' * 200);
      await expectLater(
        repo.add(draft(note: '🙂' * 201)),
        throwsA(isA<NoteTooLongError>()),
      );
    });

    test('rejects a future date and a date before 2000', () async {
      await expectLater(
        repo.add(draft(on: testToday.addDays(1))),
        throwsA(isA<InvalidDateError>()),
      );
      await expectLater(
        repo.add(draft(on: LocalDate(1999, 12, 31))),
        throwsA(isA<InvalidDateError>()),
      );
      await repo.add(draft(on: LocalDate(2000, 1, 1)));
    });

    test('rejects a missing or archived category', () async {
      await expectLater(
        repo.add(draft(categoryId: 999)),
        throwsA(isA<CategoryUnavailableError>()),
      );
      await categoryRepo(db).archive(transportId);
      await expectLater(
        repo.add(draft(categoryId: transportId)),
        throwsA(isA<CategoryUnavailableError>()),
      );
    });

    test('an edit may keep an archived category but not move to one', () async {
      final onTransport = await repo.add(draft(categoryId: transportId));
      final onFood = await repo.add(draft());
      await categoryRepo(db).archive(transportId);

      final edited = await repo.update(
        onTransport.id,
        draft(categoryId: transportId, note: 'Fixed note'),
      );
      expect(edited.note, 'Fixed note');

      await expectLater(
        repo.update(onFood.id, draft(categoryId: transportId)),
        throwsA(isA<CategoryUnavailableError>()),
      );
    });
  });

  group('watchMonth', () {
    test(
      'returns only that month and excludes the 1st of the next month',
      () async {
        final lastOfSep = await repo.add(draft(on: LocalDate(2026, 9, 30)));
        final firstOfOct = await repo.add(draft(on: LocalDate(2026, 10, 1)));
        final midOct = await repo.add(draft(on: LocalDate(2026, 10, 15)));
        await repo.add(draft(on: LocalDate(2026, 8, 31)));

        final september = await repo
            .watchMonth(const CalendarMonth(2026, 9))
            .first;
        final october = await repo
            .watchMonth(const CalendarMonth(2026, 10))
            .first;

        expect(ids(september), [lastOfSep.id]);
        expect(ids(october), [
          midOct.id,
          firstOfOct.id,
        ], reason: 'newest first');
      },
    );

    test('works across the December to January year boundary', () async {
      final dec1 = await repo.add(draft(on: LocalDate(2025, 12, 1)));
      final dec31 = await repo.add(draft(on: LocalDate(2025, 12, 31)));
      final jan1 = await repo.add(draft(on: LocalDate(2026, 1, 1)));
      final jan31 = await repo.add(draft(on: LocalDate(2026, 1, 31)));
      await repo.add(draft(on: LocalDate(2025, 11, 30)));
      await repo.add(draft(on: LocalDate(2026, 2, 1)));

      final december = await repo
          .watchMonth(const CalendarMonth(2025, 12))
          .first;
      final january = await repo.watchMonth(const CalendarMonth(2026, 1)).first;

      expect(ids(december), [dec31.id, dec1.id]);
      expect(ids(january), [jan31.id, jan1.id]);
    });

    test(
      'an edit that moves an expense to another month updates both',
      () async {
        final expense = await repo.add(draft(on: LocalDate(2026, 10, 10)));
        final october = StreamIterator(
          repo.watchMonth(const CalendarMonth(2026, 10)),
        );
        final september = StreamIterator(
          repo.watchMonth(const CalendarMonth(2026, 9)),
        );
        expect(ids(await nextValue(october)), [expense.id]);
        expect(await nextValue(september), isEmpty);

        await repo.update(expense.id, draft(on: LocalDate(2026, 9, 20)));

        expect(await nextValue(october), isEmpty);
        final moved = await nextValue(september);
        expect(ids(moved), [expense.id]);
        expect(moved.single.occurredOn, LocalDate(2026, 9, 20));

        await october.cancel();
        await september.cancel();
      },
    );

    test('deleting the last expense of a month emits an empty list', () async {
      final only = await repo.add(draft(on: LocalDate(2026, 10, 3)));
      final october = StreamIterator(
        repo.watchMonth(const CalendarMonth(2026, 10)),
      );
      expect(ids(await nextValue(october)), [only.id]);

      await repo.delete(only.id);

      expect(await nextValue(october), isEmpty);
      await october.cancel();
    });
  });

  group('watchRecent', () {
    test('is newest first by date, then by entry time, and limited', () async {
      final older = await repo.add(draft(on: testToday.addDays(-3)));
      final todayFirst = await repo.add(draft());
      final todaySecond = await repo.add(draft());

      expect(ids(await repo.watchRecent(limit: 10).first), [
        todaySecond.id,
        todayFirst.id,
        older.id,
      ]);
      expect(ids(await repo.watchRecent(limit: 2).first), [
        todaySecond.id,
        todayFirst.id,
      ]);
    });
  });

  group('watchBetween', () {
    test('includes both end dates', () async {
      await repo.add(draft(on: LocalDate(2026, 5, 31)));
      final from = await repo.add(draft(on: LocalDate(2026, 6, 1)));
      final middle = await repo.add(draft(on: LocalDate(2026, 7, 15)));
      final to = await repo.add(draft(on: LocalDate(2026, 8, 31)));
      await repo.add(draft(on: LocalDate(2026, 9, 1)));

      final result = await repo
          .watchBetween(LocalDate(2026, 6, 1), LocalDate(2026, 8, 31))
          .first;

      expect(ids(result), [to.id, middle.id, from.id]);
    });

    test('from == to returns that day only', () async {
      await repo.add(draft(on: LocalDate(2026, 6, 14)));
      final a = await repo.add(draft(on: LocalDate(2026, 6, 15)));
      final b = await repo.add(draft(on: LocalDate(2026, 6, 15)));
      await repo.add(draft(on: LocalDate(2026, 6, 16)));

      final day = LocalDate(2026, 6, 15);
      expect(ids(await repo.watchBetween(day, day).first), [b.id, a.id]);
    });

    test('spans a year boundary', () async {
      await repo.add(draft(on: LocalDate(2025, 10, 31)));
      final nov = await repo.add(draft(on: LocalDate(2025, 11, 1)));
      final dec = await repo.add(draft(on: LocalDate(2025, 12, 31)));
      final jan = await repo.add(draft(on: LocalDate(2026, 1, 1)));
      final apr = await repo.add(draft(on: LocalDate(2026, 4, 30)));
      await repo.add(draft(on: LocalDate(2026, 5, 1)));

      final result = await repo
          .watchBetween(LocalDate(2025, 11, 1), LocalDate(2026, 4, 30))
          .first;

      expect(ids(result), [apr.id, jan.id, dec.id, nov.id]);
    });

    test('rejects from after to', () {
      expect(
        () => repo.watchBetween(LocalDate(2026, 2, 1), LocalDate(2026, 1, 1)),
        throwsArgumentError,
      );
    });
  });

  group('firstExpenseDate', () {
    test('is null on an empty database', () async {
      expect(await repo.firstExpenseDate(), isNull);
    });

    test('is the earliest date on a populated database', () async {
      await repo.add(draft(on: LocalDate(2026, 3, 9)));
      await repo.add(draft(on: LocalDate(2025, 12, 30)));
      await repo.add(draft(on: LocalDate(2026, 10, 1)));

      expect(await repo.firstExpenseDate(), LocalDate(2025, 12, 30));
    });
  });

  group('clearAll', () {
    test('removes all expenses and user categories, keeps the 8 presets '
        'and the theme setting', () async {
      final categories = categoryRepo(db);
      final settings = DriftSettingsRepository(db);
      final schoolFees = await categories.create('School fees', 'education');
      await repo.add(draft());
      await repo.add(draft(categoryId: schoolFees.id));
      await settings.setThemeMode(ThemeMode.dark);

      await repo.clearAll();

      expect(await repo.watchRecent().first, isEmpty);
      final remaining = await categories.watchAll().first;
      expect(remaining, hasLength(8));
      expect(remaining.every((c) => c.isPreset), isTrue);
      expect(
        [for (final c in remaining) c.name],
        [
          'Food',
          'Transport',
          'Bills',
          'Data & Airtime',
          'Shopping',
          'Health',
          'Entertainment',
          'Other',
        ],
      );
      expect(await settings.watchThemeMode().first, ThemeMode.dark);
    });
  });

  test('restore fails cleanly when its category was cleared', () async {
    final categories = categoryRepo(db);
    final gifts = await categories.create('Gifts', 'gifts');
    final deleted = await repo.delete(
      (await repo.add(draft(categoryId: gifts.id))).id,
    );
    await repo.clearAll();

    await expectLater(
      repo.restore(deleted),
      throwsA(isA<CategoryUnavailableError>()),
    );
  });

  test('Expense.toString leaves out amount and note', () async {
    final added = await repo.add(draft(amountPesewas: 4321, note: 'Secret'));

    expect(added.toString(), isNot(contains('4321')));
    expect(added.toString(), isNot(contains('Secret')));
  });

  test('ExpenseDraft value equality', () {
    expect(draft(note: 'x'), draft(note: 'x'));
    expect(draft(note: 'x').copyWith(note: () => null), draft());
    expect(draft().hashCode, draft().hashCode);
    expect(draft(), isNot(draft(amountPesewas: 1)));
  });
}
