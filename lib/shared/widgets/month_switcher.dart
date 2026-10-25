import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/shared/selected_month.dart';

/// Previous / month / next, driving [selectedMonthProvider]. Next is disabled
/// at the current month because future months can't have expenses.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    // Watched so Next enables itself when the month turns over.
    ref.watch(todayProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: notifier.canGoBack ? notifier.previous : null,
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Semantics(
              label: month.label,
              liveRegion: true,
              excludeSemantics: true,
              // Shrinks only at text sizes where the buttons would otherwise
              // be pushed off screen.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(month.shortLabel, style: theme.textTheme.bodyLarge),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: notifier.canGoForward ? notifier.next : null,
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
