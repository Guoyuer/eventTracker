import '../domain/activity_models.dart';
import 'database/app_database.dart';

/// Maps a persisted row into its total domain shape at the persistence edge.
ActivityRecord activityRecordFromRow(Record row) {
  final startedAt = row.startTime;
  final endedAt = row.endTime;

  if (startedAt == null) {
    if (endedAt == null) {
      throw StateError('Record ${row.id} has neither start nor end time');
    }
    return PlainRecord(
      id: row.id,
      activityId: row.activityId,
      endedAt: endedAt,
      value: row.value,
    );
  }

  if (endedAt == null) {
    if (row.value != null) {
      throw StateError('Active Record ${row.id} has a value');
    }
    return ActiveTimedRecord(
      id: row.id,
      activityId: row.activityId,
      startedAt: startedAt,
    );
  }

  if (endedAt.isBefore(startedAt)) {
    throw StateError('Timed Record ${row.id} ends before it starts');
  }
  return CompletedTimedRecord(
    id: row.id,
    activityId: row.activityId,
    startedAt: startedAt,
    endedAt: endedAt,
    value: row.value,
  );
}
