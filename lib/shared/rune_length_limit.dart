import 'dart:math' as math;

// Also brings in package:characters, which flutter/widgets re-exports.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flutter's [LengthLimitingTextInputFormatter], counting code points (runes)
/// instead of grapheme clusters.
///
/// The repository and SQLite's `length()` count code points, while
/// `maxLength` counts what the user sees as characters, so an emoji-heavy
/// note could pass the field and then fail on save. Behaves like Flutter's
/// formatter on Android: typing at the limit is ignored, and longer input
/// (a paste) is cut at the limit. A cut keeps whole characters only, so an
/// emoji is never left half there.
class RuneLengthLimitingTextInputFormatter extends TextInputFormatter {
  const RuneLengthLimitingTextInputFormatter(this.maxRunes)
    : assert(maxRunes > 0, 'maxRunes must be positive');

  final int maxRunes;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= maxRunes) return newValue;
    // Already full, with nothing selected to replace: ignore the extra input.
    if (oldValue.text.runes.length >= maxRunes &&
        oldValue.selection.isCollapsed) {
      return oldValue;
    }
    return truncate(newValue, maxRunes);
  }

  /// [value] cut to the longest run of whole characters from the start whose
  /// code points fit in [maxRunes], with selection and composing clamped.
  @visibleForTesting
  static TextEditingValue truncate(TextEditingValue value, int maxRunes) {
    var runes = 0;
    // A UTF-16 offset, which is what String and TextSelection use.
    var end = 0;
    for (final character in value.text.characters) {
      final size = character.runes.length;
      if (runes + size > maxRunes) break;
      runes += size;
      end += character.length;
    }
    final truncated = value.text.substring(0, end);

    return TextEditingValue(
      text: truncated,
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, end),
        extentOffset: math.min(value.selection.end, end),
      ),
      composing: !value.composing.isCollapsed && end > value.composing.start
          ? TextRange(
              start: value.composing.start,
              end: math.min(value.composing.end, end),
            )
          : TextRange.empty,
    );
  }
}

/// A `TextField.buildCounter` showing `N / max`, counted in code points like
/// [RuneLengthLimitingTextInputFormatter].
///
/// Flutter's `currentLength` counts grapheme clusters, so the count is read
/// from [controller] instead.
InputCounterWidgetBuilder runeCounter(
  TextEditingController controller,
  int maxRunes,
) {
  return (context, {required currentLength, required isFocused, maxLength}) {
    final theme = Theme.of(context);
    final count = controller.text.runes.length;
    return Semantics(
      label: '$count of $maxRunes characters used',
      excludeSemantics: true,
      child: Text(
        '$count / $maxRunes',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  };
}
