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
      final recordId = await _db.into(_db.records).insert(
            RecordsCompanion(
              eventId: Value(activityId),
              endTime: Value(endTime),
              value: Value(value),
            ),
          );
      final activity = await _db.getEventById(activityId);
      final nextTotals = ActivityAggregateTotals(
        sumTime: activity.sumTime,
        sumValue: activity.sumVal,
      ).addPlainRecord(value: value);

      await (_db.update(_db.events)
            ..where((event) => event.id.equals(activityId)))
          .write(
        EventsCompanion(
          lastRecordId: Value(recordId),
          sumTime: Value(nextTotals.sumTime),
          sumVal: Value(nextTotals.sumValue),
        ),
      );
    });
  }

  Future<int> startTimedRecord(int activityId, DateTime startTime) {
    return _db.transaction(() async {
      final recordId = await _db.into(_db.records).insert(
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
      final activity = await _db.getEventById(activityId);
      final activeRecord = await _getActiveTimedRecord(activityId);
      final activeRecordId = activeRecord.id;

      final duration = stoppedAt.difference(activeRecord.startTime!);
      final nextTotals = ActivityAggregateTotals(
        sumTime: activity.sumTime,
        sumValue: activity.sumVal,
      ).addTimedRecord(duration: duration, value: value);

      await (_db.update(_db.records)
            ..where((record) => record.id.equals(activeRecordId)))
          .write(
        RecordsCompanion(
          endTime: Value(stoppedAt),
          value: Value(value),
        ),
      );

      await (_db.update(_db.events)
            ..where((event) => event.id.equals(activityId)))
          .write(
        EventsCompanion(
          sumTime: Value(nextTotals.sumTime),
          sumVal: Value(nextTotals.sumValue),
        ),
      );
    });
  }

  Future<void> cancelActiveTimedRecord(int activityId) async {
    return _db.transaction(() async {
      final activeRecord = await _getActiveTimedRecord(activityId);

      await (_db.delete(_db.records)
            ..where((record) => record.id.equals(activeRecord.id)))
          .go();

      final previousRecord = await (_db.select(_db.records)
            ..where((record) => record.eventId.equals(activityId))
            ..orderBy([
              (record) => OrderingTerm(
                    expression: record.startTime,
                    mode: OrderingMode.desc,
                  ),
            ])
            ..limit(1))
          .getSingleOrNull();

      await (_db.update(_db.events)
            ..where((event) => event.id.equals(activityId)))
          .write(EventsCompanion(lastRecordId: Value(previousRecord?.id)));
    });
  }

  Future<Record> _getActiveTimedRecord(int activityId) async {
    final activity = await _db.getEventById(activityId);
    final activeRecordId = activity.lastRecordId;
    if (activeRecordId == null) {
      throw StateError('Activity $activityId has no active timed record.');
    }

    final activeRecord = await _db.getRecordById(activeRecordId);
    if (activeRecord.eventId != activityId ||
        activeRecord.startTime == null ||
        activeRecord.endTime != null) {
      throw StateError('Activity $activityId has no active timed record.');
    }

    return activeRecord;
  }
}
