import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/errors/app_error.dart';
import 'package:traccash/features/expenses/presentation/expense_form.dart';
import 'package:traccash/features/expenses/presentation/expenses_providers.dart';
import 'package:traccash/shared/widgets/empty_state.dart';

/// The full-screen add / edit route. Adding opens the empty form at once;
/// editing first loads the stored expense.
class ExpenseFormScreen extends ConsumerWidget {
  const ExpenseFormScreen({this.expenseId, super.key});

  /// Null when adding a new expense.
  final int? expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = expenseId;
    if (id == null) return const ExpenseForm();

    return switch (ref.watch(expenseByIdProvider(id))) {
      AsyncData(value: final expense?) => ExpenseForm(expense: expense),
      // Deleted elsewhere, or a stale link.
      AsyncData() => _Unavailable(
        title: 'Expense not found',
        message: const ExpenseNotFoundError().message,
        action: FilledButton.tonal(
          onPressed: () => context.pop(),
          child: const Text('Close'),
        ),
      ),
      AsyncError(:final error) => _Unavailable(
        title: 'Couldn’t load this expense',
        message: error is AppError
            ? error.message
            : const StorageError().message,
        action: FilledButton.tonal(
          onPressed: () => ref.invalidate(expenseByIdProvider(id)),
          child: const Text('Try again'),
        ),
      ),
      _ => const _EditShell(
        child: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading expense'),
        ),
      ),
    };
  }
}

/// The edit route's app bar around a loading or problem state.
class _EditShell extends StatelessWidget {
  const _EditShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Edit expense'),
      ),
      body: child,
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.title,
    required this.message,
    required this.action,
  });

  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return _EditShell(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: title,
            message: message,
            action: action,
          ),
        ),
      ),
    );
  }
}
