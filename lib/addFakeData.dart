import 'package:moor_flutter/moor_flutter.dart';
import 'DAO/base.dart';
import 'dart:math';

Future addData() async {
  await addTimingWithoutValue();
  await addTimingWithValue();
  await addPlainWithoutValue();
  await addPlainWithValue();
}

Future addTimingWithValue() async {
  var db = DBHandle().db;
  // 增加Timing Events及大量Records
  //timing with value -- start
  var event = EventsCompanion(
      name: Value("timing with value"),
      careTime: Value(true),
      unit: Value("题"));
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
    DateTime endTime = startTime.add(Duration(minutes: minutes));
    record = RecordsCompanion(
        id: Value(recordId),
        eventId: Value(eventId),
        value: Value(next(0, 10).toDouble()),
        endTime: Value(endTime));
    await db.stopTimingRecordInDB(Duration(minutes: minutes), record);
  }
  //timing without value -- end
}

Future addTimingWithoutValue() async {
  var db = DBHandle().db;
  // 增加Timing Events及大量Records
  //timing with value -- start
  var event = EventsCompanion(
      name: Value("timing without value"), careTime: Value(true));
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
    DateTime endTime = startTime.add(Duration(minutes: minutes));
    record = RecordsCompanion(
        id: Value(recordId), eventId: Value(eventId), endTime: Value(endTime));
    await db.stopTimingRecordInDB(Duration(minutes: minutes), record);
  }
  //timing without value -- end
}

Future addPlainWithValue() async {
  //plain with value --start
  var db = DBHandle().db;
  final _random = new Random();
  int next(int min, int max) => min + _random.nextInt(max - min);
  var event = EventsCompanion(
      name: Value("plain with value"),
      careTime: Value(false),
      unit: Value("题"));
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
  var event = EventsCompanion(
      name: Value("plain without value"), careTime: Value(false));
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
