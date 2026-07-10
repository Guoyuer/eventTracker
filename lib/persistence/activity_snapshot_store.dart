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
    final query = _db.select(_db.events).join([
      leftOuterJoin(_db.records, _db.records.eventId.equalsExp(_db.events.id)),
    ])..orderBy([OrderingTerm.asc(_db.events.id)]);
    if (activityId != null) {
      query.where(_db.events.id.equals(activityId));
    }

    final rows = await query.get();
    final eventsById = <int, Event>{};
    final recordsByActivityId = <int, List<Record>>{};
    for (final row in rows) {
      final event = row.readTable(_db.events);
      eventsById[event.id] = event;
      final record = row.readTableOrNull(_db.records);
      if (record != null) {
        recordsByActivityId.putIfAbsent(event.id, () => []).add(record);
      }
    }

    return [
      for (final event in eventsById.values)
        _snapshotFor(event, recordsByActivityId[event.id] ?? const []),
    ];
  }

  Activity _snapshotFor(Event event, List<Record> records) {
    final history = ActivityRecordHistory.evaluate(
      activityId: event.id,
      careTime: event.careTime,
      hasUnit: event.unit != null,
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

    if (!event.careTime) {
      return PlainActivity(
        id: event.id,
        name: event.name,
        unit: event.unit,
        description: event.description,
        occurrenceCount: history.occurrenceCount,
        totalValue: history.totalValue,
      );
    }

    final activeStartedAt = history.activeStartedAt;
    if (activeStartedAt == null) {
      return InactiveTimedActivity(
        id: event.id,
        name: event.name,
        unit: event.unit,
        description: event.description,
        totalDuration: history.totalDuration,
        totalValue: history.totalValue,
      );
    }

    return ActiveTimedActivity(
      id: event.id,
      name: event.name,
      unit: event.unit,
      description: event.description,
      startedAt: activeStartedAt,
      totalDuration: history.totalDuration,
      totalValue: history.totalValue,
    );
  }
}
