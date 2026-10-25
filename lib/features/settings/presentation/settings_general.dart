import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/features/settings/presentation/settings_providers.dart';
import 'package:traccash/features/settings/presentation/settings_row.dart';
import 'package:traccash/shared/widgets/section_card.dart';

/// Currency, where the data lives, and the installed version.
class GeneralSection extends ConsumerWidget {
  const GeneralSection({super.key});

  static const String currency =
      'Ghanaian cedi ($ghsSymbol) · fixed in this version';

  // True only while android:allowBackup is false (DECISIONS.md).
  static const String storage =
      'Your expenses are kept in a local database on this phone. TracCash '
      'has no account and does not sync or upload them.';

  static const String versionUnavailable = 'Not available';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = switch (ref.watch(appVersionProvider)) {
      AsyncData(:final value) => value,
      AsyncError() => versionUnavailable,
      // Left blank for the moment the platform takes to answer.
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsHeading('General'),
        const SizedBox(height: AppSpacing.s12),
        SectionCard(
          child: Column(
            children: [
              const SettingsRow(
                icon: Icons.payments_outlined,
                title: 'Currency',
                subtitle: currency,
                showDivider: true,
              ),
              const SettingsRow(
                icon: Icons.shield_outlined,
                title: 'Stored on this device',
                subtitle: storage,
                showDivider: true,
              ),
              SettingsRow(
                icon: Icons.info_outline,
                title: 'Version',
                value: version,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
