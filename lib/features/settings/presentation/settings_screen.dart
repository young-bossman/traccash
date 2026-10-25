import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/features/settings/presentation/settings_appearance.dart';
import 'package:traccash/features/settings/presentation/settings_developer.dart';
import 'package:traccash/features/settings/presentation/settings_general.dart';

/// Theme choice, app facts, and debug tools in debug builds (16-settings.png).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({this.showDeveloper = kDebugMode, super.key});

  /// Whether the Developer section shows. Release builds never show it;
  /// tests turn it off to see what release users get.
  final bool showDeveloper;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Scrolls once large text makes the page taller than the screen.
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.s28),
            const AppearanceSection(),
            const SizedBox(height: AppSpacing.s28),
            const GeneralSection(),
            if (showDeveloper) ...[
              const SizedBox(height: AppSpacing.s28),
              const DeveloperSection(),
            ],
          ],
        ),
      ),
    );
  }
}
