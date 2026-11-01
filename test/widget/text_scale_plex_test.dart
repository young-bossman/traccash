import 'package:flutter_test/flutter_test.dart';

import 'plex_font.dart';
import 'text_scale_checks.dart';

// The same checks as text_scale_test.dart, in the bundled IBM Plex Sans, so
// the layouts that switch at a measured width switch where a phone would.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadPlex();
  });

  defineTextScaleTests();
}
