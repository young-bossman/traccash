import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traccash/core/formatting/dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting(dateLocale);
  });

  group('LocalDate', () {
    test('has value equality and chronological ordering', () {
      expect(LocalDate(2026, 10, 21), LocalDate(2026, 10, 21));
      expect(
        LocalDate(2026, 10, 21).hashCode,
        LocalDate(2026, 10, 21).hashCode,
      );
      final sorted = [
        LocalDate(2027, 1, 1),
        LocalDate(2026, 10, 2),
        LocalDate(2026, 9, 30),
        LocalDate(2026, 10, 1),
      ]..sort();
      expect(sorted, [
        LocalDate(2026, 9, 30),
        LocalDate(2026, 10, 1),
        LocalDate(2026, 10, 2),
        LocalDate(2027, 1, 1),
      ]);
    });

    test('asserts that the fields form a real date', () {
      for (final (y, m, d) in [
        (2026, 2, 29),
        (2026, 13, 1),
        (2026, 0, 1),
        (2026, 4, 31),
        (2026, 10, 0),
        (0, 1, 1),
        (10000, 1, 1),
      ]) {
        expect(
          () => LocalDate(y, m, d),
          throwsA(isA<AssertionError>()),
          reason: '$y-$m-$d',
        );
      }
    });

    test('takes the local calendar day from a DateTime', () {
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 21, 23, 59, 59)),
        LocalDate(2026, 10, 21),
      );
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 22)),
        LocalDate(2026, 10, 22),
      );
    });

    test('writes zero-padded ISO text', () {
      expect(LocalDate(2026, 1, 5).toIso(), '2026-01-05');
      expect(LocalDate(2026, 10, 21).toIso(), '2026-10-21');
      expect(LocalDate(2026, 10, 21).toIso().length, 10);
    });

    test('parses ISO text and round-trips', () {
      expect(LocalDate.parseIso('2026-10-21'), LocalDate(2026, 10, 21));
      expect(LocalDate.parseIso('2024-02-29'), LocalDate(2024, 2, 29));
      final date = LocalDate(2000, 1, 1);
      expect(LocalDate.parseIso(date.toIso()), date);
    });

    test('rejects ISO text that is malformed or not a real date', () {
      for (final text in [
        '',
        '2026-2-1',
        '20261021',
        ' 2026-10-21',
        '2026-10-21T00:00',
        '21/10/2026',
        '2026-02-30',
        '2025-02-29',
        '2026-13-01',
        '2026-00-10',
        '2026-10-00',
        '0000-01-01',
      ]) {
        expect(
          () => LocalDate.parseIso(text),
          throwsFormatException,
          reason: text,
        );
      }
    });

    test('adds days across month, year and leap boundaries', () {
      expect(LocalDate(2026, 10, 31).addDays(1), LocalDate(2026, 11, 1));
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2027, 1, 1).addDays(-1), LocalDate(2026, 12, 31));
      expect(LocalDate(2024, 3, 1).addDays(-1), LocalDate(2024, 2, 29));
      expect(LocalDate(2026, 3, 1).addDays(-1), LocalDate(2026, 2, 28));
    });
  });

  group('CalendarMonth', () {
    test('asserts that month is 1 to 12', () {
      for (final month in [0, 13]) {
        expect(
          () => CalendarMonth(2026, month),
          throwsA(isA<AssertionError>()),
          reason: '$month',
        );
      }
    });

    test('is found from a date', () {
      expect(
        CalendarMonth.of(LocalDate(2026, 10, 21)),
        const CalendarMonth(2026, 10),
      );
    });

    test('knows the days in every month of a common year', () {
      const expected = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      for (var m = 1; m <= 12; m++) {
        expect(CalendarMonth(2026, m).daysInMonth, expected[m - 1]);
      }
    });

    test('handles leap year February', () {
      expect(const CalendarMonth(2024, 2).daysInMonth, 29);
      expect(const CalendarMonth(2000, 2).daysInMonth, 29);
      expect(const CalendarMonth(2026, 2).daysInMonth, 28);
      expect(const CalendarMonth(2100, 2).daysInMonth, 28);
      expect(const CalendarMonth(2024, 2).last, LocalDate(2024, 2, 29));
      expect(const CalendarMonth(2024, 2).nextStart, LocalDate(2024, 3, 1));
      expect(const CalendarMonth(2026, 2).last, LocalDate(2026, 2, 28));
      expect(const CalendarMonth(2026, 2).nextStart, LocalDate(2026, 3, 1));
    });

    test('has a half-open range from the 1st to the next 1st', () {
      const october = CalendarMonth(2026, 10);
      expect(october.first, LocalDate(2026, 10, 1));
      expect(october.last, LocalDate(2026, 10, 31));
      expect(october.nextStart, LocalDate(2026, 11, 1));
    });

    test('goes from December to January and back', () {
      const december = CalendarMonth(2026, 12);
      expect(december.next, const CalendarMonth(2027, 1));
      expect(december.nextStart, LocalDate(2027, 1, 1));
      expect(const CalendarMonth(2027, 1).previous, december);
      expect(
        const CalendarMonth(2026, 3).previous,
        const CalendarMonth(2026, 2),
      );
    });

    test('contains its 1st and last day but not its neighbours', () {
      const october = CalendarMonth(2026, 10);
      expect(october.contains(LocalDate(2026, 10, 1)), isTrue);
      expect(october.contains(LocalDate(2026, 10, 31)), isTrue);
      expect(october.contains(LocalDate(2026, 9, 30)), isFalse);
      expect(october.contains(LocalDate(2026, 11, 1)), isFalse);

      const december = CalendarMonth(2026, 12);
      expect(december.contains(LocalDate(2026, 12, 31)), isTrue);
      expect(december.contains(LocalDate(2027, 1, 1)), isFalse);
      expect(december.contains(LocalDate(2025, 12, 15)), isFalse);
    });

    test('ISO text comparison matches the range, as the database uses it', () {
      for (final month in const [
        CalendarMonth(2026, 10),
        CalendarMonth(2026, 12),
        CalendarMonth(2024, 2),
      ]) {
        final from = month.first.toIso();
        final to = month.nextStart.toIso();
        bool inRange(LocalDate d) =>
            d.toIso().compareTo(from) >= 0 && d.toIso().compareTo(to) < 0;

        for (var day = 1; day <= month.daysInMonth; day++) {
          final date = LocalDate(month.year, month.month, day);
          expect(inRange(date), isTrue, reason: date.toIso());
        }
        expect(inRange(month.first.addDays(-1)), isFalse);
        expect(inRange(month.nextStart), isFalse);
      }
    });
  });

  group('labels', () {
    test('numeric date is day/month/year, zero-padded', () {
      expect(formatNumericDate(LocalDate(2026, 10, 21)), '21/10/2026');
      expect(formatNumericDate(LocalDate(2026, 1, 5)), '05/01/2026');
    });

    test('long date names the weekday and month', () {
      expect(
        formatLongDate(LocalDate(2026, 10, 21)),
        'Wednesday, 21 October 2026',
      );
      expect(formatLongDate(LocalDate(2027, 1, 1)), 'Friday, 1 January 2027');
    });

    test('day label says Today and Yesterday', () {
      final today = LocalDate(2026, 10, 21);
      expect(dayLabel(today, today: today), 'Today');
      expect(dayLabel(LocalDate(2026, 10, 20), today: today), 'Yesterday');
      expect(
        dayLabel(LocalDate(2026, 10, 19), today: today),
        'Monday, 19 October 2026',
      );
    });

    test('Yesterday works across month and year boundaries', () {
      expect(
        dayLabel(LocalDate(2026, 10, 31), today: LocalDate(2026, 11, 1)),
        'Yesterday',
      );
      expect(
        dayLabel(LocalDate(2026, 12, 31), today: LocalDate(2027, 1, 1)),
        'Yesterday',
      );
    });

    test('month label', () {
      expect(const CalendarMonth(2026, 10).label, 'October 2026');
      expect(const CalendarMonth(2027, 1).label, 'January 2027');
    });

    test('short month names follow the design, Sep not Sept', () {
      expect(
        [for (var m = 1; m <= 12; m++) shortMonthName(m)],
        [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ],
      );
    });

    test('short month name asserts that month is 1 to 12', () {
      expect(() => shortMonthName(0), throwsA(isA<AssertionError>()));
      expect(() => shortMonthName(13), throwsA(isA<AssertionError>()));
    });

    test('short month label for every month', () {
      expect(
        [for (var m = 1; m <= 12; m++) CalendarMonth(2026, m).shortLabel],
        [
          'Jan 2026',
          'Feb 2026',
          'Mar 2026',
          'Apr 2026',
          'May 2026',
          'Jun 2026',
          'Jul 2026',
          'Aug 2026',
          'Sep 2026',
          'Oct 2026',
          'Nov 2026',
          'Dec 2026',
        ],
      );
      expect(const CalendarMonth(2027, 1).shortLabel, 'Jan 2027');
    });

    test('day heading has the weekday and month but no year', () {
      expect(formatDayHeading(LocalDate(2026, 10, 19)), 'Monday, 19 October');
      expect(formatDayHeading(LocalDate(2027, 1, 1)), 'Friday, 1 January');
    });

    test('ledger day label says Today, Yesterday or the day heading', () {
      final today = LocalDate(2026, 10, 21);
      expect(ledgerDayLabel(today, today: today), 'Today');
      expect(
        ledgerDayLabel(LocalDate(2026, 10, 20), today: today),
        'Yesterday',
      );
      expect(
        ledgerDayLabel(LocalDate(2026, 10, 19), today: today),
        'Monday, 19 October',
      );
      expect(
        ledgerDayLabel(LocalDate(2026, 12, 31), today: LocalDate(2027, 1, 1)),
        'Yesterday',
      );
    });

    test('day and month leave out the year in the current year', () {
      expect(
        formatDayAndMonth(
          LocalDate(2026, 10, 21),
          today: LocalDate(2026, 10, 21),
        ),
        '21 October',
      );
      expect(
        formatDayAndMonth(
          LocalDate(2026, 1, 1),
          today: LocalDate(2026, 12, 31),
        ),
        '1 January',
      );
    });

    test('day and month add the year for any other year', () {
      expect(
        formatDayAndMonth(
          LocalDate(2025, 10, 21),
          today: LocalDate(2026, 10, 21),
        ),
        '21 October 2025',
      );
      expect(
        formatDayAndMonth(
          LocalDate(2026, 12, 31),
          today: LocalDate(2027, 1, 1),
        ),
        '31 December 2026',
      );
    });

    test('a day range reads 1–21 Sep, with the short month name', () {
      expect(
        formatDayRange(LocalDate(2026, 9, 1), LocalDate(2026, 9, 21)),
        '1–21 Sep',
      );
      expect(
        formatDayRange(LocalDate(2026, 8, 1), LocalDate(2026, 8, 31)),
        '1–31 Aug',
      );
      expect(
        formatDayRange(LocalDate(2028, 2, 1), LocalDate(2028, 2, 29)),
        '1–29 Feb',
      );
    });

    test('a range of one day names the day once', () {
      expect(
        formatDayRange(LocalDate(2026, 9, 1), LocalDate(2026, 9, 1)),
        '1 Sep',
      );
    });

    test('a day range asserts that it stays inside one month', () {
      expect(
        () => formatDayRange(LocalDate(2026, 9, 21), LocalDate(2026, 9, 1)),
        throwsAssertionError,
      );
      expect(
        () => formatDayRange(LocalDate(2026, 9, 30), LocalDate(2026, 10, 1)),
        throwsAssertionError,
      );
    });

    test('short day label says Today, Yesterday or 19 Oct', () {
      final today = LocalDate(2026, 10, 21);
      expect(shortDayLabel(today, today: today), 'Today');
      expect(shortDayLabel(LocalDate(2026, 10, 20), today: today), 'Yesterday');
      expect(shortDayLabel(LocalDate(2026, 10, 19), today: today), '19 Oct');
      expect(shortDayLabel(LocalDate(2026, 9, 1), today: today), '1 Sep');
      expect(
        shortDayLabel(LocalDate(2026, 12, 31), today: LocalDate(2027, 1, 1)),
        'Yesterday',
      );
    });

    test('date field helper says Today, Yesterday or the long date', () {
      final today = LocalDate(2026, 10, 21);
      expect(
        dateFieldHelper(today, today: today),
        'Today · Wednesday, 21 October 2026',
      );
      expect(
        dateFieldHelper(LocalDate(2026, 10, 20), today: today),
        'Yesterday · Tuesday, 20 October 2026',
      );
      expect(
        dateFieldHelper(LocalDate(2026, 9, 30), today: today),
        'Wednesday, 30 September 2026',
      );
    });
  });

  test('toLocalDateTime is local midnight and reads back unchanged', () {
    final date = LocalDate(2026, 3, 29);
    final dateTime = date.toLocalDateTime();
    expect(dateTime.isUtc, isFalse);
    expect((dateTime.hour, dateTime.minute, dateTime.second), (0, 0, 0));
    expect(LocalDate.fromDateTime(dateTime), date);
  });
}
