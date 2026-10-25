import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/data/database/demo_seed.dart';

/// Placeholder until the Settings task builds the real screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Temporary; T8's Developer section replaces it.
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.s20),
                const _LoadDemoDataButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadDemoDataButton extends ConsumerWidget {
  const _LoadDemoDataButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonal(
      onPressed: () => _load(context, ref),
      child: const Text('Load demo data'),
    );
  }

  Future<void> _load(BuildContext context, WidgetRef ref) async {
    String message;
    try {
      final added = await ref.read(demoSeederProvider)();
      message = added == 0
          ? 'Demo data not loaded: there are already expenses.'
          : 'Loaded $added demo expenses.';
    } on AppError catch (error) {
      message = error.message;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
