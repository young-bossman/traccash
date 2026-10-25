import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traccash/core/errors/app_error.dart';

/// Debug only: Settings' "Fail the next save" switch. While on, the next
/// write through any repository throws [StorageError] without writing, so
/// the error paths can be checked by hand on a device.
final NotifierProvider<FailNextWriteNotifier, bool> failNextWriteProvider =
    NotifierProvider<FailNextWriteNotifier, bool>(FailNextWriteNotifier.new);

class FailNextWriteNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool armed}) => state = armed;

  /// True once after the switch was turned on, which also turns it off.
  bool take() {
    if (!state) return false;
    state = false;
    return true;
  }
}

/// What a Drift repository calls before each write. Null unless [debug], so
/// release builds have nothing that could fail a write on purpose.
bool Function()? simulatedFailureHook(Ref ref, {bool debug = kDebugMode}) =>
    debug ? ref.read(failNextWriteProvider.notifier).take : null;

/// Throws [StorageError] when [hook] reports an armed failure.
void throwIfSimulated(bool Function()? hook) {
  if (hook?.call() ?? false) throw const StorageError();
}
