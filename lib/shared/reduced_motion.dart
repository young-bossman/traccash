import 'package:flutter/material.dart';

/// No fade under reduced motion; Flutter's default otherwise. For every
/// dialog the app opens, the date picker included.
AnimationStyle? dialogAnimation(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ? AnimationStyle.noAnimation : null;

/// Replaces whatever snackbar is showing, so feedback is about the latest
/// action. It slides in unless [reduceMotion] is set.
void showReplacingSnackBar(
  ScaffoldMessengerState messenger,
  SnackBar snackBar, {
  required bool reduceMotion,
}) {
  if (!messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      snackBar,
      snackBarAnimationStyle: reduceMotion ? AnimationStyle.noAnimation : null,
    );
}
