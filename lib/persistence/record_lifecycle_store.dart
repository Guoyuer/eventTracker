import 'package:drift/drift.dart';

import '../domain/activity_aggregate_totals.dart';
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
      await _activityById(activityId);
      await _db
          .into(_db.records)
          .insert(
            RecordsCompanion(
              eventId: Value(activityId),
              endTime: Value(endTime),
              value: Value(value),
            ),
          );
      await _rebuildAggregateSnapshot(activityId);
    });
  }

  Future<int> startTimedRecord(int activityId, DateTime startTime) {
    return _db.transaction(() async {
      final recordId = await _db
          .into(_db.records)
          .insert(
            RecordsCompanion(
              eventId: Value(activityId),
              startTime: Value(startTime),
            ),
          );

      await (_db.update(_db.events)
            ..where((event) => event.id.equals(activityId)))
          .write(EventsCompanion(lastRecordId: Value(recordId)));

      return recordId;
    });
  }

  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  }) {
    return _db.transaction(() async {
      final activeRecord = await _getActiveTimedRecord(activityId);
      final activeRecordId = activeRecord.id;

      _validateCompletedRecord(
        activeRecord,
        completedAt: stoppedAt,
        value: value,
      );

      await (_db.update(
        _db.records,
      )..where((record) => record.id.equals(activeRecordId))).write(
        RecordsCompanion(endTime: Value(stoppedAt), value: Value(value)),
      );

      await _rebuildAggregateSnapshot(activityId);
    });
  }

  Future<void> cancelActiveTimedRecord(int activityId) async {
    return _db.transaction(() async {
      final activeRecord = await _getActiveTimedRecord(activityId);

      await (_db.delete(
        _db.records,
      )..where((record) => record.id.equals(activeRecord.id))).go();

      await _rebuildAggregateSnapshot(activityId);
    });
  }

  Future<void> _rebuildAggregateSnapshot(int activityId) async {
    final completedRecords =
        await (_db.select(_db.records)..where(
              (record) =>
                  record.eventId.equals(activityId) &
                  record.endTime.isNotNull(),
            ))
            .get();
    final snapshot = ActivityAggregateSnapshot.fromCompletedRecords([
      for (final record in completedRecords)
        ActivityAggregateRecord(
          id: record.id,
          startTime: record.startTime,
          endTime: record.endTime!,
          value: record.value,
        ),
    ]);

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

  void _validateCompletedRecord(
    Record record, {
    required DateTime completedAt,
    double? value,
  }) {
    ActivityAggregateRecord(
      id: record.id,
      startTime: record.startTime,
      endTime: completedAt,
      value: value,
    ).contribution;
  }

  Future<Record> _getActiveTimedRecord(int activityId) async {
    final activity = await _activityById(activityId);
    final activeRecordId = activity.lastRecordId;
    if (activeRecordId == null) {
      throw StateError('Activity $activityId has no active timed record.');
    }

    final activeRecord = await _recordById(activeRecordId);
    if (activeRecord.eventId != activityId ||
        activeRecord.startTime == null ||
        activeRecord.endTime != null) {
      throw StateError('Activity $activityId has no active timed record.');
    }

    return activeRecord;
  }

  Future<Event> _activityById(int activityId) {
    return (_db.select(
      _db.events,
    )..where((activity) => activity.id.equals(activityId))).getSingle();
  }

  Future<Record> _recordById(int recordId) {
    return (_db.select(
      _db.records,
    )..where((record) => record.id.equals(recordId))).getSingle();
  }
}
