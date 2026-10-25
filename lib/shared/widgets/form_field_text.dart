import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';

/// The label above a form field, with optional text at the end ("Optional").
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {this.trailing, super.key});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final trailing = this.trailing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
      ],
    );
  }
}

/// An inline validation message. The icon means the problem is not shown by
/// colour alone.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: AppSizes.inlineIcon, color: color),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
