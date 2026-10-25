import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/formatting/dates.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/features/reports/presentation/reports_categories.dart';
import 'package:traccash/features/reports/presentation/reports_providers.dart';
import 'package:traccash/features/reports/presentation/reports_summary.dart';
import 'package:traccash/features/reports/presentation/reports_trend.dart';
import 'package:traccash/shared/widgets/empty_state.dart';
import 'package:traccash/shared/widgets/month_switcher.dart';
import 'package:traccash/shared/widgets/section_card.dart';

/// The selected month in detail: total, stats, the largest category, every
/// category and the spending trend.
///
/// The header always shows; everything below follows the month's data.
/// Reports has no Add expense button of its own (DESIGN_SPEC §4); the
/// no-data state carries one.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(reportsViewProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s16,
            AppSpacing.s20,
            AppSpacing.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TitleWithMonthSwitcher(title: 'Reports'),
              const SizedBox(height: AppSpacing.s16),
              switch (view) {
                AsyncData(:final value) when value.isEmpty => SectionCard(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: _NoReportData(month: value.month),
                ),
                AsyncData(:final value) => _ReportsBody(view: value),
                AsyncError(:final error) => SectionCard(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: LoadErrorState(
                    error: error,
                    onRetry: () {
                      ref
                        ..invalidate(monthExpensesProvider)
                        ..invalidate(previousPeriodTotalProvider)
                        ..invalidate(trendExpensesProvider)
                        ..invalidate(firstExpenseDateProvider);
                    },
                  ),
                ),
                // No figures while loading, so a new month's label never
                // sits over the old month's report.
                _ => const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.s32),
                  child: Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading expenses',
                    ),
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.view});

  final ReportsView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportsTotal(view: view),
        const SizedBox(height: AppSpacing.s20),
        ReportsStats(view: view),
        const SizedBox(height: AppSpacing.s20),
        LargestCategoryCard(view: view),
        const SizedBox(height: AppSpacing.s28),
        ReportsCategories(view: view),
        const SizedBox(height: AppSpacing.s28),
        ReportsTrend(view: view),
      ],
    );
  }
}

/// Screenshot 15: [month] has nothing to report. Also shown on first use,
/// since the message names the month either way.
class _NoReportData extends StatelessWidget {
  const _NoReportData({required this.month});

  final CalendarMonth month;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.bar_chart_outlined,
      title: 'No spending to report',
      message: 'Reports appear once ${month.label} has at least one expense.',
      action: FilledButton.tonalIcon(
        onPressed: () => context.push(AppRoutes.addExpense),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}
