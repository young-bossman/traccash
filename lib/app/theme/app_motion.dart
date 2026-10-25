/// Durations from DESIGN_SPEC §7.
///
/// Anything that moves reads `MediaQuery.disableAnimationsOf(context)` first
/// and skips the motion when the device asks for reduced motion.
abstract final class AppMotion {
  /// The add / edit form sliding up over the tabs.
  static const Duration formSlide = Duration(milliseconds: 200);

  /// Scrolling a field error or the error banner into view.
  static const Duration reveal = Duration(milliseconds: 200);

  /// Chart bars growing or shrinking to new totals. fl_chart's own default;
  /// not in the spec.
  static const Duration chartUpdate = Duration(milliseconds: 150);
}
