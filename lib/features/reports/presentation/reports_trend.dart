import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_motion.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/calculations/chart_scale.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/reports/presentation/reports_providers.dart';
import 'package:traccash/shared/text_measure.dart';
import 'package:traccash/shared/widgets/empty_state.dart';
import 'package:traccash/shared/widgets/section_card.dart';

/// "Spending trend": the Daily / Monthly toggle and the chart.
class ReportsTrend extends ConsumerWidget {
  const ReportsTrend({required this.view, super.key});

  final ReportsView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final period = ref.watch(trendPeriodProvider);
    final monthly = view.monthly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wraps the toggle under the heading when large text leaves no room.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.s8,
          children: [
            Semantics(
              header: true,
              child: Text('Spending trend', style: theme.textTheme.titleSmall),
            ),
            SegmentedButton<TrendPeriod>(
              segments: const [
                ButtonSegment(value: TrendPeriod.daily, label: Text('Daily')),
                ButtonSegment(
                  value: TrendPeriod.monthly,
                  label: Text('Monthly'),
                ),
              ],
              selected: {period},
              onSelectionChanged: (selection) => ref
                  .read(trendPeriodProvider.notifier)
                  .select(selection.single),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        SectionCard(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: switch (period) {
            TrendPeriod.daily => _TrendBars(
              key: const ValueKey(TrendPeriod.daily),
              values: view.dayTotals,
              axisMaxPesewas: view.dailyAxisMaxPesewas,
              barMaxWidth: AppSizes.dailyBarMaxWidth,
              labelAt: view.dailyAxisLabel,
              summary: view.dailySummary,
            ),
            TrendPeriod.monthly when monthly != null => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrendBars(
                  key: const ValueKey(TrendPeriod.monthly),
                  values: monthly.totals,
                  axisMaxPesewas: monthly.axisMaxPesewas,
                  barMaxWidth: AppSizes.monthlyBarWidth,
                  labelAt: monthly.axisLabel,
                  selectedIndex: monthly.totals.length - 1,
                  summary: monthly.summary,
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  view.monthlyNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            TrendPeriod.monthly => Padding(
              padding: const EdgeInsets.all(AppSpacing.s8),
              child: LoadErrorState(
                error: view.monthlyError ?? const StorageError(),
                onRetry: () {
                  ref
                    ..invalidate(trendExpensesProvider)
                    ..invalidate(firstExpenseDateProvider);
                },
              ),
            ),
          },
        ),
      ],
    );
  }
}

/// One bar per value on an axis from GH₵ 0 to [axisMaxPesewas], labelled at
/// 0, the middle and the top. Touch is off (DESIGN_SPEC §4), and screen
/// readers get [summary] in place of the drawing.
class _TrendBars extends StatelessWidget {
  const _TrendBars({
    required this.values,
    required this.axisMaxPesewas,
    required this.barMaxWidth,
    required this.labelAt,
    required this.summary,
    this.selectedIndex,
    super.key,
  });

  /// Pesewas per bar.
  final List<int> values;
  final int axisMaxPesewas;
  final double barMaxWidth;

  /// The label under bar [index], or null for none.
  final String? Function(int index) labelAt;
  final String summary;

  /// The only bar in the accent colour, with its label in bold; the others
  /// are muted. Null when every bar is in the accent colour.
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barMuted = AppPalette.of(context).barMuted;
    final axisStyle = AppTypography.axis.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final interval = chartAxisIntervalPesewas(axisMaxPesewas);
    final labelWidth = [
      for (final pesewas in [0, interval, axisMaxPesewas])
        singleLineWidth(context, formatGhsAxis(pesewas), axisStyle),
    ].reduce(max);
    final bottomReserved = singleLineHeight(context, axisStyle) + AppSpacing.s4;

    return Semantics(
      container: true,
      label: summary,
      child: ExcludeSemantics(
        child: SizedBox(
          height: AppSizes.trendChartHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // As wide as the widest money label at the user's text size,
              // up to a share of the chart; labels past it shrink rather
              // than clip.
              final labelSpace = min(
                labelWidth,
                constraints.maxWidth * AppSizes.chartAxisMaxShare,
              );
              final leftReserved = labelSpace + AppSpacing.s8;
              final slot =
                  max(0.0, constraints.maxWidth - leftReserved) / values.length;
              final barWidth = min(barMaxWidth, slot * AppSizes.barSlotFill);

              return BarChart(
                BarChartData(
                  minY: 0,
                  maxY: axisMaxPesewas.toDouble(),
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: const BarTouchData(enabled: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: interval.toDouble(),
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant,
                      strokeWidth: AppSizes.chartGridLine,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: leftReserved,
                        interval: interval.toDouble(),
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          space: AppSpacing.s8,
                          fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                          child: SizedBox(
                            width: labelSpace,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              // Back to whole pesewas before formatting.
                              child: Text(
                                formatGhsAxis(value.round()),
                                style: axisStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: bottomReserved,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final label = labelAt(index);
                          if (label == null) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            space: AppSpacing.s4,
                            child: Text(
                              label,
                              style: index == selectedIndex
                                  ? axisStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                    )
                                  : axisStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (final (i, pesewas) in values.indexed)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            // A double for drawing only. Totals are far
                            // below 2⁵³, so the conversion is exact.
                            toY: pesewas.toDouble(),
                            width: barWidth,
                            // A day or month with nothing has no bar.
                            color: pesewas == 0
                                ? Colors.transparent
                                : selectedIndex == null || i == selectedIndex
                                ? scheme.primary
                                : barMuted,
                            borderRadius: const BorderRadius.vertical(
                              top: AppRadius.chartBar,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.chartUpdate,
              );
            },
          ),
        ),
      ),
    );
  }
}
