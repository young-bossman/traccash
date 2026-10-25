import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_typography.dart';
import 'package:traccash/core/formatting/money.dart';

/// A month's total, `GH₵ 2,313.90`, with the cedis large and the symbol and
/// pesewas smaller (DESIGN_SPEC §4 "Monthly total").
class TotalAmount extends StatelessWidget {
  const TotalAmount({required this.pesewas, super.key});

  final int pesewas;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minor = AppTypography.totalMinor.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final parts = splitGhs(pesewas);

    // The label stays the whole amount even when the figure is scaled down.
    return Semantics(
      label: formatGhs(pesewas),
      excludeSemantics: true,
      // Align loosens the column's fixed width, so the FittedBox keeps the
      // text's height and only shrinks it when the amount is too wide.
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$ghsSymbol ', style: minor),
                TextSpan(
                  text: parts.cedis,
                  style: AppTypography.displaySmall.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                TextSpan(text: parts.pesewas, style: minor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
