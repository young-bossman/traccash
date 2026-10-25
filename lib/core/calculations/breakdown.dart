import 'package:traccash/features/categories/domain/category.dart';
import 'package:traccash/features/expenses/domain/expense.dart';

/// One category's spending across a list of expenses.
final class CategoryTotal {
  const CategoryTotal({required this.category, required this.totalPesewas});

  final Category category;
  final int totalPesewas;
}

/// One part of Home's breakdown bar and legend: a single category, or the
/// remaining categories together.
final class BreakdownSlice {
  const BreakdownSlice({
    required this.category,
    required this.categoryCount,
    required this.totalPesewas,
    required this.shareTenths,
  });

  /// Null for the slice that groups the remaining categories.
  final Category? category;

  /// 1 for a named category; how many are grouped otherwise.
  final int categoryCount;
  final int totalPesewas;

  /// Tenths of a percent of the month: 332 is 33.2%.
  final int shareTenths;
}

/// The whole, in tenths of a percent.
const int _wholeTenths = 1000;

/// Categories the breakdown names before grouping the rest.
const int _namedSlices = 3;

/// Each category's total in [expenses], largest first.
///
/// Equal totals are in display order (sort order, then id), so the order
/// never depends on which expense happened to be entered first.
List<CategoryTotal> categoryTotals(Iterable<Expense> expenses) {
  final pesewas = <int, int>{};
  final categories = <int, Category>{};
  for (final e in expenses) {
    pesewas[e.category.id] = (pesewas[e.category.id] ?? 0) + e.amountPesewas;
    categories[e.category.id] = e.category;
  }
  final totals = [
    for (final MapEntry(key: id, value: total) in pesewas.entries)
      CategoryTotal(category: categories[id]!, totalPesewas: total),
  ];
  return totals..sort((a, b) {
    var c = b.totalPesewas.compareTo(a.totalPesewas);
    if (c == 0) c = a.category.sortOrder.compareTo(b.category.sortOrder);
    if (c == 0) c = a.category.id.compareTo(b.category.id);
    return c;
  });
}

/// Each of [amounts] as tenths of a percent of their sum, adding up to
/// exactly 1000 (100.0%).
///
/// Largest-remainder rounding: every share is rounded down, then the tenths
/// still missing go one each to the shares that lost the most. Equal
/// remainders favour the earlier amount, so three equal amounts are 33.4%,
/// 33.3% and 33.3%. All zero amounts give 0 each. Integer arithmetic only.
List<int> shareTenths(List<int> amounts) {
  assert(amounts.every((a) => a >= 0), 'Amounts must not be negative');
  final total = _sum(amounts);
  if (total == 0) return List.filled(amounts.length, 0);

  final shares = [for (final a in amounts) a * _wholeTenths ~/ total];
  final remainders = [for (final a in amounts) a * _wholeTenths % total];
  final byRemainder = List.generate(amounts.length, (i) => i)
    ..sort((a, b) {
      final c = remainders[b].compareTo(remainders[a]);
      return c != 0 ? c : a.compareTo(b);
    });
  // Rounding down loses less than a tenth per amount, so fewer tenths are
  // missing than there are amounts to give them to.
  for (final i in byRemainder.take(_wholeTenths - _sum(shares))) {
    shares[i]++;
  }
  return shares;
}

int _sum(Iterable<int> values) => values.fold<int>(0, (sum, v) => sum + v);

/// Home's breakdown of [totals] (in [categoryTotals] order): the 3 largest
/// categories by name, then the rest as one slice.
///
/// With exactly 4 categories the fourth is named too, since a
/// "1 other category" row would hide a name without saving a row.
///
/// Shares are rounded across every category and the grouped slice's share
/// is the sum of its members', so a category reads the same here as in a
/// table of all categories.
List<BreakdownSlice> breakdownSlices(List<CategoryTotal> totals) {
  final shares = shareTenths([for (final t in totals) t.totalPesewas]);
  BreakdownSlice named(int i) => BreakdownSlice(
    category: totals[i].category,
    categoryCount: 1,
    totalPesewas: totals[i].totalPesewas,
    shareTenths: shares[i],
  );

  if (totals.length <= _namedSlices + 1) {
    return [for (var i = 0; i < totals.length; i++) named(i)];
  }
  var restPesewas = 0;
  var restTenths = 0;
  for (var i = _namedSlices; i < totals.length; i++) {
    restPesewas += totals[i].totalPesewas;
    restTenths += shares[i];
  }
  return [
    for (var i = 0; i < _namedSlices; i++) named(i),
    BreakdownSlice(
      category: null,
      categoryCount: totals.length - _namedSlices,
      totalPesewas: restPesewas,
      shareTenths: restTenths,
    ),
  ];
}

/// Every category tied for the largest total in [totals] (in
/// [categoryTotals] order), in display order.
List<Category> largestCategories(List<CategoryTotal> totals) {
  if (totals.isEmpty) return const [];
  final largest = totals.first.totalPesewas;
  return [
    for (final t in totals.takeWhile((t) => t.totalPesewas == largest))
      t.category,
  ];
}
