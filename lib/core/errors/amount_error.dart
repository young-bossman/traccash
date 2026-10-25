/// Why an amount typed by the user was rejected.
///
/// The messages live here so the form and the repository report the same
/// wording. DESIGN_SPEC §5 defines [misplacedComma] and [zero].
enum AmountError {
  empty('Enter an amount.'),
  invalidFormat('Enter an amount like 12.50.'),
  tooManyDecimals('Use at most 2 digits after the dot.'),
  misplacedComma('Use a dot for pesewas, for example 12.50.'),
  zero('Amount must be more than GH₵ 0.00.'),
  overMax('Amount must be at most GH₵ 1,000,000.00.');

  const AmountError(this.message);

  /// User-facing text, safe to show under the amount field.
  final String message;
}
