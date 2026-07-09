import 'package:drift/drift.dart';

import '../domain/activity_models.dart';
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
    final activeRecords = _db.alias(_db.records, 'active_records');
    final query = _db.select(_db.events).join([
      leftOuterJoin(
        activeRecords,
        activeRecords.eventId.equalsExp(_db.events.id) &
            activeRecords.endTime.isNull(),
      ),
    ])..orderBy([OrderingTerm.asc(_db.events.id)]);
    if (activityId != null) {
      query.where(_db.events.id.equals(activityId));
    }

    final rows = await query.get();
    final eventsById = <int, Event>{};
    final activeRecordsByActivityId = <int, List<Record>>{};
    for (final row in rows) {
      final event = row.readTable(_db.events);
      eventsById[event.id] = event;
      final activeRecord = row.readTableOrNull(activeRecords);
      if (activeRecord != null) {
        activeRecordsByActivityId
            .putIfAbsent(event.id, () => [])
            .add(activeRecord);
      }
    }

    return [
      for (final event in eventsById.values)
        _snapshotFor(event, activeRecordsByActivityId[event.id] ?? const []),
    ];
  }

  Activity _snapshotFor(Event event, List<Record> activeRecords) {
    if (!event.careTime) {
      if (activeRecords.isNotEmpty) {
        throw StateError('Plain Activity ${event.id} has an active Record');
      }
      return PlainActivity(
        id: event.id,
        name: event.name,
        unit: event.unit,
        description: event.description,
        occurrenceCount: event.sumTime.inSeconds,
        totalValue: event.sumVal,
      );
    }

    if (activeRecords.length > 1) {
      throw StateError(
        'Timed Activity ${event.id} has ${activeRecords.length} active Records',
      );
    }

    if (activeRecords.isEmpty) {
      return InactiveTimedActivity(
        id: event.id,
        name: event.name,
        unit: event.unit,
        description: event.description,
        totalDuration: event.sumTime,
        totalValue: event.sumVal,
      );
    }

    final activeRecord = activeRecords.single;
    final startedAt = activeRecord.startTime;
    if (startedAt == null) {
      throw StateError(
        'Active Record ${activeRecord.id} for Timed Activity ${event.id} '
        'has no start time',
      );
    }
    return ActiveTimedActivity(
      id: event.id,
      name: event.name,
      unit: event.unit,
      description: event.description,
      startedAt: startedAt,
      totalDuration: event.sumTime,
      totalValue: event.sumVal,
    );
  }
}
