import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/features/categories/data/drift_category_repository.dart';

import 'data_test_helpers.dart';

void main() {
  late AppDatabase db;
  late DriftCategoryRepository repo;

  setUp(() {
    db = openTestDatabase();
    repo = categoryRepo(db);
  });

  tearDown(() => db.close());

  test('watchActive starts with the 8 presets in order', () async {
    final active = await repo.watchActive().first;

    expect(
      [for (final c in active) c.name],
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
  });

  test('create collapses whitespace and appends after the presets', () async {
    final created = await repo.create('  School   fees ', 'education');

    expect(created.name, 'School fees');
    expect(created.iconKey, 'education');
    expect(created.isPreset, isFalse);
    expect(created.createdAt.isUtc, isTrue);
    final active = await repo.watchActive().first;
    expect(active.last, created);
    expect(created.sortOrder, greaterThan(active[7].sortOrder));
  });

  group('duplicate names', () {
    Matcher duplicateOf(String existing) => throwsA(
      isA<DuplicateCategoryError>().having(
        (e) => e.existingName,
        'existingName',
        existing,
      ),
    );

    test('"school FEES" is rejected when "School fees" exists', () async {
      await repo.create('School fees', 'education');

      await expectLater(
        repo.create('school FEES', 'tag'),
        duplicateOf('School fees'),
      );
      expect(await repo.watchAll().first, hasLength(9));
    });

    test('a preset name in different case is rejected', () async {
      await expectLater(repo.create('food', 'tag'), duplicateOf('Food'));
      await expectLater(
        repo.create('DATA  &  airtime', 'tag'),
        duplicateOf('Data & Airtime'),
      );
    });

    test(
      'non-ASCII case is caught too, which NOCASE alone would miss',
      () async {
        await repo.create('École', 'education');

        await expectLater(repo.create('école', 'tag'), duplicateOf('École'));
      },
    );

    test('the message names the stored spelling', () async {
      await repo.create('School fees', 'education');

      await expectLater(
        repo.create('SCHOOL FEES', 'tag'),
        throwsA(
          isA<DuplicateCategoryError>().having(
            (e) => e.message,
            'message',
            '“School fees” already exists. Choose it above.',
          ),
        ),
      );
    });
  });

  group('name and icon rules', () {
    test('rejects empty and whitespace-only names', () async {
      for (final name in ['', '   ']) {
        await expectLater(
          repo.create(name, 'tag'),
          throwsA(
            isA<CategoryNameError>().having(
              (e) => e.problem,
              'problem',
              CategoryNameProblem.empty,
            ),
          ),
        );
      }
    });

    test(
      'rejects 21 characters and accepts 20, counted in code points',
      () async {
        await expectLater(
          repo.create('a' * 21, 'tag'),
          throwsA(isA<CategoryNameError>()),
        );
        await repo.create('a' * 20, 'tag');
        // 20 emoji are 40 UTF-16 units but 20 characters to SQLite.
        await repo.create('🙂' * 20, 'tag');
        await expectLater(
          repo.create('🙂' * 21, 'tag'),
          throwsA(isA<CategoryNameError>()),
        );
      },
    );

    test('rejects an icon outside the user set', () async {
      await expectLater(
        repo.create('Pets', 'food'),
        throwsA(isA<InvalidCategoryIconError>()),
      );
      await expectLater(
        repo.create('Pets', 'rocket'),
        throwsA(isA<InvalidCategoryIconError>()),
      );
    });
  });

  group('archive', () {
    test('archived category is not in watchActive, is in watchAll, and '
        'still labels its old expenses', () async {
      final expenses = expenseRepo(db);
      final old = await expenses.add(draft(categoryId: transportId));

      await repo.archive(transportId);

      final active = await repo.watchActive().first;
      final all = await repo.watchAll().first;
      expect(active.map((c) => c.id), isNot(contains(transportId)));
      expect(all.firstWhere((c) => c.id == transportId).isArchived, isTrue);

      final labelled = (await expenses.getById(old.id))!;
      expect(labelled.category.name, 'Transport');
      expect(labelled.category.isArchived, isTrue);
      expect(
        (await expenses.watchRecent().first).single.category.name,
        'Transport',
      );
    });

    test('presets can be archived too', () async {
      await repo.archive(foodId);

      expect(await repo.watchActive().first, hasLength(7));
    });

    test('creating the name of an archived category brings it back', () async {
      final gifts = await repo.create('Gifts', 'gifts');
      await repo.archive(gifts.id);

      final again = await repo.create('GIFTS', 'tag');

      expect(again.id, gifts.id);
      expect(again.name, 'Gifts');
      expect(again.iconKey, 'gifts', reason: 'keeps its original icon');
      expect(again.isArchived, isFalse);
      expect(await repo.watchAll().first, hasLength(9));
    });

    test('archive of a missing id throws CategoryNotFoundError', () async {
      await expectLater(
        repo.archive(999),
        throwsA(isA<CategoryNotFoundError>()),
      );
    });
  });
}
