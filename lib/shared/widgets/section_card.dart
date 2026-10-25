import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_palette.dart';
import 'package:traccash/app/theme/app_spacing.dart';

/// The card surface with a 1px border, clipping its child to the corners.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(AppRadius.r12);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppPalette.of(context).card,
        borderRadius: radius,
      ),
      // In front, so rows that paint their own background don't hide it.
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: radius,
      ),
      padding: padding,
      child: child,
    );
  }
}
