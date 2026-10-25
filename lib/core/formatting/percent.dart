/// Tenths of a percent as `33.2%`, with integers only, so a set of shares
/// that totals 1000 always reads as 100.0% in total.
///
/// [tenths] must not be negative.
String formatShare(int tenths) {
  assert(tenths >= 0, 'formatShare takes a non-negative share');
  return '${tenths ~/ 10}.${tenths % 10}%';
}
