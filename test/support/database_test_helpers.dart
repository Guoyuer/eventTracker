import 'package:drift/drift.dart';
import 'package:event_tracker/persistence/database/app_database.dart';

Future<int> insertTestActivity(
  AppDatabase db, {
  required String name,
  required bool careTime,
  String? unit,
  String? description,
}) async {
  int? unitId;
  if (unit != null) {
    var storedUnit = await (db.select(
      db.units,
    )..where((row) => row.name.equals(unit))).getSingleOrNull();
    storedUnit ??= await db
        .into(db.units)
        .insertReturning(UnitsCompanion(name: Value(unit)));
    unitId = storedUnit.id;
  }
  return db
      .into(db.events)
      .insert(
        EventsCompanion(
          name: Value(name),
          careTime: Value(careTime),
          unitId: Value(unitId),
          description: Value(description),
        ),
      );
}

Future<Event> getTestActivity(AppDatabase db, int activityId) {
  return (db.select(
    db.events,
  )..where((activity) => activity.id.equals(activityId))).getSingle();
}

Future<Record> getTestRecord(AppDatabase db, int recordId) {
  return (db.select(
    db.records,
  )..where((record) => record.id.equals(recordId))).getSingle();
}

Future<List<Record>> getCompletedTestRecordsForActivity(
  AppDatabase db,
  int activityId,
) {
  return (db.select(db.records)
        ..orderBy([(record) => OrderingTerm(expression: record.endTime)])
        ..where(
          (record) =>
              record.eventId.equals(activityId) & record.endTime.isNotNull(),
        ))
      .get();
}
