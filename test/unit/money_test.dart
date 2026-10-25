import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/errors/amount_error.dart';
import 'package:traccash/core/formatting/money.dart';

void expectPesewas(String input, int pesewas) {
  expect(parsePesewas(input), ValidAmount(pesewas), reason: 'input "$input"');
}

void expectError(String input, AmountError error) {
  expect(parsePesewas(input), InvalidAmount(error), reason: 'input "$input"');
}

void main() {
  group('parsePesewas accepts', () {
    test('pesewa amounts without floating point drift', () {
      expectPesewas('0.01', 1);
      expectPesewas('0.29', 29);
      expectPesewas('0.50', 50);
      expectPesewas('25.50', 2550);
    });

    test('every two-digit pesewa value exactly', () {
      for (var p = 1; p <= 99; p++) {
        expectPesewas('0.${p.toString().padLeft(2, '0')}', p);
      }
    });

    test('one decimal digit as tens of pesewas', () {
      expectPesewas('25.5', 2550);
      expectPesewas('1,000.5', 100050);
    });

    test('whole cedis and leading zeros', () {
      expectPesewas('25', 2500);
      expectPesewas('007', 700);
      expectPesewas('000.50', 50);
    });

    test('surrounding whitespace', () {
      expectPesewas('  12.50 ', 1250);
    });

    test('correct thousands grouping', () {
      expectPesewas('1,000', 100000);
      expectPesewas('1,000.50', 100050);
      expectPesewas('1,000,000', 100000000);
      expectPesewas('12,345.67', 1234567);
    });

    test('the maximum in both forms', () {
      expectPesewas('1,000,000.00', maxPesewas);
      expectPesewas('1000000', maxPesewas);
    });
  });

  group('parsePesewas rejects', () {
    test('empty input', () {
      expectError('', AmountError.empty);
      expectError('   ', AmountError.empty);
    });

    test('zero', () {
      expectError('0', AmountError.zero);
      expectError('0.00', AmountError.zero);
      expectError('000', AmountError.zero);
    });

    test('amounts over the cap', () {
      expectError('1000000.01', AmountError.overMax);
      expectError('1,000,000.01', AmountError.overMax);
      expectError('1000001', AmountError.overMax);
    });

    test('characters other than digits, dot and comma', () {
      expectError('abc', AmountError.invalidFormat);
      expectError('1 000', AmountError.invalidFormat);
      expectError('₵12', AmountError.invalidFormat);
      expectError('-5', AmountError.invalidFormat);
      expectError('+5', AmountError.invalidFormat);
      expectError('1e3', AmountError.invalidFormat);
    });

    test('a leading, trailing or repeated dot', () {
      expectError('.5', AmountError.invalidFormat);
      expectError('12.', AmountError.invalidFormat);
      expectError('.', AmountError.invalidFormat);
      expectError('1.2.3', AmountError.invalidFormat);
      expectError('1,000.', AmountError.invalidFormat);
    });

    test('more than two decimals', () {
      expectError('1.234', AmountError.tooManyDecimals);
      expectError('12.500', AmountError.tooManyDecimals);
    });

    test('commas that are not thousands grouping', () {
      expectError('12,50', AmountError.misplacedComma);
      expectError('1,00', AmountError.misplacedComma);
      expectError('1000,000', AmountError.misplacedComma);
      expectError('1.000,50', AmountError.misplacedComma);
      expectError('0,500', AmountError.misplacedComma);
      expectError('000,000', AmountError.misplacedComma);
      expectError(',500', AmountError.misplacedComma);
      expectError('1,,000', AmountError.misplacedComma);
      expectError('1,0000', AmountError.misplacedComma);
      expectError(',', AmountError.misplacedComma);
    });
  });

  group('parsePesewas with long input', () {
    test('many significant digits are over the cap', () {
      expectError('9' * 12, AmountError.overMax);
    });

    test('leading zeros do not count towards the digit limit', () {
      expectPesewas('${'0' * 15}1', 100);
    });

    test('exactly 20 characters is still parsed', () {
      final input = '${'0' * 17}1.5';
      expect(input.length, 20);
      expectPesewas(input, 150);
    });

    test('the limit applies after trimming', () {
      expectPesewas('  ${'0' * 17}1.5  ', 150);
    });

    test('more than 20 characters is rejected before anything else', () {
      expectError('1' * 21, AmountError.invalidFormat);
      expectError('9' * 1000, AmountError.invalidFormat);
    });
  });

  group('AmountError messages', () {
    test('match DESIGN_SPEC wording where it defines one', () {
      expect(AmountError.zero.message, 'Amount must be more than GH₵ 0.00.');
      expect(
        AmountError.misplacedComma.message,
        'Use a dot for pesewas, for example 12.50.',
      );
    });

    test('are present for every error', () {
      for (final error in AmountError.values) {
        expect(error.message, isNotEmpty, reason: error.name);
      }
    });
  });

  group('formatGhs', () {
    test('symbol, space, grouped cedis and two pesewa digits', () {
      expect(formatGhs(150000), 'GH₵ 1,500.00');
      expect(formatGhs(231390), 'GH₵ 2,313.90');
      expect(formatGhs(2550), 'GH₵ 25.50');
    });

    test('small amounts', () {
      expect(formatGhs(0), 'GH₵ 0.00');
      expect(formatGhs(1), 'GH₵ 0.01');
      expect(formatGhs(29), 'GH₵ 0.29');
      expect(formatGhs(999), 'GH₵ 9.99');
    });

    test('the maximum single expense', () {
      expect(formatGhs(maxPesewas), 'GH₵ 1,000,000.00');
    });

    test('totals far above the single-expense cap', () {
      // 10,000 expenses at the cap.
      expect(formatGhs(10000 * maxPesewas), 'GH₵ 10,000,000,000.00');
    });

    test('asserts on negative amounts', () {
      expect(() => formatGhs(-1), throwsA(isA<AssertionError>()));
    });

    test('round-trips through parsePesewas', () {
      for (final pesewas in [1, 29, 50, 2550, 100050, 1234567, maxPesewas]) {
        final text = formatGhs(pesewas).replaceFirst('$ghsSymbol ', '');
        expect(parsePesewas(text), ValidAmount(pesewas), reason: text);
      }
    });
  });

  group('splitGhs', () {
    test('splits grouped cedis from the pesewa part', () {
      final parts = splitGhs(231390);
      expect(parts.cedis, '2,313');
      expect(parts.pesewas, '.90');
    });

    test('pads small pesewa values', () {
      final parts = splitGhs(5);
      expect(parts.cedis, '0');
      expect(parts.pesewas, '.05');
    });

    test('asserts on negative amounts', () {
      expect(() => splitGhs(-1), throwsA(isA<AssertionError>()));
    });
  });

  group('formatPesewasForInput', () {
    test('writes cedis and two pesewa digits without grouping', () {
      expect(formatPesewasForInput(18650), '186.50');
      expect(formatPesewasForInput(480000), '4800.00');
      expect(formatPesewasForInput(maxPesewas), '1000000.00');
      expect(formatPesewasForInput(5), '0.05');
    });

    test('reads back as the same amount', () {
      for (final pesewas in [1, 29, 1250, 18650, 480000, maxPesewas]) {
        expect(
          parsePesewas(formatPesewasForInput(pesewas)),
          ValidAmount(pesewas),
        );
      }
    });

    test('asserts on negative amounts', () {
      expect(() => formatPesewasForInput(-1), throwsA(isA<AssertionError>()));
    });
  });
}
