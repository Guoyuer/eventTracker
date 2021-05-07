import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/commonWidget.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/heatmap_calendar/heatMap.dart';
import 'package:moor_flutter/moor_flutter.dart';

import 'tables.dart';

part 'base.g.dart';
part 'model/displayModel.dart';
// 实现单例模式

class DBHandle {
  static final DBHandle _ins = new DBHandle._internal();

  DBHandle._internal();

  factory DBHandle() {
    return _ins;
  }

  static AppDatabase _db = AppDatabase();

  AppDatabase get db {
    return _db;
  }
}

@UseMoor(
    tables: [Units, Events, Records, Steps, StepOffset], include: {'SQL.moor'})
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: "db.sqlite", logStatements: false));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(beforeOpen: (details) async {
        // var offset = await getStepOffset();
        // if (offset == null) {
        //   //便于后续操作，因为不是nullable
        //   await into(stepOffset).insert(StepOffsetCompanion(
        //       id: Value(1), step: Value(0), time: Value(nilTime)));
        // }
        await customStatement('PRAGMA synchronous = OFF');
      }, onCreate: (Migrator m) {
        return m.createAll();
      });

//////////////////////////////////debug工具////////////////////////////////////
  Future<void> deleteEverything() {
    return transaction(() async {
      // you only need this if you've manually enabled foreign keys
      // await customStatement('PRAGMA foreign_keys = OFF');
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

//////////////////////////////////unit相关////////////////////////////////////

  Future<List<Unit>> getAllUnits() => select(units).get();

  Future addUnit(UnitsCompanion unit) => into(units).insert(unit);

  Future deleteUnit(UnitsCompanion unit) {
    return (delete(units)..where((tbl) => tbl.name.equals(unit.name.value)))
        .go();
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

  ///得到eventId对应事件的LastRecordId
  Future<int> getLastRecordId(int eventId) async {
    Event event = await (select(events)
          ..where((event) => event.id.equals(eventId)))
        .getSingle();
    return event.lastRecordId!;
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
    int recordId = await into(records).insert(record);
    int eventId = record.eventId.value;
    return transaction(() async {
      await customUpdate(
          "update events set sum_time = sum_time + 1, last_record_id = $recordId where id = $eventId"); //step 1 更新Events的lastRecordId和sumTime
      if (record.value != Value.absent() && record.value.value != 0) {
        double val = record.value.value!;
        await customUpdate(
            "update events set sum_val = sum_val + $val where id = $eventId"); //step 2 有值才更新Events的sumVal
      }
    });
  }

  Future<int> startTimingRecordInDB(RecordsCompanion record) async {
    assert(record.startTime != Value.absent());
    assert(record.eventId != Value.absent());
    int recordId = await into(records).insert(record);
    int eventId = record.eventId.value;
    customUpdate(
        "update events set last_record_id = $recordId where id = $eventId");
    return recordId;
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

      Duration sumTime = await getEventSumTime(eventId);
      sumTime += thisDuration;
      await (update(events)..where((event) => event.id.equals(eventId)))
          .write(EventsCompanion(sumTime: Value(sumTime)));

      if (record.value != Value.absent() && record.value.value != 0) {
        double val = record.value.value!;
        await customUpdate(
            "update events set sum_val = sum_val + $val where id = $eventId");
      }
    });
  }

  Future deleteActiveTimingRecordInDB(int recordId, int eventId) async {
    (delete(records)..where((tbl) => tbl.id.equals(recordId)))
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
    var lastRecordId;
    if (formerRecord == null) {
      lastRecordId = Value(null);
    } else {
      lastRecordId = Value(formerRecord.id);
    }

    (update(events)
          ..where((tbl) =>
              tbl.id.equals(eventId))) //step3: 更新Event row的lastRecordId
        .write(EventsCompanion(lastRecordId: lastRecordId));
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
  Future<int> addEventInDB(EventsCompanion event) async {
    try {
      return into(events).insert(event);
    } catch (err) {
      print(err);
      showToast("创建项目失败，可能是因为重名");
      return -1;
    }
  }

  Future updateEventDescription(int eventId, String desc) {
    print(desc);
    return (update(events)..where((tbl) => tbl.id.equals(eventId)))
        .write(EventsCompanion(description: Value(desc)));
  }

  Future deleteEvent(int eventId) async {
    delete(events)
      ..where((tbl) => tbl.id.equals(eventId))
      ..go();
    return delete(records)
      ..where((tbl) => tbl.eventId.equals(eventId))
      ..go();
  }

  Future _eventProcessor(Event rawEvent) async {
    // print(rawEvent);
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

///////////////////////////////////////steps相关///////////////////////////////////
///////////////////offset相关
  Future<StepOffsetData?> getStepOffset() {
    return (select(stepOffset)..where((tbl) => tbl.id.equals(1)))
        .getSingleOrNull();
  }

  Future updateStepOffset(int step, DateTime time) {
    return (update(stepOffset)..where((tbl) => tbl.id.equals(1)))
        .write(StepOffsetCompanion(step: Value(step), time: Value(time)));
  }

  Future writeStepOffset(int step, DateTime time) {
    return into(stepOffset).insert(StepOffsetCompanion(
        id: Value(1), step: Value(step), time: Value(nilTime)));
  }

  ///////////////////step相关
  Future writeStep(int step, DateTime time) {
    return into(steps)
        .insert(StepsCompanion(step: Value(step), time: Value(time)));
  }

  Future<Step?> getLatestStep() async {
    var tmp =
        await customSelect("select max(id) as id from steps").getSingleOrNull();
    if (tmp != null) {
      int id = tmp.data['id'];
      return (select(steps)..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
    } else {
      return null;
    }
  }

///////////////////step相关
  Future writeDailyStep(int step, DateTime time) {
    return into(records).insert(RecordsCompanion(
        eventId: Value(-1),
        endTime: Value(time),
        value: Value(step.toDouble())));
  }
}
