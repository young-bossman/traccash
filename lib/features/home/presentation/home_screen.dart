import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';

/// Placeholder until the Home task builds the real screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Semantics(
            header: true,
            child: Text('Home', style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
      ),
    );
  }
}
