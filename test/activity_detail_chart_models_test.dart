import 'package:event_tracker/analytics/activity_detail_chart_models.dart';
import 'package:event_tracker/analytics/activity_detail_analytics.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detail chart model builds labels, heatmap, and two-hour bars', () {
    final activity = PlainEventModel(1, 'Read', 'pages', 0);
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
    expect(model.metricLabels, ['次数', 'pages']);
    expect(model.selectedMetricLabel, 'pages');
    expect(model.visibleRecordCount, 2);
    expect(model.recordCountHeading, '1月共进行');
    expect(model.heatmapSeries.data[DateTime(2026, 1, 1)], 25);
    expect(model.timeSlotBars, hasLength(12));
    expect(model.timeSlotBars[4].x, 8);
    expect(model.timeSlotBars[4].value, 25);
    expect(model.maxTimeSlotValue, 25);
  });

  test('record labels match timed and plain activity display text', () {
    final timed = TimingEventModel(
      1,
      'Run',
      'km',
      EventStatus.notActive,
      Duration.zero,
    );
    final plain = PlainEventModel(2, 'Read', 'pages', 0);
    final timedRecord = ActivityRecord(
      id: 1,
      eventId: 1,
      startTime: DateTime(2026, 1, 1, 8),
      endTime: DateTime(2026, 1, 1, 8, 30),
      value: 4,
    );
    final plainRecord = ActivityRecord(
      id: 2,
      eventId: 2,
      endTime: DateTime(2026, 1, 1, 9),
      value: 12,
    );

    expect(
      activityRecordLabel(activity: timed, record: timedRecord),
      '01-01 08:00 ~ 01-01 08:30, 4km  ',
    );
    expect(
      activityRecordLabel(activity: plain, record: plainRecord),
      '09:00, 12pages  ',
    );
  });
}

ActivityRecord record({
  required int id,
  required DateTime end,
  double? value,
}) {
  return ActivityRecord(
    id: id,
    eventId: 1,
    endTime: end,
    value: value,
  );
}
