import 'package:event_tracker/domain/date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateInterval', () {
    test('compares by value', () {
      expect(
        DateInterval(
          start: DateTime(2026, 1, 1),
          endExclusive: DateTime(2026, 1, 2),
        ),
        DateInterval(
          start: DateTime(2026, 1, 1),
          endExclusive: DateTime(2026, 1, 2),
        ),
      );
    });

    test('includes start and excludes end', () {
      final interval = DateInterval(
        start: DateTime(2026, 1, 1),
        endExclusive: DateTime(2026, 1, 2),
      );

      expect(interval.contains(DateTime(2026, 1, 1)), isTrue);
      expect(interval.contains(DateTime(2026, 1, 1, 23, 59, 59)), isTrue);
      expect(interval.contains(DateTime(2026, 1, 2)), isFalse);
    });

    test('allows an empty interval and rejects a reversed interval', () {
      final instant = DateTime(2026, 1, 1);
      expect(
        DateInterval(start: instant, endExclusive: instant).contains(instant),
        isFalse,
      );
      expect(
        () => DateInterval(
          start: DateTime(2026, 1, 2),
          endExclusive: DateTime(2026, 1, 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('CalendarDateRange', () {
    test('normalizes inputs and includes every instant on the last day', () {
      final range = CalendarDateRange(
        firstDay: DateTime(2026, 1, 1, 12),
        lastDay: DateTime(2026, 1, 2, 18),
      );

      expect(range.firstDay, DateTime(2026, 1, 1));
      expect(range.lastDay, DateTime(2026, 1, 2));
      expect(range.contains(DateTime(2026, 1, 2, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 1, 3)), isFalse);
      expect(range.interval.endExclusive, DateTime(2026, 1, 3));
    });

    test('recent days returns the requested inclusive day count', () {
      final range = CalendarDateRange.recentDays(
        endingOn: DateTime(2026, 7, 9, 19),
        dayCount: 7,
      );

      expect(range.firstDay, DateTime(2026, 7, 3));
      expect(range.lastDay, DateTime(2026, 7, 9));
    });

    test('calendar day shifts preserve local midnight across DST', () {
      final range = CalendarDateRange.recentDays(
        endingOn: DateTime(2026, 3, 10, 18),
        dayCount: 3,
      );

      expect(range.firstDay, DateTime(2026, 3, 8));
      expect(range.lastDay, DateTime(2026, 3, 10));
      expect(range.interval.endExclusive, DateTime(2026, 3, 11));
    });

    test('rejects reversed ranges and non-positive recent day counts', () {
      expect(
        () => CalendarDateRange(
          firstDay: DateTime(2026, 1, 2),
          lastDay: DateTime(2026, 1, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => CalendarDateRange.recentDays(
          endingOn: DateTime(2026, 1, 1),
          dayCount: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
