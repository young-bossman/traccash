import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/core/formatting/dates.dart';

/// The device's calendar day, kept current while the app stays open.
///
/// Tests override it with a fixed date.
final NotifierProvider<TodayNotifier, LocalDate> todayProvider =
    NotifierProvider<TodayNotifier, LocalDate>(TodayNotifier.new);

class TodayNotifier extends Notifier<LocalDate> {
  Timer? _midnight;

  @override
  LocalDate build() {
    // Android suspends timers while the app is in the background, so the
    // midnight timer alone could leave "Today" a day behind after resuming.
    final lifecycle = AppLifecycleListener(onResume: _refresh);
    ref.onDispose(() {
      _midnight?.cancel();
      lifecycle.dispose();
    });
    _scheduleMidnight();
    return LocalDate.today();
  }

  void _refresh() {
    final today = LocalDate.today();
    if (today != state) state = today;
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    // A second past midnight, so the timer never lands just before it.
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _midnight = Timer(next.difference(now), _refresh);
  }
}

/// The month shown on Home, Expenses and Reports. Changing it in one place
/// changes all three. Starts at the current month.
final NotifierProvider<SelectedMonthNotifier, CalendarMonth>
selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, CalendarMonth>(
  SelectedMonthNotifier.new,
);

class SelectedMonthNotifier extends Notifier<CalendarMonth> {
  /// Matches the earliest date an expense may have.
  static const CalendarMonth earliest = CalendarMonth(2000, 1);

  // Read, not watched: the selection must not jump back to the current month
  // when the day changes.
  @override
  CalendarMonth build() => CalendarMonth.of(ref.read(todayProvider));

  CalendarMonth get _current => CalendarMonth.of(ref.read(todayProvider));

  bool get canGoBack => state != earliest;

  bool get canGoForward => state.first.compareTo(_current.first) < 0;

  void previous() {
    if (canGoBack) state = state.previous;
  }

  void next() {
    if (canGoForward) state = state.next;
  }

  /// Jumps to [month], kept between [earliest] and the current month. Used
  /// by the View action after saving an expense to another month.
  void show(CalendarMonth month) {
    final current = _current;
    if (month.first.compareTo(earliest.first) < 0) {
      state = earliest;
    } else if (month.first.compareTo(current.first) > 0) {
      state = current;
    } else {
      state = month;
    }
  }
}
