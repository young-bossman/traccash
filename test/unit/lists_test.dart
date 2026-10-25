import 'package:flutter_test/flutter_test.dart';
import 'package:traccash/core/formatting/lists.dart';

void main() {
  test('joins names for a sentence', () {
    expect(joinWithAnd(const []), '');
    expect(joinWithAnd(const ['Food']), 'Food');
    expect(joinWithAnd(const ['Food', 'Transport']), 'Food and Transport');
    expect(
      joinWithAnd(const ['Food', 'Transport', 'Bills']),
      'Food, Transport and Bills',
    );
  });
}
