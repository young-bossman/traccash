import 'dart:async';

/// A stream that emits [read]'s value when listened to and again after every
/// event on [changes], like a Drift `watch` query.
Stream<T> watchValue<T>(Stream<void> changes, T Function() read) {
  StreamSubscription<void>? subscription;
  late final StreamController<T> controller;
  controller = StreamController<T>(
    onListen: () {
      controller.add(read());
      subscription = changes.listen((_) => controller.add(read()));
    },
    onCancel: () {
      // Neither is awaited: both return Dart's shared completed future, which
      // belongs to the root zone. Awaiting it would resume a widget test
      // outside its fake async zone, where the test then waits forever.
      unawaited(subscription?.cancel());
      unawaited(controller.close());
      // A future of the caller's zone, so `await subscription.cancel()` in a
      // widget test stays inside it too.
      return Future<void>.value();
    },
  );
  return controller.stream;
}
