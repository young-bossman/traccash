import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/data/database/database_provider.dart';
import 'package:traccash/data/database/simulated_failure.dart';
import 'package:traccash/features/categories/data/category_repository.dart';
import 'package:traccash/features/categories/data/drift_category_repository.dart';
import 'package:traccash/features/expenses/data/drift_expense_repository.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/settings/data/drift_settings_repository.dart';
import 'package:traccash/features/settings/data/settings_repository.dart';

import 'data_test_helpers.dart';

/// Settings' "Fail the next save", without Riverpod: armed until one write
/// takes it.
class _Switch {
  bool armed = false;

  bool take() {
    if (!armed) return false;
    armed = false;
    return true;
  }
}

Matcher get _throwsStorageError => throwsA(isA<StorageError>());

void main() {
  late AppDatabase db;
  late _Switch failure;
  late DriftExpenseRepository expenses;
  late DriftCategoryRepository categories;
  late DriftSettingsRepository settings;

  setUp(() {
    db = openTestDatabase();
    failure = _Switch();
    expenses = DriftExpenseRepository(
      db,
      today: () => testToday,
      clock: steppingClock(),
      simulatedFailure: failure.take,
    );
    categories = DriftCategoryRepository(
      db,
      clock: steppingClock(),
      simulatedFailure: failure.take,
    );
    settings = DriftSettingsRepository(db, simulatedFailure: failure.take);
  });

  tearDown(() => db.close());

  Future<int> expenseCount() async =>
      (await expenses.watchRecent(limit: 100).first).length;

  group('each Drift write throws StorageError once, writes nothing, and the '
      'next write succeeds', () {
    test('ExpenseRepository.add', () async {
      failure.armed = true;
      await expectLater(expenses.add(draft()), _throwsStorageError);
      expect(failure.armed, isFalse);
      expect(await expenseCount(), 0);

      await expenses.add(draft());
      expect(await expenseCount(), 1);
    });

    test('ExpenseRepository.update', () async {
      final added = await expenses.add(draft(amountPesewas: 1000));

      failure.armed = true;
      await expectLater(
        expenses.update(added.id, draft(amountPesewas: 2000)),
        _throwsStorageError,
      );
      expect((await expenses.getById(added.id))!.amountPesewas, 1000);

      await expenses.update(added.id, draft(amountPesewas: 2000));
      expect((await expenses.getById(added.id))!.amountPesewas, 2000);
    });

    test('ExpenseRepository.delete', () async {
      final added = await expenses.add(draft());

      failure.armed = true;
      await expectLater(expenses.delete(added.id), _throwsStorageError);
      expect(await expenses.getById(added.id), isNotNull);

      await expenses.delete(added.id);
      expect(await expenses.getById(added.id), isNull);
    });

    test('ExpenseRepository.restore', () async {
      final deleted = await expenses.delete((await expenses.add(draft())).id);

      failure.armed = true;
      await expectLater(expenses.restore(deleted), _throwsStorageError);
      expect(await expenses.getById(deleted.id), isNull);

      await expenses.restore(deleted);
      expect(await expenses.getById(deleted.id), deleted);
    });

    test('ExpenseRepository.clearAll', () async {
      final custom = await categories.create('School fees', 'education');
      await expenses.add(draft(categoryId: custom.id));

      failure.armed = true;
      await expectLater(expenses.clearAll(), _throwsStorageError);
      expect(await expenseCount(), 1);
      expect(await categories.watchAll().first, hasLength(9));

      await expenses.clearAll();
      expect(await expenseCount(), 0);
      expect(await categories.watchAll().first, hasLength(8));
    });

    test('CategoryRepository.create', () async {
      failure.armed = true;
      await expectLater(
        categories.create('School fees', 'education'),
        _throwsStorageError,
      );
      expect(await categories.watchAll().first, hasLength(8));

      await categories.create('School fees', 'education');
      expect(await categories.watchAll().first, hasLength(9));
    });

    test('CategoryRepository.archive', () async {
      failure.armed = true;
      await expectLater(categories.archive(foodId), _throwsStorageError);
      expect(await categories.watchActive().first, hasLength(8));

      await categories.archive(foodId);
      expect(await categories.watchActive().first, hasLength(7));
    });

    test('SettingsRepository.setThemeMode', () async {
      failure.armed = true;
      await expectLater(
        settings.setThemeMode(ThemeMode.dark),
        _throwsStorageError,
      );
      expect(await settings.watchThemeMode().first, ThemeMode.system);

      await settings.setThemeMode(ThemeMode.dark);
      expect(await settings.watchThemeMode().first, ThemeMode.dark);
    });
  });

  test('validation still comes first and leaves the failure armed', () async {
    failure.armed = true;

    await expectLater(
      expenses.add(draft(amountPesewas: 0)),
      throwsA(
        isA<InvalidAmountError>().having(
          (e) => e.reason,
          'reason',
          AmountError.zero,
        ),
      ),
    );
    expect(failure.armed, isTrue);
  });

  test('reads are never failed', () async {
    failure.armed = true;

    expect(await expenses.watchRecent().first, isEmpty);
    expect(await expenses.firstExpenseDate(), isNull);
    expect(await categories.watchAll().first, hasLength(8));
    expect(await settings.watchThemeMode().first, ThemeMode.system);
    expect(failure.armed, isTrue);
  });

  group('through the app providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    void arm() =>
        container.read(failNextWriteProvider.notifier).set(armed: true);

    test('each repository provider fails the next write once and turns the '
        'switch off', () async {
      final writes = <String, Future<Object?> Function()>{
        'expenses': () =>
            container.read(expenseRepositoryProvider).add(draft()),
        'categories': () => container
            .read(categoryRepositoryProvider)
            .create('School fees', 'education'),
        'settings': () => container
            .read(settingsRepositoryProvider)
            .setThemeMode(ThemeMode.dark),
      };

      for (final MapEntry(key: name, value: write) in writes.entries) {
        arm();
        await expectLater(write(), _throwsStorageError, reason: name);
        expect(container.read(failNextWriteProvider), isFalse, reason: name);
        await expectLater(write(), completes, reason: name);
      }
    });

    test('the switch starts off', () {
      expect(container.read(failNextWriteProvider), isFalse);
    });

    test('take() is true once per arming', () {
      final notifier = container.read(failNextWriteProvider.notifier);

      expect(notifier.take(), isFalse);
      notifier.set(armed: true);
      expect(notifier.take(), isTrue);
      expect(notifier.take(), isFalse);
    });

    test('release builds get no hook; debug builds get the switch', () {
      final release = Provider(
        (ref) => simulatedFailureHook(ref, debug: false),
      );
      final debug = Provider((ref) => simulatedFailureHook(ref, debug: true));

      expect(container.read(release), isNull);
      final hook = container.read(debug)!;
      arm();
      expect(hook(), isTrue);
      expect(container.read(failNextWriteProvider), isFalse);
    });
  });
}
