import 'package:intl/intl.dart';
import 'package:traccash/core/errors/amount_error.dart';

const String ghsSymbol = 'GH₵';

/// Largest single expense: GH₵ 1,000,000.00.
const int maxPesewas = 100000000;

// Checked before anything else so no step ever works on unbounded input.
const int _maxInputLength = 20;

// maxPesewas is 1,000,000 cedis (7 digits); 8 or more significant digits are
// always over the cap, so they are rejected before int.parse can overflow.
const int _maxCediDigits = 7;

final RegExp _allowedCharacters = RegExp(r'^[0-9.,]+$');

// The first group may not start with 0, so "0,500" is not read as 500.
final RegExp _groupedCedis = RegExp(r'^[1-9]\d{0,2}(,\d{3})+$');

final RegExp _leadingZeros = RegExp(r'^0+');

final NumberFormat _cediGrouping = NumberFormat('#,##0', 'en_GB');

/// The outcome of [parsePesewas]: a [ValidAmount] or an [InvalidAmount].
sealed class AmountParseResult {
  const AmountParseResult();
}

final class ValidAmount extends AmountParseResult {
  const ValidAmount(this.pesewas);

  final int pesewas;

  @override
  bool operator ==(Object other) =>
      other is ValidAmount && other.pesewas == pesewas;

  @override
  int get hashCode => pesewas.hashCode;

  @override
  String toString() => 'ValidAmount($pesewas)';
}

final class InvalidAmount extends AmountParseResult {
  const InvalidAmount(this.error);

  final AmountError error;

  @override
  bool operator ==(Object other) =>
      other is InvalidAmount && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'InvalidAmount(${error.name})';
}

/// Parses user input such as `1,000.50` into integer pesewas.
///
/// Works on the string only, never `double`: `0.29 * 100` is `28.999…`.
/// The dot is the only decimal separator. A comma is accepted only as
/// correct thousands grouping; any other comma is rejected rather than
/// guessed, because some keyboards type `12,50` meaning 12.50.
AmountParseResult parsePesewas(String input) {
  final text = input.trim();
  if (text.isEmpty) return const InvalidAmount(AmountError.empty);
  if (text.length > _maxInputLength || !_allowedCharacters.hasMatch(text)) {
    return const InvalidAmount(AmountError.invalidFormat);
  }

  final dot = text.indexOf('.');
  var cedis = dot == -1 ? text : text.substring(0, dot);
  final fraction = dot == -1 ? null : text.substring(dot + 1);

  if (text.contains(',')) {
    final commaAfterDot = fraction != null && fraction.contains(',');
    if (commaAfterDot || !_groupedCedis.hasMatch(cedis)) {
      return const InvalidAmount(AmountError.misplacedComma);
    }
    cedis = cedis.replaceAll(',', '');
  }

  if (cedis.isEmpty ||
      (fraction != null && (fraction.isEmpty || fraction.contains('.')))) {
    return const InvalidAmount(AmountError.invalidFormat);
  }
  if (fraction != null && fraction.length > 2) {
    return const InvalidAmount(AmountError.tooManyDecimals);
  }

  final significant = cedis.replaceFirst(_leadingZeros, '');
  if (significant.length > _maxCediDigits) {
    return const InvalidAmount(AmountError.overMax);
  }

  final cediValue = significant.isEmpty ? 0 : int.parse(significant);
  // "5" after the dot is 50 pesewas, not 5.
  final pesewaValue = fraction == null
      ? 0
      : int.parse(fraction.padRight(2, '0'));
  final pesewas = cediValue * 100 + pesewaValue;

  if (pesewas == 0) return const InvalidAmount(AmountError.zero);
  if (pesewas > maxPesewas) return const InvalidAmount(AmountError.overMax);
  return ValidAmount(pesewas);
}

/// Formats pesewas as `GH₵ 1,500.00`.
///
/// [pesewas] must not be negative. Callers showing a difference pass its
/// absolute value and word the direction ("less than", "more than").
String formatGhs(int pesewas) {
  assert(pesewas >= 0, 'formatGhs takes a non-negative amount');
  final parts = splitGhs(pesewas);
  return '$ghsSymbol ${parts.cedis}${parts.pesewas}';
}

/// Splits pesewas into grouped cedis and the pesewa part, for the large
/// monthly total that styles them differently: `2,313` and `.90`.
///
/// [pesewas] must not be negative.
({String cedis, String pesewas}) splitGhs(int pesewas) {
  assert(pesewas >= 0, 'splitGhs takes a non-negative amount');
  return (
    cedis: _cediGrouping.format(pesewas ~/ 100),
    pesewas: '.${(pesewas % 100).toString().padLeft(2, '0')}',
  );
}
