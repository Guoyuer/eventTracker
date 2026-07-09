import 'package:event_tracker/domain/date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('date range compares by value', () {
    expect(
      DateRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 2)),
      DateRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 2)),
    );
  });

  test('contains both endpoints', () {
    final range = DateRange(
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 1, 2),
    );

    expect(range.contains(DateTime(2026, 1, 1)), isTrue);
    expect(range.contains(DateTime(2026, 1, 2)), isTrue);
    expect(range.contains(DateTime(2026, 1, 3)), isFalse);
  });

  test('rejects reversed ranges', () {
    expect(
      () => DateRange(start: DateTime(2026, 1, 2), end: DateTime(2026, 1, 1)),
      throwsArgumentError,
    );
  });
}
