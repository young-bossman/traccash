import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/core/formatting/money.dart';
import 'package:traccash/shared/widgets/form_field_text.dart';

/// "GH₵" and the amount on one baseline, over a full-width underline.
///
/// Built from a bare TextField rather than an `InputDecoration` prefix,
/// which Flutter hides while the field is empty and unfocused.
class AmountField extends StatefulWidget {
  const AmountField({
    required this.controller,
    required this.autofocus,
    required this.fieldKey,
    this.error,
    super.key,
  });

  final TextEditingController controller;
  final bool autofocus;

  /// Put on the TextField itself, for tests.
  final Key fieldKey;
  final String? error;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  // Owned here only to colour the underline while the field has focus.
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = widget.error;
    final digits = theme.textTheme.displaySmall;
    final lineColor = error != null
        ? scheme.error
        : _focus.hasFocus
        ? scheme.primary
        : scheme.outline;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Amount'),
          const SizedBox(height: AppSpacing.s8),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: lineColor,
                  width: AppSizes.amountUnderline,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      ghsSymbol,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: TextField(
                      key: widget.fieldKey,
                      controller: widget.controller,
                      focusNode: _focus,
                      autofocus: widget.autofocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // Commas still get through so the parser can explain
                      // "12,50" rather than silently dropping the comma.
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                      ],
                      textInputAction: TextInputAction.done,
                      style: digits?.copyWith(color: scheme.onSurface),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: digits?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.s8),
            FieldError(error),
          ],
        ],
      ),
    );
  }
}
