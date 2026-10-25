import 'package:flutter/material.dart';
import 'package:traccash/app/theme/app_spacing.dart';
import 'package:traccash/shared/widgets/icon_tile.dart';

/// A section title on the Settings page, such as "Appearance".
class SettingsHeading extends StatelessWidget {
  const SettingsHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One row of a Settings card: an optional icon tile, a title, an optional
/// explanation under it, and an optional [value] or [control] at the end.
///
/// With an icon, the icon stays beside the title however many lines the
/// explanation takes (16-settings.png); without one, the row centres its
/// control. The row is read as one item by screen readers.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.value,
    this.control,
    this.titleColor,
    this.onTap,
    this.showDivider = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Text at the end of the title line ("0.1.0 (1)"). It wraps under the
  /// title when large text leaves no room beside it.
  final String? value;

  /// A switch or similar, at the end of the row.
  final Widget? control;

  final Color? titleColor;
  final VoidCallback? onTap;

  /// Draws a divider under this row, aligned with the text.
  final bool showDivider;

  static const double _padding = AppSpacing.s16;
  static const double _gap = AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = this.icon;
    final value = this.value;
    final subtitle = this.subtitle;
    final control = this.control;

    final titleText = Text(
      title,
      style: theme.textTheme.bodyLarge?.copyWith(color: titleColor),
    );
    final text = ConstrainedBox(
      // As tall as the icon tile, so one line sits level with its centre.
      constraints: const BoxConstraints(minHeight: AppSizes.iconTile),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value == null)
            titleText
          else
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: _gap,
                children: [
                  titleText,
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (subtitle != null)
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

    Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _padding,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        crossAxisAlignment: icon == null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[IconTile(icon), const SizedBox(width: _gap)],
          Expanded(child: text),
          if (control != null) ...[const SizedBox(width: _gap), control],
        ],
      ),
    );
    if (onTap != null) row = InkWell(onTap: onTap, child: row);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MergeSemantics(child: row),
        if (showDivider)
          Divider(
            indent: icon == null
                ? _padding
                : _padding + AppSizes.iconTile + _gap,
          ),
      ],
    );
  }
}
