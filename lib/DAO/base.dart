import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'package:moor_flutter/moor_flutter.dart';

part 'model/displayModel.dart';

part 'base.g.dart';

//tables and converters
class DurationConverter extends TypeConverter<Duration, double> {
  const DurationConverter();

  @override
  Duration mapToDart(double fromDb) {
    return Duration(seconds: fromDb.toInt());
  }

  @override
  double mapToSql(Duration value) {
    return value.inSeconds.toDouble();
  }
}

// class Units extends Table {
//   IntColumn get id => integer().autoIncrement()();
//
//   TextColumn get name => text().customConstraint("not null unique")();
// }

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint("not null unique")();

  TextColumn get description => text().nullable()();

  BoolColumn get careTime => boolean()();

  IntColumn get lastRecordId => integer().nullable()(); //初次添加时可空
  TextColumn get unit => text().nullable()();

  //冗余信息，加速列表显示
  RealColumn get sumVal => real().withDefault(Constant(0))();

  RealColumn get sumTime => real()
      .withDefault(Constant(0)) // 对于TimingEvent以秒的形式记录总时间，对于PlainEvent则记录次数
      .map(const DurationConverter())();
}

class Records extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get eventId => integer()();

  DateTimeColumn get startTime => dateTime().nullable()();

  //startTime可为空，当不careTime的事件开始时

  DateTimeColumn get endTime =>
      dateTime().nullable()(); //endTime可为空，当careTime的事件开始时。

  RealColumn get value => real().nullable()();
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
}

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

@UseMoor(tables: [Events, Records, Units])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: "db.sqlite", logStatements: true));

  @override
  int get schemaVersion => 2;

  // @override
  // MigrationStrategy get migration => MigrationStrategy(beforeOpen: (_) {
  //       return customStatement("pragma journal_mode=delete");
  //     });
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

  ///得到recordId对应记录的开始时间
  Future<DateTime> getStartTime(int recordId) async {
    final query = selectOnly(records)
      ..addColumns([records.startTime])
      ..where(records.id.equals(recordId));
    return query.map((row) => row.read(records.startTime)).getSingle();
  }

  ///得到eventId对应事件的LastRecordId
  Future<int> getLastRecordId(int eventId) async {
    Event event = await (select(events)
          ..where((event) => event.id.equals(eventId)))
        .getSingle();
    return event.lastRecordId;
  }

  ///得到所有的记录
  Future<List<Record>> getAllRecords(int eventId) =>
      (select(records)..where((tbl) => tbl.eventId.equals(eventId))).get();

  ///////////////////record.add类

  /// 添加plain record in DB
  Future addPlainRecordInDB(RecordsCompanion record) async {
    assert(record.endTime != Value.absent());
    assert(record.eventId != Value.absent());
    int recordId = await into(records).insert(record);
    int eventId = record.eventId.value;
    await customUpdate(
        "update events set sum_time = sum_time + 1, last_record_id = $recordId where id = $eventId"); //step 1 更新Events的lastRecordId和sumTime
    if (record.value != Value.absent() && record.value.value != 0) {
      double val = record.value.value;
      return customUpdate(
          "update events set sum_val = sum_val + $val where id = $eventId"); //step 2 有值才更新Events的sumVal
    } else {
      return;
    }
  }

  Future startTimingRecordInDB(RecordsCompanion record) async {
    assert(record.startTime != Value.absent());
    assert(record.eventId != Value.absent());
    int recordId = await into(records).insert(record);
    int eventId = record.eventId.value;
    return customUpdate(
        "update events set last_record_id = $recordId where id = $eventId");
  }

  Future stopTimingRecordInDB(
      Duration thisDuration, RecordsCompanion record) async {
    assert(record.id != Value.absent());
    assert(record.eventId != Value.absent());
    int eventId = record.eventId.value;
    int recordId = record.id.value;
    update(records)
      ..where((record) => record.id.equals(recordId))
      ..write(RecordsCompanion(
          endTime: Value(DateTime.now()), value: record.value));

    Duration sumTime = await getEventSumTime(eventId);
    sumTime += thisDuration;
    update(events)
      ..where((event) => event.id.equals(eventId))
      ..write(EventsCompanion(sumTime: Value(sumTime)));

    if (record.value != Value.absent() && record.value.value != 0) {
      double val = record.value.value;
      return customUpdate(
          "update events set sum_val = sum_val + $val where id = $eventId");
    } else {
      return;
    }
  }

  Future deleteActiveTimingRecordInDB(int recordId, int eventId) async {
    (delete(records)..where((tbl) => tbl.id.equals(recordId)))
        .go(); //step1 删除recordId对应记录

    Record formerRecord =
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

  Future<Duration> getEventSumTime(int eventId) async {
    Event event = await (select(events)..where((tbl) => tbl.id.equals(eventId)))
        .getSingle();
    return event.sumTime;
  }

  Future<double> getEventSumVal(int eventId) {
    final query = (selectOnly(events)..addColumns([events.sumVal]))
      ..where(events.id.equals(eventId));
    return query.map((row) => row.read(events.sumVal)).getSingle();
  }

  Future<String> getEventUnit(int eventId) async {
    final query = selectOnly(events)
      ..addColumns([events.unit])
      ..where(events.id.equals(eventId));

    return query.map((row) => row.read(events.unit)).getSingle();
  }

  ///返回成功或失败
  bool addEventInDB(Map<String, dynamic> res) {
    if (res == null || res.isEmpty) return false; //直接返回相当于pop时没带数据，就不写
    var event = EventsCompanion(
        name: Value(res['eventName']),
        description: Value(res['eventDesc']),
        careTime: Value(res['careTime']),
        unit: Value(res['unit']));
    into(events).insert(event).then((value) {
      print(res);
      print("插入Event成功");
      return true;
    }).catchError((err) {
      print(err);
      showToast("创建项目失败，可能是因为重名");
      return false;
    });
    return false;
  }

  Future<List<Event>> getRawEvents() {
    return select(events).get();
  }

  Future _eventProcessor(Event rawEvent) async {
    // print(rawEvent);
    Future<TimingEventDisplayModel> timingEventProcessor(Event rawEvent) async {
      if (rawEvent.lastRecordId == null) {
        // 当前还无记录（新创建且未开始的的event）
        return TimingEventDisplayModel(rawEvent.id, rawEvent.name,
            rawEvent.unit, false, Duration(seconds: 0), null, 0);
      } else {
        //当前已有记录
        var record = await getRecordById(rawEvent.lastRecordId);
        if (record.endTime == null) {
          return TimingEventDisplayModel(
              rawEvent.id,
              rawEvent.name,
              rawEvent.unit,
              true,
              rawEvent.sumTime,
              record.startTime,
              rawEvent.sumVal);
        } else {
          return TimingEventDisplayModel(rawEvent.id, rawEvent.name,
              rawEvent.unit, false, rawEvent.sumTime, null, rawEvent.sumVal);
        }
      }
    }

    Future<PlainEventDisplayModel> plainEventProcessor(Event rawEvent) async {
      return PlainEventDisplayModel(rawEvent.id, rawEvent.name, rawEvent.unit,
          rawEvent.sumTime.inSeconds, rawEvent.sumVal);
    }

    if (rawEvent.careTime)
      return timingEventProcessor(rawEvent);
    else
      return plainEventProcessor(rawEvent);
  }

  Future<List<BaseEventDisplayModel>> getEventsProfile() async {
    var rawEvents = await getRawEvents();
    List<BaseEventDisplayModel> events = [];
    for (var event in rawEvents) {
      events.add(await _eventProcessor(event));
    }

    return events;
  }
}
