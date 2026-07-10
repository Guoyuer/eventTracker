import 'package:event_tracker/bootstrap/error_boundary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlutterExceptionHandler? originalFlutterErrorHandler;

  setUp(() {
    originalFlutterErrorHandler = FlutterError.onError;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterErrorHandler;
  });

  test(
    'runGuarded reports and completes with an unhandled asynchronous error',
    () async {
      final reported = <Object>[];

      await expectLater(
        runGuarded(
          () async => throw StateError('boom'),
          onError: (error, _) => reported.add(error),
        ),
        throwsStateError,
      );

      expect(reported, [isA<StateError>()]);
    },
  );

  test(
    'runGuarded routes framework errors through the same reporter',
    () async {
      final reported = <Object>[];

      await runGuarded(() async {
        FlutterError.reportError(
          FlutterErrorDetails(exception: ArgumentError('invalid input')),
        );
      }, onError: (error, _) => reported.add(error));

      expect(reported, [isA<ArgumentError>()]);
    },
  );
}
