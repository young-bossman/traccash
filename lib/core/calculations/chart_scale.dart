/// The top of a bar chart's money axis, in pesewas: the smallest
/// 1, 2, 2.5 or 5 × 10ⁿ cedis (n ≥ 0) that is at least [largestPesewas]
/// (DESIGN_SPEC §6). An empty chart, or one whose bars are all under a
/// cedi, gets GH₵ 1.
///
/// Every step is a multiple of 50 pesewas, so half of it, where the middle
/// label goes, is always a whole number of pesewas.
int chartAxisMaxPesewas(int largestPesewas) {
  assert(largestPesewas >= 0, 'Bars are never negative');
  // 10ⁿ cedis. Month totals stay far below 5 × 10¹⁸ pesewas, the last step
  // reachable before this would overflow.
  for (var power = 100; ; power *= 10) {
    for (final step in [power, 2 * power, 5 * power ~/ 2, 5 * power]) {
      if (step >= largestPesewas) return step;
    }
  }
}

/// The gap between axis labels: half of [axisMaxPesewas], so the axis is
/// labelled at 0, the middle and the top.
int chartAxisIntervalPesewas(int axisMaxPesewas) {
  assert(axisMaxPesewas.isEven, 'Axis maximums come from chartAxisMaxPesewas');
  return axisMaxPesewas ~/ 2;
}
