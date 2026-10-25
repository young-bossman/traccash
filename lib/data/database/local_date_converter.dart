import 'package:drift/drift.dart';
import 'package:traccash/core/formatting/dates.dart';

/// Stores a [LocalDate] as `YYYY-MM-DD` text.
///
/// Reading goes through [LocalDate.parseIso], which rejects impossible dates
/// even in release builds, so a corrupted row surfaces as an error instead of
/// a wrong date.
class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parseIso(fromDb);

  @override
  String toSql(LocalDate value) => value.toIso();
}
