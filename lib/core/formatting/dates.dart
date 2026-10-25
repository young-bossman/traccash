import 'package:intl/intl.dart';

/// Locale for every date label. Its intl data must be loaded with
/// `initializeDateFormatting(dateLocale)` before any label is formatted.
const String dateLocale = 'en_GB';

final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

final DateFormat _numericDate = DateFormat('dd/MM/yyyy', dateLocale);
final DateFormat _longDate = DateFormat('EEEE, d MMMM y', dateLocale);
final DateFormat _monthLabel = DateFormat('MMMM y', dateLocale);

int _daysInMonth(int year, int month) =>
    // Day 0 of the next month is the last day of this one.
    DateTime.utc(year, month + 1, 0).day;

// Years are limited to four digits so ISO text is always 10 characters.
bool _isRealDate(int year, int month, int day) =>
    year >= 1 &&
    year <= 9999 &&
    month >= 1 &&
    month <= 12 &&
    day >= 1 &&
    day <= _daysInMonth(year, month);

/// A calendar day with no time or time zone, such as the day an expense
/// happened. It cannot drift to a neighbouring day when time zones change.
final class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day)
    : assert(
        _isRealDate(year, month, day),
        'Not a real date: $year-$month-$day',
      );

  /// The calendar day of [dateTime] as the device sees it.
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  factory LocalDate.today() => LocalDate.fromDateTime(DateTime.now());

  /// Reads `YYYY-MM-DD`, the stored form.
  ///
  /// Throws [FormatException] for anything else, including dates that do not
  /// exist such as `2026-02-30`, because that can only mean corrupted data.
  factory LocalDate.parseIso(String text) {
    final match = _isoDate.firstMatch(text);
    if (match == null) {
      throw FormatException('Expected a date as YYYY-MM-DD', text);
    }
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (!_isRealDate(year, month, day)) {
      throw FormatException('Not a real date', text);
    }
    return LocalDate(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  /// `YYYY-MM-DD`, which sorts chronologically as text.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  LocalDate addDays(int days) =>
      // UTC has no daylight-saving jumps, so adding days never skips or
      // repeats one.
      LocalDate.fromDateTime(DateTime.utc(year, month, day + days));

  DateTime get _asDateTime => DateTime.utc(year, month, day);

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// A calendar month. Its expenses are those with `first <= date < nextStart`.
final class CalendarMonth {
  const CalendarMonth(this.year, this.month)
    : assert(month >= 1 && month <= 12, 'Month must be 1 to 12');

  factory CalendarMonth.of(LocalDate date) =>
      CalendarMonth(date.year, date.month);

  final int year;
  final int month;

  int get daysInMonth => _daysInMonth(year, month);

  LocalDate get first => LocalDate(year, month, 1);

  LocalDate get last => LocalDate(year, month, daysInMonth);

  /// The 1st of the next month: the exclusive end of this month's range.
  LocalDate get nextStart => next.first;

  CalendarMonth get previous =>
      month == 1 ? CalendarMonth(year - 1, 12) : CalendarMonth(year, month - 1);

  CalendarMonth get next =>
      month == 12 ? CalendarMonth(year + 1, 1) : CalendarMonth(year, month + 1);

  bool contains(LocalDate date) => date.year == year && date.month == month;

  /// `October 2026`.
  String get label => _monthLabel.format(DateTime.utc(year, month));

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'CalendarMonth($year-$month)';
}

/// `21/10/2026`.
String formatNumericDate(LocalDate date) =>
    _numericDate.format(date._asDateTime);

/// `Wednesday, 21 October 2026`.
String formatLongDate(LocalDate date) => _longDate.format(date._asDateTime);

/// `Today`, `Yesterday`, or the long date. [today] is passed in so the label
/// is predictable in tests and consistent across one screen build.
String dayLabel(LocalDate date, {required LocalDate today}) {
  if (date == today) return 'Today';
  if (date == today.addDays(-1)) return 'Yesterday';
  return formatLongDate(date);
}
