import 'package:event_tracker/analytics/statistics_chart_models.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chart model builds pie slices and stacked time slots', () {
    final model = buildStatisticsChartModel(
      records: [
        record(id: 1, eventId: 2, end: DateTime(2026, 1, 1, 8)),
        record(id: 2, eventId: 1, end: DateTime(2026, 1, 1, 9)),
        record(id: 3, eventId: 2, end: DateTime(2026, 1, 1, 9)),
      ],
      activitiesById: {
        1: activity(id: 1, name: 'Read'),
        2: activity(id: 2, name: 'Run'),
      },
      colorCount: 10,
    );

    expect(model.totalCount, 3);
    expect(model.pieSlices.map((slice) => slice.activityName), ['Run', 'Read']);
    expect(model.pieSlices.map((slice) => slice.count), [2, 1]);
    expect(model.pieSlices.map((slice) => slice.colorIndex), [2, 1]);

    final hourNine = model.landscapeSlots.bars[9];
    expect(hourNine.x, 9);
    expect(hourNine.total, 2);
    expect(hourNine.segments.map((segment) => segment.activityName), [
      'Run',
      'Read',
    ]);
    expect(hourNine.segments.map((segment) => segment.fromY), [0, 1]);
    expect(hourNine.segments.map((segment) => segment.toY), [1, 2]);
    expect(model.landscapeSlots.maxY, 2);
  });

  test('chart model builds twelve portrait two-hour slots', () {
    final model = buildStatisticsChartModel(
      records: [
        record(id: 1, eventId: 1, end: DateTime(2026, 1, 1, 8)),
        record(id: 2, eventId: 1, end: DateTime(2026, 1, 1, 9)),
      ],
      activitiesById: {1: activity(id: 1, name: 'Read')},
      colorCount: 10,
    );

    expect(model.portraitSlots.bars, hasLength(12));
    expect(model.portraitSlots.bars[4].x, 8);
    expect(model.portraitSlots.bars[4].total, 2);
    expect(model.portraitSlots.maxY, 2);
  });
}

StatisticsActivity activity({required int id, required String name}) {
  return StatisticsActivity(id: id, name: name);
}

ActivityRecord record({
  required int id,
  required int eventId,
  required DateTime end,
}) {
  return PlainRecord(id: id, activityId: eventId, endedAt: end);
}
