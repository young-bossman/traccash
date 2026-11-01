import 'text_scale_checks.dart';

// In Ahem, the test font, which is wider than IBM Plex Sans: stricter than a
// device. text_scale_plex_test.dart runs the same checks in Plex, where the
// layouts that switch at a measured width switch where a phone would.
void main() => defineTextScaleTests();
