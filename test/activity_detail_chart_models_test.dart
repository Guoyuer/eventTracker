import 'package:event_tracker/analytics/activity_detail_chart_models.dart';
import 'package:event_tracker/analytics/activity_detail_analytics.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detail chart model builds labels, heatmap, and two-hour bars', () {
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
      record(id: 3, end: DateTime(2026, 2, 1, 8), value: 7),
    ];

    final model = buildActivityDetailChartModel(
      activity: activity,
      records: records,
      selectedMetricIndex: 1,
      selectedMonth: DateTime(2026, 1, 15),
      now: DateTime(2026, 2, 5),
      combineHourSlots: true,
    );

    expect(model.metric, ActivityDetailMetric.value);
    expect(model.availableMetrics, [
      ActivityDetailMetric.count,
      ActivityDetailMetric.value,
    ]);
    expect(model.visibleRecordCount, 2);
    expect(model.selectedMonth, DateTime(2026, 1, 15));
    expect(model.heatmapSeries.data[DateTime(2026, 1, 1)], 25);
    expect(model.timeSlotBars, hasLength(12));
    expect(model.timeSlotBars[4].x, 8);
    expect(model.timeSlotBars[4].value, 25);
    expect(model.maxTimeSlotValue, 25);
  });

  test('record details preserve typed times, values, and units', () {
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
    final timedRecord = CompletedTimedRecord(
      id: 1,
      activityId: 1,
      startedAt: DateTime(2026, 1, 1, 8),
      endedAt: DateTime(2026, 1, 1, 8, 30),
      value: 4,
    );
    final plainRecord = PlainRecord(
      id: 2,
      activityId: 2,
      endedAt: DateTime(2026, 1, 1, 9),
      value: 12,
    );

    expect(
      activityRecordDetail(activity: timed, record: timedRecord),
      isA<ActivityRecordDetail>()
          .having(
            (detail) => detail.startedAt,
            'startedAt',
            DateTime(2026, 1, 1, 8),
          )
          .having(
            (detail) => detail.endedAt,
            'endedAt',
            DateTime(2026, 1, 1, 8, 30),
          )
          .having((detail) => detail.value, 'value', 4)
          .having((detail) => detail.unit, 'unit', 'km'),
    );
    expect(
      activityRecordDetail(activity: plain, record: plainRecord),
      isA<ActivityRecordDetail>()
          .having((detail) => detail.startedAt, 'startedAt', isNull)
          .having(
            (detail) => detail.endedAt,
            'endedAt',
            DateTime(2026, 1, 1, 9),
          )
          .having((detail) => detail.value, 'value', 12)
          .having((detail) => detail.unit, 'unit', 'pages'),
    );
  });
}

ActivityRecord record({required int id, required DateTime end, double? value}) {
  return PlainRecord(id: id, activityId: 1, endedAt: end, value: value);
}
