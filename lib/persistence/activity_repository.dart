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
  Future<List<BaseEventModel>> getActivities() {
    return _db.getEventsProfile();
  }

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) async {
    final records = await _db.getRecordsByEventId(activityId);
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
    return _db.addEventInDB(
      EventsCompanion(
        name: Value(name),
        careTime: Value(careTime),
        unit: Value(unit),
        description: Value(description),
      ),
    );
  }

  @override
  Future<String?> getActivityUnit(int activityId) {
    return _db.getEventUnit(activityId);
  }

  @override
  Future<String?> getActivityDescription(int activityId) {
    return _db.getEventDesc(activityId);
  }

  @override
  Future<void> updateActivityDescription(
    int activityId,
    String description,
  ) {
    return _db.updateEventDescription(activityId, description);
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
  Future<void> deleteActivity(int activityId) {
    return _db.deleteEvent(activityId);
  }
}
