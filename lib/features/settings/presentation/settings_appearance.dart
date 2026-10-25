import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/features/settings/data/settings_repository.dart';
import 'package:traccash/features/settings/presentation/settings_providers.dart';
import 'package:traccash/features/settings/presentation/settings_row.dart';
import 'package:traccash/shared/reduced_motion.dart';
import 'package:traccash/shared/text_measure.dart';

/// System / Light / Dark. The selection is always the stored choice: a tap
/// writes it, and the segments change when the database confirms.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  static const String helper =
      'System follows your device’s light or dark setting.';
  static const String loadError =
      'Couldn’t load your theme choice, so TracCash is following your '
      'device.';
  static const String saveError = 'Couldn’t save your theme choice. Try again.';

  static const Map<ThemeMode, String> _labels = {
    ThemeMode.system: 'System',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stored = ref.watch(themeModeProvider);
    final selected = stored.value;
    final failed = stored.hasError && selected == null;
    // Still reading: nothing to show as chosen yet, so nothing to change.
    final waiting = stored.isLoading && !stored.hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsHeading('Appearance'),
        const SizedBox(height: AppSpacing.s12),
        LayoutBuilder(
          builder: (context, constraints) {
            final inRow = _labelsFit(context, constraints.maxWidth);
            return SegmentedButton<ThemeMode>(
              direction: inRow ? Axis.horizontal : Axis.vertical,
              segments: [
                for (final MapEntry(key: mode, value: label) in _labels.entries)
                  ButtonSegment(value: mode, label: Text(label)),
              ],
              selected: {?selected},
              emptySelectionAllowed: selected == null,
              // Stacked, the segments already take the stretched column's
              // width; expanding would also ask for the page's whole height.
              expandedInsets: inRow ? EdgeInsets.zero : null,
              onSelectionChanged: waiting
                  ? null
                  : (choice) {
                      if (choice.isEmpty) return;
                      unawaited(_choose(context, ref, choice.single));
                    },
            );
          },
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          failed ? loadError : helper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: failed
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Whether every label fits on one line, with the check icon, in a third
  /// of [width]. Otherwise the segments stack, so no label breaks mid-word.
  bool _labelsFit(BuildContext context, double width) {
    final style = Theme.of(context).textTheme.labelLarge!;
    final widest = _labels.values
        .map((label) => singleLineWidth(context, label, style))
        .reduce((a, b) => a > b ? a : b);
    return widest + AppSizes.segmentChrome <= width / _labels.length;
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode,
  ) async {
    final repository = ref.read(settingsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    try {
      await repository.setThemeMode(mode);
    } on AppError {
      // The segments still show the stored choice, which didn't change.
      showReplacingSnackBar(
        messenger,
        const SnackBar(content: Text(saveError)),
        reduceMotion: reduceMotion,
      );
    }
  }
}
