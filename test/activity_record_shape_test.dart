import 'package:event_tracker/domain/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed timed records derive duration from non-null endpoints', () {
    final record = CompletedTimedRecord(
      id: 1,
      activityId: 2,
      startedAt: DateTime(2026, 7, 10, 8),
      endedAt: DateTime(2026, 7, 10, 8, 30),
    );

    expect(record.duration, const Duration(minutes: 30));
  });

  test('active timed records have no completed value', () {
    final record = ActiveTimedRecord(
      id: 1,
      activityId: 2,
      startedAt: DateTime(2026, 7, 10, 8),
    );

    expect(record.value, isNull);
  });
}
