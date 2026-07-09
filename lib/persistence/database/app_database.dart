import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import 'database_bootstrap.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Units, Events, Records], include: {'sql.moor'})
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? defaultDatabaseExecutor());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(beforeOpen: (details) async {
        await customStatement('PRAGMA synchronous = OFF');
      }, onCreate: (Migrator m) {
        return m.createAll();
      }, onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          await _migrateToVersion3();
        }
      });

  Future<void> _migrateToVersion3() async {
    await customStatement('DELETE FROM records WHERE event_id = -1');
    await customStatement('DROP INDEX IF EXISTS step_time');
    await customStatement('DROP TABLE IF EXISTS step_offset');
    await customStatement('DROP TABLE IF EXISTS steps');
  }

//////////////////////////////////unit相关////////////////////////////////////

  Future<List<Unit>> getAllUnits() => select(units).get();

  Future<int> addUnit(UnitsCompanion unit) => into(units).insert(unit);

  Future<void> deleteUnitByName(String unitName) async {
    await (delete(units)..where((tbl) => tbl.name.equals(unitName))).go();
  }

  //////////////////////////////////record相关///////////////////////////////////

  ///////////////////record.get类

  ///得到recordId对应的整个record
  Future<Record> getRecordById(int id) async {
    var record =
        await (select(records)..where((tbl) => tbl.id.equals(id))).getSingle();
    return record;
  }

  Future<List<Record>> getRecordsInRange(DateTimeRange range) {
    DateTime start = range.start;
    DateTime end = range.end;
    return (select(records)
          ..where((tbl) => tbl.endTime.isBetweenValues(start, end)))
        .get();
  }

  ///得到所有的记录，不包括active的记录
  Future<List<Record>> getRecordsByEventId(int eventId) => (select(records)
        ..orderBy([(t) => OrderingTerm(expression: t.endTime)])
        ..where((tbl) => tbl.eventId.equals(eventId) & tbl.endTime.isNotNull()))
      .get();

  ///////////////////////////////////////event相关///////////////////////////////////
  ///////////////////event.get类

  Future<Event> getEventById(int eventId) async {
    return await (select(events)..where((tbl) => tbl.id.equals(eventId)))
        .getSingle();
  }

  Future<String?> getEventDesc(int eventId) async {
    Event event = await getEventById(eventId);
    return event.description;
  }

  Future<String?> getEventUnit(int eventId) async {
    final query = selectOnly(events)
      ..addColumns([events.unit])
      ..where(events.id.equals(eventId));

    return query.map((row) => row.read(events.unit)).getSingleOrNull();
  }

  Future<List<Event>> getRawEvents() {
    return select(events).get();
  }

  Future<Map<int, Event>> getEventsMap() async {
    List<Event> events = await getRawEvents();
    Map<int, Event> res = {};
    events.forEach((element) {
      res[element.id] = element;
    });
    return res;
  }

  ///返回成功或失败
  Future<int> addEventInDB(EventsCompanion event) => into(events).insert(event);

  Future updateEventDescription(int eventId, String desc) {
    return (update(events)..where((tbl) => tbl.id.equals(eventId)))
        .write(EventsCompanion(description: Value(desc)));
  }

  Future deleteEvent(int eventId) async {
    return transaction(() async {
      await (delete(records)..where((tbl) => tbl.eventId.equals(eventId))).go();
      await (delete(events)..where((tbl) => tbl.id.equals(eventId))).go();
    });
  }
}
