import 'package:event_tracker/bootstrap/app_bootstrap.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('platform bootstrap decisions', () {
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
