import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:event_tracker/common/const.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/activity_models.dart';
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

  Future _eventProcessor(Event rawEvent) async {
    Future<TimingEventModel> timingEventProcessor(Event rawEvent) async {
      EventStatus status;
      Duration? sumTime;
      DateTime? startTime;
      double? sumVal;
      if (rawEvent.lastRecordId == null) {
        // 当前还无记录（新创建且未开始的的event）
        status = EventStatus.notActive;
        sumTime = Duration(seconds: 0);
        startTime = null;
        sumVal = 0;
      } else {
        //当前已有记录
        var record = await getRecordById(rawEvent.lastRecordId!);
        startTime = record.startTime;
        sumVal = rawEvent.sumVal;
        sumTime = rawEvent.sumTime;
        if (record.endTime == null) {
          status = EventStatus.active;
        } else {
          status = EventStatus.notActive;
        }
      }
      return TimingEventModel(
          rawEvent.id,
          rawEvent.name,
          rawEvent.unit,
          status,
          sumTime,
          startTime,
          sumVal,
          rawEvent.description,
          rawEvent.lastRecordId);
    }

    Future<PlainEventModel> plainEventProcessor(Event rawEvent) async {
      return PlainEventModel(
          rawEvent.id,
          rawEvent.name,
          rawEvent.unit,
          rawEvent.sumTime.inSeconds,
          rawEvent.sumVal,
          rawEvent.description,
          rawEvent.lastRecordId);
    }

    if (rawEvent.careTime)
      return timingEventProcessor(rawEvent);
    else
      return plainEventProcessor(rawEvent);
  }

  Future<List<BaseEventModel>> getEventsProfile() async {
    var rawEvents = await getRawEvents();
    List<BaseEventModel> events = [];
    for (var event in rawEvents) {
      events.add(await _eventProcessor(event));
    }

    return events;
  }
}

QueryExecutor defaultDatabaseExecutor() {
  return LazyDatabase(() async {
    if (usesExplicitDatabasePathOnPlatform(defaultTargetPlatform,
        isWeb: kIsWeb)) {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      return SqfliteQueryExecutor(
        path: p.join(directory.path, 'db.sqlite'),
        logStatements: false,
      );
    }

    return SqfliteQueryExecutor.inDatabaseFolder(
      path: 'db.sqlite',
      logStatements: false,
    );
  });
}

@visibleForTesting
bool usesExplicitDatabasePathOnPlatform(TargetPlatform platform,
    {required bool isWeb}) {
  return !isWeb &&
      (platform == TargetPlatform.windows ||
          platform == TargetPlatform.linux ||
          platform == TargetPlatform.macOS);
}
