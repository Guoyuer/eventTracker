import 'package:event_tracker/heatmap_calendar/heatmap_calendar_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildHeatMapCalendarModel', () {
    test('normalizes dates and maps values to heatmap levels', () {
      final model = buildHeatMapCalendarModel(
        start: DateTime(2026, 1, 1, 13, 30),
        end: DateTime(2026, 1, 3, 23, 59),
        input: {DateTime(2026, 1, 1, 8): 1, DateTime(2026, 1, 3, 9): 10},
        maxLevel: 4,
      );

      expect(model.start, DateTime(2026, 1, 1));
      expect(model.end, DateTime(2026, 1, 3));
      expect(model.valuesByDate, {
        DateTime(2026, 1, 1): 1,
        DateTime(2026, 1, 3): 10,
      });

      final month = model.years.single.months.single;
      final days = month.weeks.single.days;
      expect(days.take(4).every((day) => day.isPlaceholder), isTrue);
      expect(days[4].date, DateTime(2026, 1, 1));
      expect(days[4].level, 1);
      expect(days[5].date, DateTime(2026, 1, 2));
      expect(days[5].level, 0);
      expect(days[6].date, DateTime(2026, 1, 3));
      expect(days[6].level, 4);
    });

    test('keeps Sunday-start ranges in the current week column', () {
      final model = buildHeatMapCalendarModel(
        start: DateTime(2026, 1, 4),
        end: DateTime(2026, 1, 5),
        input: {},
        maxLevel: 4,
      );

      final days = model.years.single.months.single.weeks.single.days;
      expect(days[0].date, DateTime(2026, 1, 4));
      expect(days[1].date, DateTime(2026, 1, 5));
      expect(days.skip(2).every((day) => day.isPlaceholder), isTrue);
    });

    test('splits ranges across years and months', () {
      final model = buildHeatMapCalendarModel(
        start: DateTime(2025, 12, 31),
        end: DateTime(2026, 1, 1),
        input: {},
        maxLevel: 4,
      );

      expect(model.years, hasLength(2));
      expect(model.years[0].months.single.start, DateTime(2025, 12, 31));
      expect(model.years[1].months.single.end, DateTime(2026, 1, 1));
    });

    test('adds a visual spacer week when a full month ends on Saturday', () {
      final model = buildHeatMapCalendarModel(
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 28),
        input: {},
        maxLevel: 4,
      );

      final weeks = model.years.single.months.single.weeks;
      expect(weeks, hasLength(5));
      expect(weeks.last.days.every((day) => day.isPlaceholder), isTrue);
    });

    test('rejects reversed ranges', () {
      expect(
        () => buildHeatMapCalendarModel(
          start: DateTime(2026, 1, 2),
          end: DateTime(2026, 1, 1),
          input: {},
          maxLevel: 4,
        ),
        throwsArgumentError,
      );
    });
  });
}
