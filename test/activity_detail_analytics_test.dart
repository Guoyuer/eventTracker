import 'package:event_tracker/analytics/activity_detail_analytics.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selection maps to the expected activity detail metric', () {
    final timed = InactiveTimedActivity(
      id: 1,
      name: 'Run',
      unit: 'km',
      totalDuration: Duration.zero,
      totalValue: 0,
    );
    final plain = PlainActivity(
      id: 2,
      name: 'Read',
      unit: 'pages',
      occurrenceCount: 0,
      totalValue: 0,
    );

    expect(metricForActivitySelection(timed, 0), ActivityDetailMetric.duration);
    expect(metricForActivitySelection(timed, 1), ActivityDetailMetric.value);
    expect(metricForActivitySelection(plain, 0), ActivityDetailMetric.count);
    expect(metricForActivitySelection(plain, 1), ActivityDetailMetric.value);
  });

  test(
    'heatmap series aggregates timed activity duration by day in minutes',
    () {
      final activity = InactiveTimedActivity(
        id: 1,
        name: 'Run',
        totalDuration: Duration.zero,
        totalValue: 0,
      );
      final records = [
        record(
          id: 1,
          start: DateTime(2026, 1, 1, 8),
          end: DateTime(2026, 1, 1, 8, 20),
        ),
        record(
          id: 2,
          start: DateTime(2026, 1, 1, 9),
          end: DateTime(2026, 1, 1, 9, 10),
        ),
        record(
          id: 3,
          start: DateTime(2026, 1, 2, 9),
          end: DateTime(2026, 1, 2, 9, 5),
        ),
      ];

      final series = buildActivityHeatmapSeries(
        records: records,
        activity: activity,
        metric: ActivityDetailMetric.duration,
        now: DateTime(2026, 1, 5, 12),
      );

      expect(series.range.firstDay, DateTime(2026, 1, 1));
      expect(series.range.lastDay, DateTime(2026, 1, 5));
      expect(series.data, {DateTime(2026, 1, 1): 30, DateTime(2026, 1, 2): 5});
    },
  );

  test('heatmap series aggregates plain activity count and value by day', () {
    final activity = PlainActivity(
      id: 1,
      name: 'Read',
      unit: 'pages',
      occurrenceCount: 0,
      totalValue: 0,
    );
    final records = [
      record(id: 1, end: DateTime(2026, 1, 1, 8), value: 10),
      record(id: 2, end: DateTime(2026, 1, 1, 9), value: 15),
      record(id: 3, end: DateTime(2026, 1, 2, 9), value: 7),
    ];

    final countSeries = buildActivityHeatmapSeries(
      records: records,
      activity: activity,
      metric: ActivityDetailMetric.count,
      now: DateTime(2026, 1, 5),
    );
    final valueSeries = buildActivityHeatmapSeries(
      records: records,
      activity: activity,
      metric: ActivityDetailMetric.value,
      now: DateTime(2026, 1, 5),
    );

    expect(countSeries.data, {
      DateTime(2026, 1, 1): 2,
      DateTime(2026, 1, 2): 1,
    });
    expect(valueSeries.data, {
      DateTime(2026, 1, 1): 25,
      DateTime(2026, 1, 2): 7,
    });
  });

  test('time slot series splits timed duration across occupied hours', () {
    final activity = InactiveTimedActivity(
      id: 1,
      name: 'Run',
      totalDuration: Duration.zero,
      totalValue: 0,
    );
    final records = [
      record(
        id: 1,
        start: DateTime(2026, 1, 1, 8, 30),
        end: DateTime(2026, 1, 1, 10, 15),
      ),
    ];

    final series = buildActivityTimeSlotSeries(
      records: records,
      activity: activity,
      metric: ActivityDetailMetric.duration,
    );

    expect(series.hourlyValues[8], 30);
    expect(series.hourlyValues[9], 60);
    expect(series.hourlyValues[10], 15);
  });

  test('record filters and adjacent hour slot combining are pure helpers', () {
    final records = [
      record(id: 1, end: DateTime(2026, 1, 1, 8), value: 1),
      record(id: 2, end: DateTime(2026, 1, 2, 8), value: 1),
      record(id: 3, end: DateTime(2026, 2, 1, 8), value: 1),
    ];

    expect(recordsOnDay(records, DateTime(2026, 1, 1)), [records[0]]);
    expect(recordsInMonth(records, DateTime(2026, 1, 20)), [
      records[0],
      records[1],
    ]);
    expect(
      combineAdjacentHourSlots([for (var i = 0; i < 24; i++) i.toDouble()]),
      [for (var i = 0; i < 12; i++) (i * 2 + i * 2 + 1).toDouble()],
    );
  });
}

ActivityRecord record({
  required int id,
  DateTime? start,
  DateTime? end,
  double? value,
}) {
  if (start == null) {
    return PlainRecord(id: id, activityId: 1, endedAt: end!, value: value);
  }
  return CompletedTimedRecord(
    id: id,
    activityId: 1,
    startedAt: start,
    endedAt: end!,
    value: value,
  );
}
