import 'package:event_tracker/analytics/statistics_analytics.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('statistics summary counts records per activity in record order', () {
    final eventsById = {
      1: event(id: 1, name: 'Read'),
      2: event(id: 2, name: 'Run'),
    };
    final records = [
      record(id: 1, eventId: 2, end: DateTime(2026, 1, 1, 8)),
      record(id: 2, eventId: 1, end: DateTime(2026, 1, 1, 9)),
      record(id: 3, eventId: 2, end: DateTime(2026, 1, 1, 10)),
    ];

    final summary = buildStatisticsSummary(
      records: records,
      eventsById: eventsById,
    );

    expect(summary.totalCount, 3);
    expect(summary.activityCounts.map((count) => count.activity.name), [
      'Run',
      'Read',
    ]);
    expect(summary.activityCounts.map((count) => count.count), [2, 1]);
  });

  test('statistics summary groups hourly counts by activity name', () {
    final eventsById = {
      1: event(id: 1, name: 'Read'),
      2: event(id: 2, name: 'Run'),
    };
    final records = [
      record(id: 1, eventId: 1, end: DateTime(2026, 1, 1, 8, 30)),
      record(id: 2, eventId: 1, end: DateTime(2026, 1, 1, 8, 45)),
      record(id: 3, eventId: 2, end: DateTime(2026, 1, 1, 9)),
    ];

    final summary = buildStatisticsSummary(
      records: records,
      eventsById: eventsById,
    );

    expect(summary.hourlyCountsByActivityName['Read']![8], 2);
    expect(summary.hourlyCountsByActivityName['Run']![9], 1);
    expect(summary.hourlyCountsByActivityName['Run']![8], 0);
  });

  test(
    'statistics summary fails fast on dangling record activity references',
    () {
      expect(
        () => buildStatisticsSummary(
          records: [record(id: 1, eventId: 404, end: DateTime(2026, 1, 1))],
          eventsById: {},
        ),
        throwsStateError,
      );
    },
  );

  test('adjacent hour grouping returns twelve two-hour slots', () {
    expect(
      combineStatisticsAdjacentHourSlots([
        for (var i = 0; i < 24; i++) i.toDouble(),
      ]),
      [for (var i = 0; i < 12; i++) (i * 2 + i * 2 + 1).toDouble()],
    );
  });
}

StatisticsActivity event({required int id, required String name}) {
  return StatisticsActivity(id: id, name: name);
}

ActivityRecord record({
  required int id,
  required int eventId,
  required DateTime end,
}) {
  return ActivityRecord(id: id, eventId: eventId, endTime: end);
}
