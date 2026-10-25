import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

import 'test_app.dart';

LocalDate _oct(int day) => LocalDate(2026, 10, day);
LocalDate sep(int day) => LocalDate(2026, 9, day);

/// The month in 01-home-light.png: GH₵ 2,313.90 across all 8 presets, with
/// Bills, Shopping and Food largest. Entered oldest first, so the newest
/// is listed first; ids 1 to 12 in this order.
final List<ExpenseDraft> october = [
  draft(45000, PresetIds.bills, date: _oct(5), note: 'ECG prepaid'),
  draft(53050, PresetIds.food, date: _oct(8), note: 'Market run'),
  draft(31900, PresetIds.bills, date: _oct(10), note: 'Water bill'),
  draft(22800, PresetIds.shopping, date: _oct(12)),
  draft(12000, PresetIds.health, date: _oct(14), note: 'Pharmacy'),
  draft(35000, PresetIds.shopping, date: _oct(15), note: 'School shoes'),
  draft(8000, PresetIds.entertainment, date: _oct(17), note: 'Cinema'),
  draft(9440, PresetIds.other, date: _oct(18)),
  draft(
    3500,
    PresetIds.transport,
    date: _oct(19),
    note: 'Ride to Airport City',
  ),
  draft(5000, PresetIds.dataAirtime, date: _oct(20), note: 'MTN data bundle'),
  draft(1200, PresetIds.transport, note: 'Trotro, Madina to Circle'),
  draft(4500, PresetIds.food, note: 'Waakye and egg, lunch'),
];

/// 1–21 September is GH₵ 5,571.00, so October is GH₵ 3,257.10 less. The
/// 25th falls outside the compared days. GH₵ 6,571.00 for the whole month.
final List<ExpenseDraft> september = [
  draft(300000, PresetIds.bills, date: sep(2), note: 'Rent share'),
  draft(200000, PresetIds.shopping, date: sep(10)),
  draft(57100, PresetIds.food, date: sep(21)),
  draft(100000, PresetIds.transport, date: sep(25)),
];
