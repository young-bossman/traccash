import 'package:characters/characters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/shared/rune_length_limit.dart';

/// [text] with the cursor at its end, as after typing or pasting.
TextEditingValue typed(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

TextEditingValue format(
  TextInputFormatter formatter,
  String oldText,
  String newText,
) => formatter.formatEditUpdate(typed(oldText), typed(newText));

void main() {
  const formatter = RuneLengthLimitingTextInputFormatter(5);

  // Rainbow flag: U+1F3F3 U+FE0F U+200D U+1F308. One character on screen,
  // 4 code points, 6 UTF-16 units.
  const flag = '\u{1F3F3}\u{FE0F}\u{200D}\u{1F308}';

  test('the rainbow flag is one character but 4 code points', () {
    expect(flag.characters.length, 1);
    expect(flag.runes.length, 4);
    expect(flag.length, 6);
  });

  group('ASCII', () {
    test('input within the limit passes unchanged', () {
      expect(format(formatter, 'abcd', 'abcde'), typed('abcde'));
    });

    test('typing at the limit keeps the old value', () {
      expect(format(formatter, 'abcde', 'abcdef'), typed('abcde'));
    });

    test('a paste over the limit is cut at the limit', () {
      final result = format(formatter, 'ab', 'abcdefgh');
      expect(result.text, 'abcde');
      expect(result.selection, const TextSelection.collapsed(offset: 5));
    });

    test('replacing a selection at the limit is allowed', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'abcde',
          selection: TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        typed('xyzxyzxyz'),
      );
      expect(result.text, 'xyzxy');
    });
  });

  group('a 4-code-point emoji at the boundary', () {
    test('fits exactly: one letter and the flag are 5 code points', () {
      expect(format(formatter, 'a', 'a$flag'), typed('a$flag'));
    });

    test('one code point over: the whole flag is dropped, never split', () {
      final result = format(formatter, 'ab', 'ab$flag');
      expect(result.text, 'ab');
      expect(result.selection, const TextSelection.collapsed(offset: 2));
    });

    test('a full field ending in the flag ignores more typing', () {
      expect(format(formatter, 'a$flag', 'a${flag}b'), typed('a$flag'));
    });

    test('a pasted run of flags keeps only whole ones', () {
      final result = format(formatter, '', flag * 3);
      expect(result.text, flag);
      expect(result.text.runes.length, 4);
    });
  });

  test('a cut also clamps the composing range', () {
    final result = formatter.formatEditUpdate(
      typed('ab'),
      const TextEditingValue(
        text: 'abcdefg',
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange(start: 2, end: 7),
      ),
    );
    expect(result.text, 'abcde');
    expect(result.composing, const TextRange(start: 2, end: 5));
  });

  test(
    'Flutter’s own formatter would accept 7 code points as 4 characters',
    () {
      // Why this formatter exists: maxLength counts what the user sees.
      final flutter = LengthLimitingTextInputFormatter(
        5,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
      );
      final result = format(flutter, 'aaa', 'aaa$flag');
      expect(result.text.runes.length, 7);
      expect(format(formatter, 'aaa', 'aaa$flag').text, 'aaa');
    },
  );
}
