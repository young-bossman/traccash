/// `Food`, `Food and Transport`, `Food, Transport and Bills`: names in a
/// sentence.
String joinWithAnd(List<String> items) {
  if (items.length < 2) return items.join();
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}
