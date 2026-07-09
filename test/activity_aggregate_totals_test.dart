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
    ).addTimedRecord(
      duration: const Duration(minutes: 25),
      value: 4,
    );

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
}
