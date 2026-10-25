import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/features/home/presentation/home_breakdown.dart';
import 'package:traccash/features/home/presentation/home_providers.dart';
import 'package:traccash/features/home/presentation/home_recent.dart';
import 'package:traccash/features/home/presentation/home_section.dart';
import 'package:traccash/features/home/presentation/home_total.dart';
import 'package:traccash/shared/widgets/empty_state.dart';
import 'package:traccash/shared/widgets/month_switcher.dart';

/// The selected month at a glance: total, comparison, category breakdown
/// and the latest expenses.
///
/// The header and month row always show; everything below follows the
/// month's data. The Add expense button belongs to `AppShell`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(homeViewProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s16,
            AppSpacing.s20,
            AppSizes.fabClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AppHeader(),
              const SizedBox(height: AppSpacing.s16),
              const MonthSwitcher.spread(),
              const SizedBox(height: AppSpacing.s12),
              switch (view) {
                AsyncData(:final value) => _HomeBody(view: value),
                AsyncError(:final error) => HomeCard(
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  child: LoadErrorState(
                    error: error,
                    onRetry: () {
                      ref
                        ..invalidate(monthExpensesProvider)
                        ..invalidate(hasAnyExpensesProvider)
                        ..invalidate(previousPeriodTotalProvider);
                    },
                  ),
                ),
                // No figures while loading, so a new month's label never
                // sits over the old month's total.
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

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.view});

  final HomeView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeTotal(view: view),
        const SizedBox(height: AppSpacing.s28),
        if (!view.hasAnyExpenses)
          const HomeCard(
            padding: EdgeInsets.all(AppSpacing.s24),
            child: FirstUseState(),
          )
        else if (view.slices.isEmpty)
          HomeCard(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: EmptyMonthState(month: view.month),
          )
        else ...[
          HomeBreakdown(view: view),
          const SizedBox(height: AppSpacing.s28),
          HomeRecent(view: view),
        ],
      ],
    );
  }
}

/// The app mark and name.
class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: AppSizes.logoTile,
          height: AppSizes.logoTile,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: const BorderRadius.all(AppRadius.r8),
          ),
          child: Icon(
            Icons.notes,
            size: AppSizes.logoGlyph,
            color: scheme.onPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Flexible(
          child: Semantics(
            header: true,
            child: Text('TracCash', style: theme.textTheme.titleLarge),
          ),
        ),
      ],
    );
  }
}
