import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';

/// Placeholder until the Add / edit task builds the real form.
class ExpenseFormScreen extends StatelessWidget {
  const ExpenseFormScreen({this.expenseId, super.key});

  /// Null when adding a new expense.
  final int? expenseId;

  @override
  Widget build(BuildContext context) {
    final editing = expenseId != null;
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(editing ? 'Edit expense' : 'Add expense'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Text(
          editing ? 'Expense $expenseId' : 'New expense',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
