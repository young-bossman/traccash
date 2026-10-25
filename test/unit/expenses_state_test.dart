import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/shared/selected_month.dart';

import '../fakes/fixed_today.dart';

ProviderContainer _container({LocalDate? today}) => ProviderContainer.test(
  overrides: [
    todayProvider.overrideWith(
      () => FixedToday(today ?? LocalDate(2026, 10, 21)),
    ),
  ],
);

void main() {
  group('todayProvider', () {
    // flutter_test fails a test that ends with a timer still pending.
    testWidgets('cancels its midnight timer when disposed', (tester) async {
      final container = ProviderContainer();
      expect(container.read(todayProvider), LocalDate.today());

      // Background and back, in the order Android reports it.
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      expect(container.read(todayProvider), LocalDate.today());

      container.dispose();
    });
  });

  group('selectedMonthProvider', () {
    test('starts at the current month and cannot go past it', () {
      final container = _container();
      final notifier = container.read(selectedMonthProvider.notifier);

      expect(
        container.read(selectedMonthProvider),
        const CalendarMonth(2026, 10),
      );
      expect(notifier.canGoForward, isFalse);

      notifier.next();
      expect(
        container.read(selectedMonthProvider),
        const CalendarMonth(2026, 10),
      );
    });

    test('goes back across a year and forward again', () {
      final container = _container(today: LocalDate(2027, 1, 5));
      final notifier = container.read(selectedMonthProvider.notifier)
        ..previous();

      expect(
        container.read(selectedMonthProvider),
        const CalendarMonth(2026, 12),
      );
      expect(notifier.canGoForward, isTrue);

      notifier.next();
      expect(
        container.read(selectedMonthProvider),
        const CalendarMonth(2027, 1),
      );
    });

    test('stops at January 2000', () {
      final container = _container(today: LocalDate(2000, 2, 1));
      final notifier = container.read(selectedMonthProvider.notifier)
        ..previous();
      expect(notifier.canGoBack, isFalse);

      notifier.previous();
      expect(
        container.read(selectedMonthProvider),
        const CalendarMonth(2000, 1),
      );
    });
  });

  group('selectedMonthProvider.show', () {
    test('jumps to an earlier month', () {
      final container = _container();
      container
          .read(selectedMonthProvider.notifier)
          .show(const CalendarMonth(2026, 9));
      expect(
        container.read(selectedMonthProvider),
        const CalendarMonth(2026, 9),
      );
    });

    test('never goes past the current month or before January 2000', () {
      final container = _container();
      final notifier = container.read(selectedMonthProvider.notifier)
        ..show(const CalendarMonth(2026, 11));
      expect(
        container.read(selectedMonthProvider),
        const CalendarMonth(2026, 10),
      );

      notifier.show(const CalendarMonth(1999, 12));
      expect(
        container.read(selectedMonthProvider),
        const CalendarMonth(2000, 1),
      );
    });
  });

  group('expenseFiltersProvider', () {
    testWidgets('applies the query 200 ms after the last change', (
      tester,
    ) async {
      final container = _container();
      final notifier = container.read(expenseFiltersProvider.notifier)
        ..setQuery('tro');
      await tester.pump(const Duration(milliseconds: 150));
      notifier.setQuery('trotro');
      await tester.pump(const Duration(milliseconds: 150));

      expect(container.read(expenseFiltersProvider).query, '');

      await tester.pump(const Duration(milliseconds: 50));
      expect(container.read(expenseFiltersProvider).query, 'trotro');
    });

    testWidgets('clear cancels a pending query', (tester) async {
      final container = _container();
      container.read(expenseFiltersProvider.notifier)
        ..setCategory(2)
        ..setQuery('pizza')
        ..clear();
      await tester.pump(const Duration(milliseconds: 300));

      expect(container.read(expenseFiltersProvider).isActive, isFalse);
    });

    test('a whitespace-only query is not an active filter', () {
      expect(const ExpenseFilters(query: '   ').isActive, isFalse);
      expect(const ExpenseFilters(categoryId: 1).isActive, isTrue);
    });
  });
}
