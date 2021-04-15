import 'package:moor_flutter/moor_flutter.dart';
import 'DAO/base.dart';
import 'dart:math';

Future addData() async {
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
  for (int i = 1; i <= 5; i++) {
    for (int j = 1; j <= 28; j++) {
      int minutes = next(0, 60);
      var record = RecordsCompanion(
        eventId: Value(eventId),
        startTime: Value(DateTime(2021, i, j, 0, 0)),
      );
      int recordId = await db.startTimingRecordInDB(record);
      record = RecordsCompanion(
          id: Value(recordId),
          eventId: Value(eventId),
          value: Value(next(0, 10).toDouble()),
          endTime: Value(DateTime(2021, i, j, 0, minutes)));
      await db.stopTimingRecordInDB(Duration(minutes: minutes), record);
    }
    //timing with value -- end

  }

  //plain with value --start
  event = EventsCompanion(
      name: Value("plain with value"),
      careTime: Value(false),
      unit: Value("题"));
  eventId = await db.addEventInDB(event);
  for (int i = 1; i <= 5; i++) {
    for (int j = 1; j <= 28; j++) {
      for (int k = 1; k <= next(0, 20); k++) {
        int minutes = next(0, 60);
        var record = RecordsCompanion(
            eventId: Value(eventId),
            value: Value(next(0, 10).toDouble()),
            endTime: Value(DateTime(2021, i, j, 0, minutes)));
        await db.addPlainRecordInDB(record);
        //timing with value -- end
      }
    }
  }
  //plain with value --end
  return;
}
