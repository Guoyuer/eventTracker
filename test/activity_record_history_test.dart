import 'package:event_tracker/domain/activity_record_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain history counts completed records and values', () {
    final history = ActivityRecordHistory.evaluate(
      activityId: 1,
      careTime: false,
      records: [
        ActivityHistoryRecord(id: 1, endTime: DateTime(2026, 1, 1), value: 3),
        ActivityHistoryRecord(id: 2, endTime: DateTime(2026, 1, 2), value: 4),
      ],
    );

    expect(history.occurrenceCount, 2);
    expect(history.totalDuration, Duration.zero);
    expect(history.totalValue, 7);
    expect(history.activeStartedAt, isNull);
  });

  test('timed history totals completed duration and exposes active start', () {
    final history = ActivityRecordHistory.evaluate(
      activityId: 1,
      careTime: true,
      records: [
        ActivityHistoryRecord(
          id: 1,
          startTime: DateTime(2026, 1, 1, 8),
          endTime: DateTime(2026, 1, 1, 8, 25),
          value: 3,
        ),
        ActivityHistoryRecord(id: 2, startTime: DateTime(2026, 1, 1, 9)),
      ],
    );

    expect(history.occurrenceCount, 0);
    expect(history.totalDuration, const Duration(minutes: 25));
    expect(history.totalValue, 3);
    expect(history.activeStartedAt, DateTime(2026, 1, 1, 9));
  });

  test('plain history rejects timed and active record shapes', () {
    for (final record in [
      ActivityHistoryRecord(
        id: 1,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 9),
      ),
      const ActivityHistoryRecord(id: 2),
    ]) {
      expect(
        () => ActivityRecordHistory.evaluate(
          activityId: 1,
          careTime: false,
          records: [record],
        ),
        throwsStateError,
      );
    }
  });

  test('timed history rejects malformed records', () {
    final malformedRecords = [
      ActivityHistoryRecord(id: 1, endTime: DateTime(2026, 1, 1, 9)),
      ActivityHistoryRecord(
        id: 2,
        startTime: DateTime(2026, 1, 1, 9),
        endTime: DateTime(2026, 1, 1, 8),
      ),
      ActivityHistoryRecord(
        id: 3,
        startTime: DateTime(2026, 1, 1, 9),
        value: 1,
      ),
    ];

    for (final record in malformedRecords) {
      expect(
        () => ActivityRecordHistory.evaluate(
          activityId: 1,
          careTime: true,
          records: [record],
        ),
        throwsStateError,
      );
    }
  });

  test('timed history rejects multiple active records', () {
    expect(
      () => ActivityRecordHistory.evaluate(
        activityId: 1,
        careTime: true,
        records: [
          ActivityHistoryRecord(id: 1, startTime: DateTime(2026, 1, 1, 8)),
          ActivityHistoryRecord(id: 2, startTime: DateTime(2026, 1, 1, 9)),
        ],
      ),
      throwsStateError,
    );
  });
}
