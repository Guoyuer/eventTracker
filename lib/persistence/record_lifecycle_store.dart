import 'package:drift/drift.dart';

import '../domain/input_validation.dart';
import 'database/app_database.dart';

class RecordLifecycleStore {
  RecordLifecycleStore(this._db);

  final AppDatabase _db;

  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  }) {
    return _db.transaction(() async {
      final validatedValue = validateOptionalFiniteValue(value);
      final activity = await _activityById(activityId);
      if (activity.careTime) {
        throw StateError('Timed Activity $activityId cannot add Plain Records');
      }
      await _db
          .into(_db.records)
          .insert(
            RecordsCompanion(
              eventId: Value(activityId),
              endTime: Value(endTime),
              value: Value(validatedValue),
            ),
          );
    });
  }

  Future<int> startTimedRecord(int activityId, DateTime startTime) {
    return _db.transaction(() async {
      final activity = await _activityById(activityId);
      if (!activity.careTime) {
        throw StateError('Plain Activity $activityId cannot start timing');
      }
      final activeRecords = await _activeRecords(activityId);
      if (activeRecords.isNotEmpty) {
        throw StateError('Timed Activity $activityId is already active');
      }

      final recordId = await _db
          .into(_db.records)
          .insert(
            RecordsCompanion(
              eventId: Value(activityId),
              startTime: Value(startTime),
            ),
          );

      return recordId;
    });
  }

  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  }) {
    return _db.transaction(() async {
      final validatedValue = validateOptionalFiniteValue(value);
      final activeRecord = await _getActiveTimedRecord(activityId);
      final activeRecordId = activeRecord.id;

      _validateCompletedRecord(activeRecord, completedAt: stoppedAt);

      await (_db.update(
        _db.records,
      )..where((record) => record.id.equals(activeRecordId))).write(
        RecordsCompanion(
          endTime: Value(stoppedAt),
          value: Value(validatedValue),
        ),
      );
    });
  }

  Future<void> cancelActiveTimedRecord(int activityId) async {
    return _db.transaction(() async {
      final activeRecord = await _getActiveTimedRecord(activityId);

      await (_db.delete(
        _db.records,
      )..where((record) => record.id.equals(activeRecord.id))).go();
    });
  }

  void _validateCompletedRecord(
    Record record, {
    required DateTime completedAt,
  }) {
    final startedAt = record.startTime;
    if (startedAt == null || completedAt.isBefore(startedAt)) {
      throw StateError('Timed Record ${record.id} cannot end before it starts');
    }
  }

  Future<Record> _getActiveTimedRecord(int activityId) async {
    final activity = await _activityById(activityId);
    if (!activity.careTime) {
      throw StateError('Plain Activity $activityId cannot be timed');
    }

    final activeRecords = await _activeRecords(activityId);
    if (activeRecords.length != 1 || activeRecords.single.startTime == null) {
      throw StateError(
        'Timed Activity $activityId must have exactly one active Record',
      );
    }
    return activeRecords.single;
  }

  Future<Event> _activityById(int activityId) {
    return (_db.select(
      _db.events,
    )..where((activity) => activity.id.equals(activityId))).getSingle();
  }

  Future<List<Record>> _activeRecords(int activityId) {
    return (_db.select(_db.records)..where(
          (record) =>
              record.eventId.equals(activityId) & record.endTime.isNull(),
        ))
        .get();
  }
}
