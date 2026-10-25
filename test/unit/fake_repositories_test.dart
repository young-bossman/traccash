import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_expense_repository.dart';
import '../fakes/fake_settings_repository.dart';

/// Runs [operation] as a widget test body runs: in a zone whose microtasks
/// wait in a queue until flushed, as flutter_test's fake async zone does.
///
/// The result must be ready once that queue is flushed. Anything that needs
/// a real event-loop turn as well, such as a future that belongs to the root
/// zone, would leave a widget test awaiting it stuck for good, since the
/// binding only flushes the queue again on the next pump. The timeout turns
/// any other hang into a failure.
Future<T> _inFakeAsync<T>(String name, Future<T> Function() operation) {
  final microtasks = Queue<void Function()>();
  final zone = Zone.current.fork(
    specification: ZoneSpecification(
      scheduleMicrotask: (self, parent, zone, task) => microtasks.add(task),
    ),
  );
  // Taken over in this zone while the queue is flushed: listening to the
  // operation's own future afterwards would queue in the held zone again.
  final outcome = Completer<T>();
  unawaited(
    zone.run(operation).then(outcome.complete, onError: outcome.completeError),
  );
  while (microtasks.isNotEmpty) {
    microtasks.removeFirst()();
  }
  expect(
    outcome.isCompleted,
    isTrue,
    reason:
        '$name needed a real event-loop turn; a widget test awaiting it '
        'would never finish',
  );
  return outcome.future.timeout(
    const Duration(seconds: 2),
    onTimeout: () => throw TimeoutException('$name did not finish'),
  );
}

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

  group('watch streams finish inside a widget test’s fake async zone', () {
    late FakeSettingsRepository settings;

    setUp(() {
      settings = FakeSettingsRepository();
    });

    tearDown(() async {
      await settings.dispose();
    });

    Map<String, Stream<Object?> Function()> watchStreams() => {
      'expenses.watchMonth': () => expenses.watchMonth(CalendarMonth.of(today)),
      'expenses.watchRecent': expenses.watchRecent,
      'expenses.watchBetween': () => expenses.watchBetween(today, today),
      'categories.watchActive': categories.watchActive,
      'categories.watchAll': categories.watchAll,
      'settings.watchThemeMode': settings.watchThemeMode,
    };

    test('.first gives the current value', () async {
      await expenses.add(draft());

      for (final MapEntry(key: name, value: watch) in watchStreams().entries) {
        final value = await _inFakeAsync(name, () => watch().first);
        expect(value, isNotNull, reason: name);
      }
      expect(
        await _inFakeAsync('watchRecent', () => expenses.watchRecent().first),
        hasLength(1),
      );
      expect(
        await _inFakeAsync('watchActive', () => categories.watchActive().first),
        hasLength(8),
      );
      expect(
        await _inFakeAsync(
          'watchThemeMode',
          () => settings.watchThemeMode().first,
        ),
        ThemeMode.system,
      );
    });

    test('.take(n) gives the current value, then one per change', () async {
      final modes = await _inFakeAsync('settings.watchThemeMode', () async {
        final three = settings.watchThemeMode().take(3).toList();
        await settings.setThemeMode(ThemeMode.light);
        await settings.setThemeMode(ThemeMode.dark);
        return three;
      });
      expect(modes, [ThemeMode.system, ThemeMode.light, ThemeMode.dark]);

      final recent = await _inFakeAsync('expenses.watchRecent', () async {
        final two = expenses.watchRecent().take(2).toList();
        await expenses.add(draft());
        return two;
      });
      expect([for (final list in recent) list.length], [0, 1]);

      final active = await _inFakeAsync('categories.watchActive', () async {
        final two = categories.watchActive().take(2).toList();
        await categories.create('School fees', 'education');
        return two;
      });
      expect([for (final list in active) list.length], [8, 9]);
    });

    test('cancelling a subscription completes', () async {
      for (final MapEntry(key: name, value: watch) in watchStreams().entries) {
        await _inFakeAsync(name, () => watch().listen((_) {}).cancel());
      }
    });

    test('dispose() completes', () async {
      // Created in the zone as well, as a widget test body creates them, and
      // disposed in pumpTestApp's teardown order.
      await _inFakeAsync('dispose()', () async {
        final zoneCategories = FakeCategoryRepository();
        final zoneExpenses = FakeExpenseRepository(
          zoneCategories,
          today: () => today,
        );
        final zoneSettings = FakeSettingsRepository();
        await zoneExpenses.dispose();
        await zoneCategories.dispose();
        await zoneSettings.dispose();
      });
    });
  });
}
