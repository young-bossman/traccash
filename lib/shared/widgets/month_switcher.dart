import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/shared/selected_month.dart';

/// A screen title with the month switcher at the end of its line, for
/// Expenses and Reports. The switcher wraps under the title when large text
/// leaves no room beside it.
class TitleWithMonthSwitcher extends StatelessWidget {
  const TitleWithMonthSwitcher({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    // Full width because a Wrap given a loose width shrinks to its children,
    // leaving spaceBetween nothing to spread.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const MonthSwitcher(),
        ],
      ),
    );
  }
}

/// Previous / month / next, driving [selectedMonthProvider]. Next is disabled
/// at the current month because future months can't have expenses.
class MonthSwitcher extends ConsumerWidget {
  /// `‹ Oct 2026 ›`, sized to its content, beside the Expenses title.
  const MonthSwitcher({super.key}) : _spread = false;

  /// `October 2026` at the start and the arrows at the end, filling the
  /// width: Home's month row.
  const MonthSwitcher.spread({super.key}) : _spread = true;

  final bool _spread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    // Watched so Next enables itself when the month turns over.
    ref.watch(todayProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final theme = Theme.of(context);

    final previous = IconButton(
      onPressed: notifier.canGoBack ? notifier.previous : null,
      tooltip: 'Previous month',
      icon: const Icon(Icons.chevron_left),
    );
    final next = IconButton(
      onPressed: notifier.canGoForward ? notifier.next : null,
      tooltip: 'Next month',
      icon: const Icon(Icons.chevron_right),
    );
    final label = Semantics(
      label: month.label,
      liveRegion: true,
      excludeSemantics: true,
      // Shrinks only at text sizes where the buttons would otherwise be
      // pushed off screen.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _spread ? month.label : month.shortLabel,
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );

    if (_spread) {
      return Row(
        children: [
          // Align loosens the width Expanded fixes, so the FittedBox keeps
          // the text's height instead of growing to its aspect ratio.
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: label,
            ),
          ),
          previous,
          next,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        previous,
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: label,
          ),
        ),
        next,
      ],
    );
  }
}
