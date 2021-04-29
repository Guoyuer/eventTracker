import 'package:flutter_event_tracker/common/util.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'DAO/base.dart';
import 'dart:math';

Future addData() async {
  // await addTimingWithoutValue();
  // await addTimingWithValue();
  // await addPlainWithoutValue();
  // await addPlainWithValue();
  await addStepData();
}

Future addTimingWithValue() async {
  var db = DBHandle().db;
  // 增加Timing Events及大量Records
  //timing with value -- start
  var event = EventsCompanion(
      name: Value("跑步"), careTime: Value(true), unit: Value("千米"));
  int eventId = await db.addEventInDB(event);
  final _random = new Random();
  int next(int min, int max) => min + _random.nextInt(max - min);
  for (int i = 300; i >= 0; i--) {
    int minutes = next(0, 60);
    DateTime startTime = DateTime.now().add(Duration(days: -i));
    var record = RecordsCompanion(
      eventId: Value(eventId),
      startTime: Value(startTime),
    );
    int recordId = await db.startTimingRecordInDB(record);
    DateTime endTime = startTime.add(Duration(minutes: minutes, seconds: 1));
    record = RecordsCompanion(
        id: Value(recordId),
        eventId: Value(eventId),
        value: Value(next(0, 10).toDouble()),
        endTime: Value(endTime));
    await db.stopTimingRecordInDB(
        Duration(minutes: minutes, seconds: 1), record);
  }
  //timing without value -- end
}

Future addTimingWithoutValue() async {
  var db = DBHandle().db;
  // 增加Timing Events及大量Records
  //timing with value -- start
  var event = EventsCompanion(name: Value("读课外书"), careTime: Value(true));
  int eventId = await db.addEventInDB(event);
  final _random = new Random();
  int next(int min, int max) => min + _random.nextInt(max - min);
  for (int i = 300; i >= 0; i--) {
    int minutes = next(0, 60);
    DateTime startTime = DateTime.now().add(Duration(days: -i));
    var record = RecordsCompanion(
      eventId: Value(eventId),
      startTime: Value(startTime),
    );
    int recordId = await db.startTimingRecordInDB(record);
    DateTime endTime = startTime.add(Duration(minutes: minutes, seconds: 1));
    record = RecordsCompanion(
        id: Value(recordId), eventId: Value(eventId), endTime: Value(endTime));
    await db.stopTimingRecordInDB(
        Duration(minutes: minutes, seconds: 1), record);
  }
  //timing without value -- end
}

Future addPlainWithValue() async {
  //plain with value --start
  var db = DBHandle().db;
  final _random = new Random();
  int next(int min, int max) => min + _random.nextInt(max - min);
  var event = EventsCompanion(
      name: Value("做算法题"), careTime: Value(false), unit: Value("题"));
  var eventId = await db.addEventInDB(event);
  for (int j = 300; j >= 0; j--) {
    for (int k = 1; k <= next(0, 20); k++) {
      var record = RecordsCompanion(
          eventId: Value(eventId),
          value: Value(next(0, 10).toDouble()),
          endTime: Value(DateTime.now().add(Duration(days: -j))));
      await db.addPlainRecordInDB(record);
      //timing with value -- end
    }
  }
  return;
  //plain with value --end
}

Future addPlainWithoutValue() async {
  //plain with value --start
  var db = DBHandle().db;
  final _random = new Random();
  int next(int min, int max) => min + _random.nextInt(max - min);
  var event = EventsCompanion(name: Value("吃冰淇淋"), careTime: Value(false));
  var eventId = await db.addEventInDB(event);
  for (int j = 300; j >= 0; j--) {
    for (int k = 1; k <= next(0, 20); k++) {
      var record = RecordsCompanion(
          eventId: Value(eventId),
          endTime: Value(
              DateTime.now().add(Duration(days: -j, minutes: next(6, 50)))));
      await db.addPlainRecordInDB(record);
      //timing with value -- end
    }
  }
  return;
  //plain with value --end
}

Future addStepData() async {
  final _random = new Random();
  var db = DBHandle().db;
  int next(int min, int max) => min + _random.nextInt(max - min);
  var time = DateTime(2021, 1, 10, 9);
  for (int i = 0; i < 100; i++) {
    time = getDate(time.add(Duration(days: 1))).add(Duration(hours: 9));
    int step = 0; //步数
    for (int k = 0; k < 12; k++) {
      time = time.add(Duration(minutes: next(0, 80)));
      step += next(0, 1000);
      db.writeStep(step, time);
    }
    db.writeDailyStep(step, time);
  }
}
