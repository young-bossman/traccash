import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/data/database/demo_seed.dart';
import 'package:traccash/data/database/simulated_failure.dart';
import 'package:traccash/features/expenses/data/expense_repository.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/features/settings/presentation/settings_row.dart';
import 'package:traccash/shared/reduced_motion.dart';
import 'package:traccash/shared/widgets/dashed_border.dart';

/// Debug-only tools: sample data, a full reset and a simulated save failure.
/// The dashed card marks them as not part of the app (16-settings.png).
class DeveloperSection extends ConsumerWidget {
  const DeveloperSection({super.key});

  static const String helper = 'Debug builds only. Not in the release app.';
  static const String loadSubtitle =
      'Adds sample expenses when there are none yet.';
  static const String clearSubtitle =
      'Deletes every expense and every category you created.';
  static const String failSubtitle = 'Simulates a local database error once.';

  static const String clearTitle = 'Clear all data?';
  static const String clearBody =
      'Every expense and every category you created will be deleted. The 8 '
      'preset categories and your theme setting stay. This can’t be undone.';
  static const String cleared =
      'Cleared every expense and the categories you created.';
  static const String alreadyHasData =
      'Demo data not loaded: there are already expenses.';

  static String loaded(int count) => 'Loaded $count demo expenses.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final failNextWrite = ref.watch(failNextWriteProvider);
    final failure = ref.read(failNextWriteProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsHeading('Developer'),
        const SizedBox(height: AppSpacing.s4),
        Text(
          helper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: scheme.outline,
            radius: AppRadius.r12,
          ),
          child: Material(
            color: AppPalette.of(context).card,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(AppRadius.r12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SettingsRow(
                  title: 'Load demo data',
                  subtitle: loadSubtitle,
                  titleColor: scheme.primary,
                  onTap: () => unawaited(_loadDemoData(context, ref)),
                  showDivider: true,
                ),
                SettingsRow(
                  title: 'Clear all data',
                  subtitle: clearSubtitle,
                  titleColor: scheme.error,
                  onTap: () => unawaited(_clearAll(context, ref)),
                  showDivider: true,
                ),
                SettingsRow(
                  title: 'Fail the next save',
                  subtitle: failSubtitle,
                  control: Switch(
                    value: failNextWrite,
                    onChanged: (armed) => failure.set(armed: armed),
                  ),
                  onTap: () => failure.set(armed: !failNextWrite),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadDemoData(BuildContext context, WidgetRef ref) async {
    final seed = ref.read(demoSeederProvider);
    final messenger = ScaffoldMessenger.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // A second tap is harmless: the seeder adds nothing once expenses exist.
    String message;
    try {
      final added = await seed();
      message = added == 0 ? alreadyHasData : loaded(added);
    } on AppError catch (error) {
      message = error.message;
    }
    showReplacingSnackBar(
      messenger,
      SnackBar(content: Text(message)),
      reduceMotion: reduceMotion,
    );
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    // Read before the dialog: this screen may be gone when it closes.
    final repository = ref.read(expenseRepositoryProvider);
    final filters = ref.read(expenseFiltersProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!await _confirmClearAll(context)) return;

    String message;
    try {
      await repository.clearAll();
      // A filter on a deleted category would hide every new expense, with
      // no chip on Expenses to say why.
      filters.setCategory(null);
      message = cleared;
    } on AppError catch (error) {
      message = error.message;
    }
    showReplacingSnackBar(
      messenger,
      SnackBar(content: Text(message)),
      reduceMotion: reduceMotion,
    );
  }

  /// True means clear.
  Future<bool> _confirmClearAll(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      animationStyle: dialogAnimation(context),
      builder: (context) => AlertDialog(
        title: const Text(clearTitle),
        content: const Text(clearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    return clear ?? false;
  }
}
