import 'package:event_tracker/domain/activity_aggregate_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain records add one occurrence and optional value', () {
    final totals = ActivityAggregateTotals(
      sumTime: const Duration(seconds: 4),
      sumValue: 10,
    ).addPlainRecord(value: 3);

    expect(totals.sumTime, const Duration(seconds: 5));
    expect(totals.sumValue, 13);
  });

  test('timed records add duration and optional value', () {
    final totals = ActivityAggregateTotals(
      sumTime: const Duration(minutes: 10),
      sumValue: 2,
    ).addTimedRecord(duration: const Duration(minutes: 25), value: 4);

    expect(totals.sumTime, const Duration(minutes: 35));
    expect(totals.sumValue, 6);
  });

  test('timed record duration fails fast when negative', () {
    expect(
      () => ActivityAggregateTotals(
        sumTime: Duration.zero,
        sumValue: 0,
      ).addTimedRecord(duration: const Duration(seconds: -1)),
      throwsArgumentError,
    );
  });

  test('snapshot rebuilds aggregate totals from completed records', () {
    final snapshot = ActivityAggregateSnapshot.fromCompletedRecords([
      ActivityAggregateRecord(
        id: 1,
        endTime: DateTime(2026, 1, 1, 8),
        value: 3,
      ),
      ActivityAggregateRecord(
        id: 2,
        startTime: DateTime(2026, 1, 1, 9),
        endTime: DateTime(2026, 1, 1, 9, 20),
        value: 4,
      ),
    ]);

    expect(snapshot.lastRecordId, 2);
    expect(snapshot.sumTime, const Duration(minutes: 20, seconds: 1));
    expect(snapshot.sumValue, 7);
  });

  test('snapshot uses latest end time for last record', () {
    final snapshot = ActivityAggregateSnapshot.fromCompletedRecords([
      ActivityAggregateRecord(
        id: 1,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 10),
      ),
      ActivityAggregateRecord(
        id: 2,
        startTime: DateTime(2026, 1, 1, 9),
        endTime: DateTime(2026, 1, 1, 9, 30),
      ),
    ]);

    expect(snapshot.lastRecordId, 1);
  });

  test('completed record duration fails fast when negative', () {
    final record = ActivityAggregateRecord(
      id: 1,
      startTime: DateTime(2026, 1, 1, 9),
      endTime: DateTime(2026, 1, 1, 8),
    );

    expect(() => record.contribution, throwsArgumentError);
  });
}
