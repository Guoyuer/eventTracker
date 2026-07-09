import 'package:drift/drift.dart';

import '../domain/activity_aggregate_totals.dart';
import 'database/app_database.dart';

class ActivityAggregateStore {
  ActivityAggregateStore(this._db);

  final AppDatabase _db;

  Future<void> rebuildActivitySnapshot(int activityId) async {
    final snapshot = await _snapshotForActivity(activityId);
    await (_db.update(
      _db.events,
    )..where((event) => event.id.equals(activityId))).write(
      EventsCompanion(
        lastRecordId: Value(snapshot.lastRecordId),
        sumTime: Value(snapshot.sumTime),
        sumVal: Value(snapshot.sumValue),
      ),
    );
  }

  Future<void> rebuildAllActivitySnapshots() async {
    final activities = await _db.select(_db.events).get();
    for (final activity in activities) {
      await rebuildActivitySnapshot(activity.id);
    }
  }

  Future<ActivityAggregateSnapshot> _snapshotForActivity(int activityId) async {
    final completedRecords =
        await (_db.select(_db.records)..where(
              (record) =>
                  record.eventId.equals(activityId) &
                  record.endTime.isNotNull(),
            ))
            .get();
    final activeRecords =
        await (_db.select(_db.records)..where(
              (record) =>
                  record.eventId.equals(activityId) &
                  record.startTime.isNotNull() &
                  record.endTime.isNull(),
            ))
            .get();

    if (activeRecords.length > 1) {
      throw StateError(
        'Activity $activityId has multiple active timed records.',
      );
    }

    return ActivityAggregateSnapshot.fromCompletedRecords([
      for (final record in completedRecords)
        ActivityAggregateRecord(
          id: record.id,
          startTime: record.startTime,
          endTime: record.endTime!,
          value: record.value,
        ),
    ], activeRecordId: activeRecords.isEmpty ? null : activeRecords.single.id);
  }
}
