import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/calculations/chart_scale.dart';
import 'package:traccash/core/formatting/money.dart';

/// The labels at 0, half and the top of an axis that ends at [axisMax].
List<String> _labels(int axisMax) => [
  for (final pesewas in [0, chartAxisIntervalPesewas(axisMax), axisMax])
    formatGhsAxis(pesewas),
];

void main() {
  group('chartAxisMaxPesewas: the smallest 1, 2, 2.5 or 5 × 10ⁿ cedis '
      '(n ≥ 0) at least as large as the largest bar', () {
    test('an empty chart uses GH₵ 1', () {
      expect(chartAxisMaxPesewas(0), 100);
    });

    test('the smallest axis is GH₵ 1, even for a few pesewas', () {
      expect(chartAxisMaxPesewas(1), 100);
      expect(chartAxisMaxPesewas(3), 100);
      expect(chartAxisMaxPesewas(99), 100);
    });

    test('steps through 1, 2, 2.5 and 5 in each power of ten', () {
      const cases = {
        100: 100, // GH₵ 1
        101: 200, // GH₵ 2
        201: 250, // GH₵ 2.50
        251: 500, // GH₵ 5
        501: 1000, // GH₵ 10
        1001: 2000,
        2001: 2500,
        2501: 5000,
        5001: 10000,
        150001: 200000, // GH₵ 2,000
        200001: 250000, // GH₵ 2,500
        250001: 500000, // GH₵ 5,000
      };
      for (final MapEntry(key: largest, value: axis) in cases.entries) {
        expect(chartAxisMaxPesewas(largest), axis, reason: '$largest');
      }
    });

    test('a bar already on a step keeps that step', () {
      for (final step in [100, 200, 250, 500, 1000, 25000, 250000]) {
        expect(chartAxisMaxPesewas(step), step, reason: '$step');
      }
    });

    test('the month in 10-reports-daily-light', () {
      // Biggest day GH₵ 530.50, month GH₵ 2,313.90, September GH₵ 6,571.00.
      expect(chartAxisMaxPesewas(53050), 100000);
      expect(chartAxisMaxPesewas(231390), 250000);
      expect(chartAxisMaxPesewas(657100), 1000000);
    });

    test('large totals', () {
      expect(chartAxisMaxPesewas(100000000), 100000000); // GH₵ 1,000,000
      expect(chartAxisMaxPesewas(100000001), 200000000);
      expect(chartAxisMaxPesewas(3100000000), 5000000000);
    });
  });

  group('chartAxisIntervalPesewas', () {
    test('is half the axis, always a whole number of pesewas', () {
      expect(chartAxisIntervalPesewas(100), 50);
      expect(chartAxisIntervalPesewas(250), 125);
      expect(chartAxisIntervalPesewas(250000), 125000);
    });
  });

  group('axis labels', () {
    test('GH₵ 1: the half is shown in pesewas', () {
      expect(_labels(100), ['GH₵ 0', 'GH₵ 0.50', 'GH₵ 1']);
    });

    test('GH₵ 2', () {
      expect(_labels(200), ['GH₵ 0', 'GH₵ 1', 'GH₵ 2']);
    });

    test('GH₵ 2.50 and its half, GH₵ 1.25, are never rounded', () {
      expect(_labels(250), ['GH₵ 0', 'GH₵ 1.25', 'GH₵ 2.50']);
    });

    test('GH₵ 5', () {
      expect(_labels(500), ['GH₵ 0', 'GH₵ 2.50', 'GH₵ 5']);
    });

    test('whole cedis are grouped', () {
      expect(_labels(250000), ['GH₵ 0', 'GH₵ 1,250', 'GH₵ 2,500']);
      expect(_labels(1000000), ['GH₵ 0', 'GH₵ 5,000', 'GH₵ 10,000']);
      expect(_labels(5000000000), [
        'GH₵ 0',
        'GH₵ 25,000,000',
        'GH₵ 50,000,000',
      ]);
    });
  });
}
