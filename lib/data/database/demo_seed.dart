import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/data/database/app_database.dart';
import 'package:traccash/data/database/database_provider.dart';
import 'package:traccash/data/database/db_errors.dart';

typedef _DemoExpense = ({
  int daysAgo,
  String category,
  int pesewas,
  String? note,
});

// DESIGN_SPEC §9: 41 fictional records across all 8 presets, 0 to 75 days
// back, with same-day entries, a long note, GH₵ 1,500.00 and GH₵ 4,800.00,
// and some without notes.
const List<_DemoExpense> _demoExpenses = [
  (daysAgo: 0, category: 'Food', pesewas: 3500, note: 'Waakye and egg'),
  (daysAgo: 0, category: 'Transport', pesewas: 800, note: 'Trotro to Circle'),
  (daysAgo: 0, category: 'Data & Airtime', pesewas: 2000, note: null),
  (daysAgo: 1, category: 'Food', pesewas: 4550, note: 'Jollof with chicken'),
  (daysAgo: 1, category: 'Transport', pesewas: 1500, note: 'Taxi to Osu'),
  (daysAgo: 2, category: 'Shopping', pesewas: 12999, note: 'Phone charger'),
  (daysAgo: 2, category: 'Food', pesewas: 2200, note: null),
  (daysAgo: 3, category: 'Bills', pesewas: 150000, note: 'Rent share'),
  (daysAgo: 3, category: 'Entertainment', pesewas: 6000, note: 'Cinema'),
  (daysAgo: 4, category: 'Health', pesewas: 8500, note: 'Pharmacy'),
  (daysAgo: 5, category: 'Food', pesewas: 1800, note: 'Kelewele'),
  (daysAgo: 6, category: 'Transport', pesewas: 3000, note: 'Ride to work'),
  (daysAgo: 7, category: 'Other', pesewas: 5000, note: 'Haircut'),
  (daysAgo: 8, category: 'Data & Airtime', pesewas: 5000, note: 'Data bundle'),
  (daysAgo: 9, category: 'Food', pesewas: 6750, note: 'Groceries at Makola'),
  (daysAgo: 10, category: 'Bills', pesewas: 25000, note: 'Electricity'),
  (daysAgo: 12, category: 'Shopping', pesewas: 480000, note: 'New fridge'),
  (daysAgo: 13, category: 'Food', pesewas: 3200, note: null),
  (
    daysAgo: 15,
    category: 'Entertainment',
    pesewas: 15000,
    note:
        'Birthday outing with the whole family: dinner, drinks and a boat '
        'ride on the Volta. Split with my sister, who will send her half on '
        'Friday after she gets paid.',
  ),
  (daysAgo: 17, category: 'Transport', pesewas: 1200, note: null),
  (daysAgo: 18, category: 'Health', pesewas: 3000, note: 'Clinic visit'),
  (daysAgo: 20, category: 'Food', pesewas: 2900, note: 'Banku and tilapia'),
  (daysAgo: 22, category: 'Data & Airtime', pesewas: 1000, note: null),
  (daysAgo: 24, category: 'Bills', pesewas: 9000, note: 'Water bill'),
  (daysAgo: 26, category: 'Other', pesewas: 2500, note: null),
  (daysAgo: 28, category: 'Food', pesewas: 4100, note: 'Fufu and light soup'),
  (daysAgo: 30, category: 'Shopping', pesewas: 7500, note: 'School shoes'),
  (daysAgo: 33, category: 'Transport', pesewas: 2000, note: 'Taxi to Kaneshie'),
  (daysAgo: 35, category: 'Bills', pesewas: 12000, note: 'TV subscription'),
  (daysAgo: 38, category: 'Food', pesewas: 3800, note: null),
  (daysAgo: 40, category: 'Health', pesewas: 12000, note: 'Lab tests'),
  (daysAgo: 43, category: 'Entertainment', pesewas: 4000, note: 'Football'),
  (daysAgo: 45, category: 'Food', pesewas: 2600, note: 'Red red'),
  (daysAgo: 48, category: 'Data & Airtime', pesewas: 3000, note: null),
  (daysAgo: 50, category: 'Transport', pesewas: 5500, note: 'Bus to Kumasi'),
  (daysAgo: 53, category: 'Other', pesewas: 10000, note: 'Gift for a friend'),
  (daysAgo: 57, category: 'Shopping', pesewas: 22000, note: 'Kente fabric'),
  (daysAgo: 60, category: 'Food', pesewas: 3100, note: null),
  (daysAgo: 64, category: 'Bills', pesewas: 30000, note: 'Electricity'),
  (daysAgo: 68, category: 'Health', pesewas: 4500, note: null),
  (daysAgo: 75, category: 'Food', pesewas: 5000, note: 'Lunch with the team'),
];

/// Debug only: fills an empty database with sample expenses dated relative
/// to [today]. Returns how many were added: 0 in release builds or when any
/// expense already exists, so a second tap can't double the data.
Future<int> seedDemoData(AppDatabase db, {required LocalDate today}) {
  // kDebugMode is a compile-time constant, so release builds drop the rest.
  if (!kDebugMode) return Future.value(0);

  return guardDb(
    () => db.transaction(() async {
      final count = db.expenses.id.count();
      final existing = await (db.selectOnly(
        db.expenses,
      )..addColumns([count])).map((row) => row.read(count)!).getSingle();
      if (existing > 0) return 0;

      final presets = await (db.select(
        db.categories,
      )..where((c) => c.isPreset.equals(true))).get();
      final idByName = {for (final c in presets) c.name: c.id};
      final now = DateTime.now().toUtc();

      await db.batch((b) {
        b.insertAll(db.expenses, [
          for (final demo in _demoExpenses)
            ExpensesCompanion.insert(
              amountPesewas: demo.pesewas,
              categoryId: idByName[demo.category]!,
              occurredOn: today.addDays(-demo.daysAgo),
              note: Value(demo.note),
              createdAt: now,
              updatedAt: now,
            ),
        ]);
      });
      return _demoExpenses.length;
    }),
  );
}

/// What the debug "Load demo data" button calls. Widget tests override it.
final Provider<Future<int> Function()> demoSeederProvider =
    Provider<Future<int> Function()>(
      (ref) =>
          () => seedDemoData(
            ref.read(appDatabaseProvider),
            today: LocalDate.today(),
          ),
    );
