import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/formatting/percent.dart';

void main() {
  test('tenths of a percent read with one decimal', () {
    expect(formatShare(332), '33.2%');
    expect(formatShare(169), '16.9%');
    expect(formatShare(250), '25.0%');
    expect(formatShare(5), '0.5%');
  });

  test('the ends of the range', () {
    expect(formatShare(0), '0.0%');
    expect(formatShare(1000), '100.0%');
  });
}
