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
    onCancel: () async {
      await subscription?.cancel();
      await controller.close();
    },
  );
  return controller.stream;
}
