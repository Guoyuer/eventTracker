import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/persistence/activity_record_mapper.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every valid persisted Record shape to its domain type', () {
    final plain = activityRecordFromRow(
      Record(
        id: 1,
        activityId: 7,
        endTime: DateTime(2026, 7, 10, 8),
        value: 3,
      ),
    );
    final completedTimed = activityRecordFromRow(
      Record(
        id: 2,
        activityId: 7,
        startTime: DateTime(2026, 7, 10, 8),
        endTime: DateTime(2026, 7, 10, 8, 30),
      ),
    );
    final activeTimed = activityRecordFromRow(
      Record(id: 3, activityId: 7, startTime: DateTime(2026, 7, 10, 9)),
    );

    expect(plain, isA<PlainRecord>());
    expect((plain as PlainRecord).activityId, 7);
    expect(plain.endedAt, DateTime(2026, 7, 10, 8));
    expect(completedTimed, isA<CompletedTimedRecord>());
    expect(
      (completedTimed as CompletedTimedRecord).duration,
      const Duration(minutes: 30),
    );
    expect(activeTimed, isA<ActiveTimedRecord>());
    expect((activeTimed as ActiveTimedRecord).value, isNull);
  });

  test('rejects persisted Record shapes outside the domain contract', () {
    expect(
      () => activityRecordFromRow(Record(id: 1, activityId: 7)),
      throwsStateError,
    );
    expect(
      () => activityRecordFromRow(
        Record(
          id: 2,
          activityId: 7,
          startTime: DateTime(2026, 7, 10, 9),
          value: 1,
        ),
      ),
      throwsStateError,
    );
    expect(
      () => activityRecordFromRow(
        Record(
          id: 3,
          activityId: 7,
          startTime: DateTime(2026, 7, 10, 9),
          endTime: DateTime(2026, 7, 10, 8),
        ),
      ),
      throwsStateError,
    );
  });
}
