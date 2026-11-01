import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Must match `timeout` in dart_test.yaml.
const Duration testTimeout = Duration(seconds: 60);

/// Runs before every test file under test/.
///
/// dart_test.yaml's timeout reaches plain `test`s only: `testWidgets` passes
/// the binding's own timeout (10 minutes) to each test, which replaces it.
/// Without this, a hung widget test would hold CI for 10 minutes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is AutomatedTestWidgetsFlutterBinding) {
    binding.defaultTestTimeout = const Timeout(testTimeout);
  }
  await testMain();
}
