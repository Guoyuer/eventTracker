import 'package:drift/drift.dart';

import '../domain/activity_models.dart';
import '../domain/activity_record_history.dart';
import 'database/app_database.dart';

class ActivitySnapshotStore {
  ActivitySnapshotStore(this._db);

  final AppDatabase _db;

  Future<List<Activity>> getActivities() => _readSnapshots();

  Future<Activity> getActivity(int activityId) async {
    final activities = await _readSnapshots(activityId: activityId);
    if (activities.isEmpty) {
      throw StateError('Activity $activityId does not exist');
    }
    return activities.single;
  }

  Future<List<Activity>> _readSnapshots({int? activityId}) async {
    final query = _db.select(_db.activities).join([
      leftOuterJoin(
        _db.units,
        _db.units.id.equalsExp(_db.activities.unitId),
      ),
      leftOuterJoin(
        _db.records,
        _db.records.activityId.equalsExp(_db.activities.id),
      ),
    ])..orderBy([OrderingTerm.asc(_db.activities.id)]);
    if (activityId != null) {
      query.where(_db.activities.id.equals(activityId));
    }

    final rows = await query.get();
    final activitiesById = <int, ActivityRow>{};
    final recordsByActivityId = <int, List<Record>>{};
    final unitNamesByActivityId = <int, String>{};
    for (final row in rows) {
      final activity = row.readTable(_db.activities);
      activitiesById[activity.id] = activity;
      final unit = row.readTableOrNull(_db.units);
      if (unit != null) {
        unitNamesByActivityId[activity.id] = unit.name;
      }
      final record = row.readTableOrNull(_db.records);
      if (record != null) {
        recordsByActivityId.putIfAbsent(activity.id, () => []).add(record);
      }
    }

    return [
      for (final activity in activitiesById.values)
        _snapshotFor(
          activity,
          recordsByActivityId[activity.id] ?? const [],
          unitNamesByActivityId[activity.id],
        ),
    ];
  }

  Activity _snapshotFor(
    ActivityRow activity,
    List<Record> records,
    String? unit,
  ) {
    final history = ActivityRecordHistory.evaluate(
      activityId: activity.id,
      careTime: activity.careTime,
      hasUnit: unit != null,
      records: [
        for (final record in records)
          ActivityHistoryRecord(
            id: record.id,
            startTime: record.startTime,
            endTime: record.endTime,
            value: record.value,
          ),
      ],
    );

    if (!activity.careTime) {
      return PlainActivity(
        id: activity.id,
        name: activity.name,
        unit: unit,
        description: activity.description,
        occurrenceCount: history.occurrenceCount,
        totalValue: history.totalValue,
      );
    }

    final activeStartedAt = history.activeStartedAt;
    if (activeStartedAt == null) {
      return InactiveTimedActivity(
        id: activity.id,
        name: activity.name,
        unit: unit,
        description: activity.description,
        totalDuration: history.totalDuration,
        totalValue: history.totalValue,
      );
    }

    return ActiveTimedActivity(
      id: activity.id,
      name: activity.name,
      unit: unit,
      description: activity.description,
      startedAt: activeStartedAt,
      totalDuration: history.totalDuration,
      totalValue: history.totalValue,
    );
  }
}
