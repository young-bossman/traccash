import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';

/// Neutral square with a monochrome icon. The row beside it names what the
/// icon shows, so the icon is decorative.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppSizes.iconTile,
      height: AppSizes.iconTile,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(AppRadius.r12),
      ),
      child: Icon(
        icon,
        size: AppSizes.iconTileGlyph,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
