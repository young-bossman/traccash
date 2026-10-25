import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/data/database/demo_seed.dart';

import 'data_test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('inserts 41 records matching DESIGN_SPEC §9', () async {
    final added = await seedDemoData(db, today: testToday);

    expect(added, 41);
    final all = await expenseRepo(db)
        .watchBetween(LocalDate(2000, 1, 1), testToday)
        .first;
    expect(all, hasLength(41));

    expect(all.map((e) => e.category.name).toSet(), hasLength(8));
    expect(all.first.occurredOn, testToday);
    expect(all.last.occurredOn, testToday.addDays(-75));
    expect(all.where((e) => e.occurredOn == testToday).length, greaterThan(1));
    expect(all.any((e) => e.occurredOn == testToday.addDays(-1)), isTrue);
    expect(all.map((e) => e.amountPesewas), containsAll([150000, 480000]));
    expect(all.any((e) => e.note == null), isTrue);
    expect(all.any((e) => (e.note?.length ?? 0) > 120), isTrue);

    // Current, previous and earlier months all have records.
    final months = all.map((e) => CalendarMonth.of(e.occurredOn)).toSet();
    expect(months.length, greaterThanOrEqualTo(3));
  });

  test('a second run adds nothing', () async {
    await seedDemoData(db, today: testToday);

    final secondRun = await seedDemoData(db, today: testToday);

    expect(secondRun, 0);
    final count = await db.select(db.expenses).get();
    expect(count, hasLength(41));
  });
}
