import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';

/// Placeholder until the Reports task builds the real screen.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Semantics(
            header: true,
            child: Text(
              'Reports',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }
}
