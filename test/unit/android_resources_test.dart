import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/app/theme/app_colors.dart';

// Android's launch screen and launcher icon are drawn before Flutter starts,
// so their colours are hex copies in android/app/src/main/res/. These checks
// fail if a token changes in app_colors.dart and its copy doesn't.
// `flutter test` runs from the project root, so the paths are relative to it.

const String _res = 'android/app/src/main/res';

String _hex(Color colour) =>
    '#${(colour.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
        .toUpperCase();

String? _colourResource(String folder, String name) {
  final xml = File('$_res/$folder/colors.xml').readAsStringSync();
  return RegExp('<color name="$name">(#[0-9A-Fa-f]{6})</color>')
      .firstMatch(xml)
      ?.group(1)
      ?.toUpperCase();
}

void main() {
  test('the launch screen uses the light and dark background tokens', () {
    expect(
      _colourResource('values', 'window_background'),
      _hex(AppColorsLight.bg),
    );
    expect(
      _colourResource('values-night', 'window_background'),
      _hex(AppColorsDark.bg),
    );
  });

  test('the launcher icon is the light accent with an onAccent glyph', () {
    expect(
      _colourResource('values', 'ic_launcher_background'),
      _hex(AppColorsLight.accent),
    );
    final foreground = File('$_res/drawable/ic_launcher_foreground.xml')
        .readAsStringSync();
    final fill = RegExp('android:fillColor="(#[0-9A-Fa-f]{6})"')
        .firstMatch(foreground)
        ?.group(1)
        ?.toUpperCase();
    expect(fill, _hex(AppColorsLight.onAccent));
  });
}
