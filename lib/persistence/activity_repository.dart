import 'package:drift/drift.dart';

import '../domain/activity_models.dart';
import 'database/app_database.dart';
import 'record_lifecycle_store.dart';

abstract class ActivityRepository {
  Future<List<BaseEventModel>> getActivities();

  Future<List<ActivityRecord>> getActivityRecords(int activityId);

  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  });

  Future<String?> getActivityDescription(int activityId);

  Future<void> updateActivityDescription(int activityId, String description);

  Future<String?> getActivityUnit(int activityId);

  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  });

  Future<int> startTimedRecord(int activityId, DateTime startTime);

  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  });

  Future<void> cancelActiveTimedRecord(int activityId);

  Future<void> deleteActivity(int activityId);
}

class DriftActivityRepository implements ActivityRepository {
  DriftActivityRepository(this._db)
      : _recordLifecycle = RecordLifecycleStore(_db);

  final AppDatabase _db;
  final RecordLifecycleStore _recordLifecycle;

  @override
  Future<List<BaseEventModel>> getActivities() async {
    final events = await _db.select(_db.events).get();
    return [
      for (final event in events) await _toActivityModel(event),
    ];
  }

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) async {
    final records = await (_db.select(_db.records)
          ..orderBy([(record) => OrderingTerm(expression: record.endTime)])
          ..where((record) =>
              record.eventId.equals(activityId) & record.endTime.isNotNull()))
        .get();
    return [
      for (final record in records)
        ActivityRecord(
          id: record.id,
          eventId: record.eventId,
          startTime: record.startTime,
          endTime: record.endTime!,
          value: record.value,
        ),
    ];
  }

  @override
  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  }) {
    return _db.into(_db.events).insert(
          EventsCompanion(
            name: Value(name),
            careTime: Value(careTime),
            unit: Value(unit),
            description: Value(description),
          ),
        );
  }

  @override
  Future<String?> getActivityUnit(int activityId) async {
    final query = _db.selectOnly(_db.events)
      ..addColumns([_db.events.unit])
      ..where(_db.events.id.equals(activityId));

    return query.map((row) => row.read(_db.events.unit)).getSingleOrNull();
  }

  @override
  Future<String?> getActivityDescription(int activityId) async {
    final query = _db.selectOnly(_db.events)
      ..addColumns([_db.events.description])
      ..where(_db.events.id.equals(activityId));

    return query
        .map((row) => row.read(_db.events.description))
        .getSingleOrNull();
  }

  @override
  Future<void> updateActivityDescription(
    int activityId,
    String description,
  ) {
    return (_db.update(_db.events)
          ..where((activity) => activity.id.equals(activityId)))
        .write(EventsCompanion(description: Value(description)));
  }

  @override
  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  }) {
    return _recordLifecycle.addPlainRecord(
      activityId,
      endTime,
      value: value,
    );
  }

  @override
  Future<int> startTimedRecord(int activityId, DateTime startTime) {
    return _recordLifecycle.startTimedRecord(activityId, startTime);
  }

  @override
  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  }) {
    return _recordLifecycle.stopActiveTimedRecord(
      activityId,
      stoppedAt,
      value: value,
    );
  }

  @override
  Future<void> cancelActiveTimedRecord(int activityId) {
    return _recordLifecycle.cancelActiveTimedRecord(activityId);
  }

  @override
  Future<void> deleteActivity(int activityId) async {
    return _db.transaction(() async {
      await (_db.delete(_db.records)
            ..where((record) => record.eventId.equals(activityId)))
          .go();
      await (_db.delete(_db.events)
            ..where((activity) => activity.id.equals(activityId)))
          .go();
    });
  }

  Future<BaseEventModel> _toActivityModel(Event event) {
    if (event.careTime) {
      return _toTimedActivity(event);
    }

    return Future.value(_toPlainActivity(event));
  }

  PlainEventModel _toPlainActivity(Event event) {
    return PlainEventModel(
      event.id,
      event.name,
      event.unit,
      event.sumTime.inSeconds,
      event.sumVal,
      event.description,
      event.lastRecordId,
    );
  }

  Future<TimingEventModel> _toTimedActivity(Event event) async {
    if (event.lastRecordId == null) {
      return TimingEventModel(
        event.id,
        event.name,
        event.unit,
        EventStatus.notActive,
        Duration.zero,
        null,
        0,
        event.description,
        event.lastRecordId,
      );
    }

    final record = await _recordById(event.lastRecordId!);
    final status =
        record.endTime == null ? EventStatus.active : EventStatus.notActive;

    return TimingEventModel(
      event.id,
      event.name,
      event.unit,
      status,
      event.sumTime,
      record.startTime,
      event.sumVal,
      event.description,
      event.lastRecordId,
    );
  }

  Future<Record> _recordById(int id) {
    return (_db.select(_db.records)..where((record) => record.id.equals(id)))
        .getSingle();
  }
}
