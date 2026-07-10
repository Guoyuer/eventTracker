import 'package:drift/drift.dart';

import '../domain/activity_models.dart';
import '../domain/activity_repository.dart';
import '../domain/input_validation.dart';
import 'activity_snapshot_store.dart';
import 'database/app_database.dart';
import 'record_lifecycle_store.dart';

class DriftActivityRepository implements ActivityRepository {
  DriftActivityRepository(AppDatabase db)
    : _db = db,
      _activitySnapshots = ActivitySnapshotStore(db),
      _recordLifecycle = RecordLifecycleStore(db);

  final AppDatabase _db;
  final ActivitySnapshotStore _activitySnapshots;
  final RecordLifecycleStore _recordLifecycle;

  @override
  Future<List<Activity>> getActivities() => _activitySnapshots.getActivities();

  @override
  Future<Activity> getActivity(int activityId) =>
      _activitySnapshots.getActivity(activityId);

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) async {
    final records =
        await (_db.select(_db.records)
              ..orderBy([(record) => OrderingTerm(expression: record.endTime)])
              ..where(
                (record) =>
                    record.eventId.equals(activityId) &
                    record.endTime.isNotNull(),
              ))
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
  }) async {
    final normalizedName = normalizeRequiredName(name, field: 'activityName');
    final normalizedUnit = normalizeOptionalName(unit, field: 'unitName');
    Unit? selectedUnit;
    if (normalizedUnit != null) {
      selectedUnit = await (_db.select(
        _db.units,
      )..where((row) => row.name.equals(normalizedUnit))).getSingleOrNull();
      if (selectedUnit == null) {
        throw StateError('Unit $normalizedUnit does not exist');
      }
    }
    return _db
        .into(_db.events)
        .insert(
          EventsCompanion(
            name: Value(normalizedName),
            careTime: Value(careTime),
            unitId: Value(selectedUnit?.id),
            description: Value(description),
          ),
        );
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
  Future<void> updateActivityDescription(int activityId, String description) {
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
    return _recordLifecycle.addPlainRecord(activityId, endTime, value: value);
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
    final deleted = await (_db.delete(
      _db.events,
    )..where((activity) => activity.id.equals(activityId))).go();
    if (deleted != 1) {
      throw StateError('Activity $activityId does not exist');
    }
  }
}
