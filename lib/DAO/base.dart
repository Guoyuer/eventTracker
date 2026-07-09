import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:event_tracker/common/const.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'base.g.dart';

part 'model/displayModel.dart';
// 实现单例模式

class DBHandle {
  static final DBHandle _ins = DBHandle._internal();

  DBHandle._internal();

  factory DBHandle() {
    return _ins;
  }

  static final AppDatabase _db = AppDatabase();

  AppDatabase get db {
    return _db;
  }
}

@DriftDatabase(
    tables: [Units, Events, Records, Steps, StepOffset], include: {'SQL.moor'})
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? defaultDatabaseExecutor());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(beforeOpen: (details) async {
        await customStatement('PRAGMA synchronous = OFF');
      }, onCreate: (Migrator m) {
        return m.createAll();
      });

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
          ..where((tbl) =>
              tbl.endTime.isBetweenValues(start, end) &
              tbl.eventId.equals(-1).not()))
        .get();
  }

  Future<List<Record>> getEventRecordsInRange(
      int eventId, DateTimeRange range) {
    DateTime start = range.start;
    DateTime end = range.end;
    return (select(records)
          ..where((tbl) =>
              tbl.endTime.isBetweenValues(start, end) &
              tbl.eventId.equals(eventId)))
        .get();
  }

  ///得到recordId对应记录的开始时间
  Future<DateTime> getStartTime(int recordId) async {
    final query = selectOnly(records)
      ..addColumns([records.startTime])
      ..where(records.id.equals(recordId));
    return query.map((row) => row.read(records.startTime)!).getSingle();
  }

  ///得到所有的记录，不包括active的记录
  Future<List<Record>> getRecordsByEventId(int eventId) => (select(records)
        ..orderBy([(t) => OrderingTerm(expression: t.endTime)])
        ..where((tbl) => tbl.eventId.equals(eventId) & tbl.endTime.isNotNull()))
      .get();

  ///////////////////record.add类

  /// 添加plain record in DB
  Future addPlainRecordInDB(RecordsCompanion record) async {
    assert(record.endTime != Value.absent());
    assert(record.eventId != Value.absent());
    int eventId = record.eventId.value;
    return transaction(() async {
      int recordId = await into(records).insert(record);
      final event = await getEventById(eventId);
      final nextValue = event.sumVal + (record.value.value ?? 0);

      await (update(events)..where((tbl) => tbl.id.equals(eventId))).write(
        EventsCompanion(
          lastRecordId: Value(recordId),
          sumTime: Value(event.sumTime + const Duration(seconds: 1)),
          sumVal: Value(nextValue),
        ),
      );
    });
  }

  Future<int> startTimingRecordInDB(RecordsCompanion record) async {
    assert(record.startTime != Value.absent());
    assert(record.eventId != Value.absent());
    int eventId = record.eventId.value;
    return transaction(() async {
      int recordId = await into(records).insert(record);
      await (update(events)..where((tbl) => tbl.id.equals(eventId)))
          .write(EventsCompanion(lastRecordId: Value(recordId)));
      return recordId;
    });
  }

  Future stopTimingRecordInDB(
      Duration thisDuration, RecordsCompanion record) async {
    assert(record.id != Value.absent());
    assert(record.eventId != Value.absent());
    assert(record.endTime != Value.absent());
    int eventId = record.eventId.value;
    int recordId = record.id.value;
    return transaction(() async {
      await (update(records)..where((record) => record.id.equals(recordId)))
          .write(
              RecordsCompanion(endTime: record.endTime, value: record.value));

      final event = await getEventById(eventId);
      final nextValue = event.sumVal + (record.value.value ?? 0);

      await (update(events)..where((event) => event.id.equals(eventId))).write(
        EventsCompanion(
          sumTime: Value(event.sumTime + thisDuration),
          sumVal: Value(nextValue),
        ),
      );
    });
  }

  Future<void> stopActiveTimingRecordInDB(
    int eventId,
    DateTime stoppedAt, {
    double? value,
  }) {
    return transaction(() async {
      final event = await getEventById(eventId);
      final activeRecordId = event.lastRecordId;
      if (activeRecordId == null) {
        throw StateError('Activity $eventId has no active timed record.');
      }

      final activeRecord = await getRecordById(activeRecordId);
      if (activeRecord.eventId != eventId ||
          activeRecord.startTime == null ||
          activeRecord.endTime != null) {
        throw StateError('Activity $eventId has no active timed record.');
      }

      final duration = stoppedAt.difference(activeRecord.startTime!);
      if (duration.isNegative) {
        throw ArgumentError.value(
          stoppedAt,
          'stoppedAt',
          'Stop time cannot be before the active record start time.',
        );
      }

      await (update(records)
            ..where((record) => record.id.equals(activeRecordId)))
          .write(
        RecordsCompanion(
          endTime: Value(stoppedAt),
          value: Value(value),
        ),
      );

      await (update(events)..where((event) => event.id.equals(eventId))).write(
        EventsCompanion(
          sumTime: Value(event.sumTime + duration),
          sumVal: Value(event.sumVal + (value ?? 0)),
        ),
      );
    });
  }

  Future deleteActiveTimingRecordInDB(int recordId, int eventId) async {
    return transaction(() async {
      await (delete(records)..where((tbl) => tbl.id.equals(recordId)))
          .go(); //step1 删除recordId对应记录

      Record? formerRecord =
          await (select(records) //step2: 在records表里找到对应Event的当前最新记录（即之前的次新记录）
                ..where((tbl) => tbl.eventId.equals(eventId))
                ..orderBy([
                  (t) => OrderingTerm(
                      expression: t.startTime, mode: OrderingMode.desc)
                ])
                ..limit(1))
              .getSingleOrNull();
      Value<int?> lastRecordId;
      if (formerRecord == null) {
        lastRecordId = Value(null);
      } else {
        lastRecordId = Value(formerRecord.id);
      }

      await (update(events)
            ..where((tbl) =>
                tbl.id.equals(eventId))) //step3: 更新Event row的lastRecordId
          .write(EventsCompanion(lastRecordId: lastRecordId));
    });
  }

  Future<void> deleteActiveTimingRecordForEventInDB(int eventId) async {
    final event = await getEventById(eventId);
    final activeRecordId = event.lastRecordId;
    if (activeRecordId == null) {
      throw StateError('Activity $eventId has no active timed record.');
    }
    return deleteActiveTimingRecordInDB(activeRecordId, eventId);
  }

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

  Future<Duration> getEventSumTime(int eventId) async {
    Event event = await (select(events)..where((tbl) => tbl.id.equals(eventId)))
        .getSingle();
    return event.sumTime;
  }

  // Future<double> getEventSumVal(int eventId) {
  //   final query = (selectOnly(events)..addColumns([events.sumVal]))
  //     ..where(events.id.equals(eventId));
  //   return query.map((row) => row.read(events.sumVal)).getSingle();
  // }
  Future<DateTime> getEventStartTime(int eventId) async {
    Event event = await (select(events)..where((tbl) => tbl.id.equals(eventId)))
        .getSingle();
    int lastRecordId = event.lastRecordId!;
    Record record = await (select(records)
          ..where((tbl) => tbl.id.equals(lastRecordId)))
        .getSingle();
    return record.startTime!;
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
