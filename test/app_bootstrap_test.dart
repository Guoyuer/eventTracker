import 'package:event_tracker/bootstrap/app_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('platform bootstrap decisions', () {
    test('Firebase is initialized only where options exist', () {
      expect(supportsFirebaseOnPlatform(TargetPlatform.android, isWeb: false),
          isTrue);
      expect(
          supportsFirebaseOnPlatform(TargetPlatform.iOS, isWeb: false), isTrue);
      expect(supportsFirebaseOnPlatform(TargetPlatform.windows, isWeb: false),
          isFalse);
      expect(supportsFirebaseOnPlatform(TargetPlatform.linux, isWeb: false),
          isFalse);
      expect(supportsFirebaseOnPlatform(TargetPlatform.macOS, isWeb: false),
          isFalse);
      expect(supportsFirebaseOnPlatform(TargetPlatform.windows, isWeb: true),
          isTrue);
    });

    test('sqflite ffi is used on desktop platforms', () {
      expect(usesSqfliteFfiOnPlatform(TargetPlatform.windows), isTrue);
      expect(usesSqfliteFfiOnPlatform(TargetPlatform.linux), isTrue);
      expect(usesSqfliteFfiOnPlatform(TargetPlatform.macOS), isTrue);
      expect(usesSqfliteFfiOnPlatform(TargetPlatform.android), isFalse);
      expect(usesSqfliteFfiOnPlatform(TargetPlatform.iOS), isFalse);
      expect(usesSqfliteFfiOnPlatform(TargetPlatform.fuchsia), isFalse);
    });
  });
}
