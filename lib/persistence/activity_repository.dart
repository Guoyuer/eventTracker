import 'package:drift/drift.dart';

import '../DAO/base.dart';

abstract class ActivityRepository {
  Future<List<BaseEventModel>> getActivities();

  Future<String?> getActivityUnit(int activityId);

  Future<DateTime> getActivityStartTime(int activityId);

  Future<int> getLastRecordId(int activityId);

  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  });

  Future<int> startTimedRecord(int activityId, DateTime startTime);

  Future<void> stopTimedRecord(
    int activityId,
    int recordId,
    DateTime endTime,
    Duration duration, {
    double? value,
  });

  Future<void> deleteActiveTimedRecord(int activityId, int recordId);
}

class DriftActivityRepository implements ActivityRepository {
  DriftActivityRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<BaseEventModel>> getActivities() {
    return _db.getEventsProfile();
  }

  @override
  Future<String?> getActivityUnit(int activityId) {
    return _db.getEventUnit(activityId);
  }

  @override
  Future<DateTime> getActivityStartTime(int activityId) {
    return _db.getEventStartTime(activityId);
  }

  @override
  Future<int> getLastRecordId(int activityId) {
    return _db.getLastRecordId(activityId);
  }

  @override
  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  }) {
    return _db.addPlainRecordInDB(
      RecordsCompanion(
        eventId: Value(activityId),
        endTime: Value(endTime),
        value: Value(value),
      ),
    );
  }

  @override
  Future<int> startTimedRecord(int activityId, DateTime startTime) {
    return _db.startTimingRecordInDB(
      RecordsCompanion(
        eventId: Value(activityId),
        startTime: Value(startTime),
      ),
    );
  }

  @override
  Future<void> stopTimedRecord(
    int activityId,
    int recordId,
    DateTime endTime,
    Duration duration, {
    double? value,
  }) {
    return _db.stopTimingRecordInDB(
      duration,
      RecordsCompanion(
        id: Value(recordId),
        eventId: Value(activityId),
        endTime: Value(endTime),
        value: Value(value),
      ),
    );
  }

  @override
  Future<void> deleteActiveTimedRecord(int activityId, int recordId) {
    return _db.deleteActiveTimingRecordInDB(recordId, activityId);
  }
}

ActivityRepository activityRepository() {
  return DriftActivityRepository(DBHandle().db);
}
