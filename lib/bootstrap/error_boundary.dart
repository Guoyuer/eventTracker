import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs [body] in the application's single unhandled-error boundary.
Future<void> runGuarded(
  Future<void> Function() body, {
  required void Function(Object error, StackTrace stackTrace) onError,
}) {
  final completion = Completer<void>();

  runZonedGuarded(
    () async {
      FlutterError.onError = (details) {
        onError(details.exception, details.stack ?? StackTrace.current);
      };
      await body();
      if (!completion.isCompleted) {
        completion.complete();
      }
    },
    (error, stackTrace) {
      onError(error, stackTrace);
      if (!completion.isCompleted) {
        completion.completeError(error, stackTrace);
      }
    },
  );

  return completion.future;
}
