import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

/// One day of the ledger: its expenses in the order given and their total.
final class DayGroup {
  const DayGroup({
    required this.date,
    required this.totalPesewas,
    required this.expenses,
  });

  final LocalDate date;
  final int totalPesewas;
  final List<Expense> expenses;
}

/// How many of a month's expenses are in [category].
typedef CategoryCount = ({Category category, int count});

int sumPesewas(Iterable<Expense> expenses) =>
    expenses.fold(0, (total, e) => total + e.amountPesewas);

/// Expenses whose note or category name contains [query] ignoring case, and
/// whose category is [categoryId] when one is given.
///
/// [query] is trimmed; a blank query matches everything.
List<Expense> filterExpenses(
  List<Expense> expenses, {
  String query = '',
  int? categoryId,
}) {
  final needle = query.trim().toLowerCase();
  return [
    for (final e in expenses)
      if ((categoryId == null || e.category.id == categoryId) &&
          (needle.isEmpty ||
              e.category.name.toLowerCase().contains(needle) ||
              (e.note?.toLowerCase().contains(needle) ?? false)))
        e,
  ];
}

/// Groups [expenses] by date, newest day first. Within a day the input order
/// is kept, so the repository's "most recently entered first" survives.
List<DayGroup> groupByDay(List<Expense> expenses) {
  final byDate = <LocalDate, List<Expense>>{};
  for (final e in expenses) {
    (byDate[e.occurredOn] ??= []).add(e);
  }
  final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final date in dates)
      DayGroup(
        date: date,
        totalPesewas: sumPesewas(byDate[date]!),
        expenses: byDate[date]!,
      ),
  ];
}

/// Counts for the category filter: every category in [categories] that is
/// active, plus any archived one that labels an expense in [expenses], in
/// display order. Active categories with no expenses are listed with 0.
List<CategoryCount> categoryCounts(
  List<Expense> expenses,
  List<Category> categories,
) {
  final counts = <int, int>{};
  final used = <int, Category>{};
  for (final e in expenses) {
    counts[e.category.id] = (counts[e.category.id] ?? 0) + 1;
    used[e.category.id] = e.category;
  }
  final listed = <int, Category>{
    for (final c in categories)
      if (!c.isArchived || counts.containsKey(c.id)) c.id: c,
  };
  // An expense can carry a category the list hasn't caught up with yet.
  for (final c in used.values) {
    listed.putIfAbsent(c.id, () => c);
  }
  final ordered = listed.values.toList()
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  return [for (final c in ordered) (category: c, count: counts[c.id] ?? 0)];
}
