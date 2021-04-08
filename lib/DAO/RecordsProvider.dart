import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'model/Record.dart';
import 'package:sqflite/sqlite_api.dart';

import 'foundation.dart';

class RecordsUtils {
  ///表名
  static String name = 'records';

  static final RecordsUtils _ins = new RecordsUtils.internal();

  RecordsUtils.internal();

  factory RecordsUtils() => _ins;

  static Future<int> eventId2RecordId(int eventId) async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
    var tmp = await db.query('events',
        columns: ['lastRecord'], where: 'id = ?', whereArgs: [eventId]);
    return tmp[0]['lastRecord'];
  }

  static Future<void> deleteRecord(int eventId) async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
    int recordId = await eventId2RecordId(eventId);
    await db.rawDelete("delete from records where id = $recordId");
    //然后记得更新lastRecord
    List<Map> formerRecord = await db.rawQuery(
        "select id from records where eventId = $eventId order by startTime DESC LIMIT 1");

    int formerRecordId = formerRecord[0]['id'];
    await db.rawUpdate("update events set lastRecord = $formerRecordId");
    Fluttertoast.showToast(
        msg: "该记录未保留",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  static Future<void> stopRecord(int eventId, BuildContext context) async {
    int recordId = await eventId2RecordId(eventId);
    var dbHelper = Helper();
    var db = await dbHelper.db;
    var tmp =
        await db.rawQuery("select startTime from records where Id = $recordId");
    var startTime = DateTime.parse(tmp[0]['startTime']);
    var fiveSeconds = Duration(seconds: 5);
    if (DateTime.now().difference(startTime).compareTo(fiveSeconds) < 0) {
      bool delete = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("时间不足5s，删除还是继续"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("删除")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text("继续"))
              ],
            );
          });
      print("是否删除");
      print(delete);
      if (delete) {
        await deleteRecord(eventId);
        return;
      } else {
        Fluttertoast.showToast(
            msg: "继续",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.blueAccent,
            textColor: Colors.white,
            fontSize: 16.0);
        return;
      }
    }
    print(DateTime.now().difference(startTime).toString());
    // 未弹出对话框的情况

    String now = DateTime.now().toString();
    await db
        .rawUpdate("update records set endTime = '$now' where Id = $recordId");
  }

  ///插入到数据库
  static Future<void> writeRecord(RecordModel recordModel) async {
    int eventId = recordModel.eventId;
    int recordId = await insert(recordModel); // 最先的await一定最先执行
    var dbHelper = Helper();
    var db = await dbHelper.db;
    await db.rawUpdate('''
      update events
      set lastRecord = $recordId
      where id = $eventId;
    ''');
  }

  static Future<int> insert(RecordModel record) async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
// db.insert(table, values)
    return await db.rawInsert(
        "insert into $name (eventId, startTime, endTime, value, duration) values (?,?,?,?,?)",
        [
          record.eventId,
          record.startTime,
          record.endTime,
          record.value,
          record.duration
        ]);
  }

  ///删除记录
  Future<int> delete(RecordModel model) async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
    return await db.delete('records', where: 'id = ?', whereArgs: [model.id]);
  }

  static Future<List<RecordModel>> getAllRecords(int eventId) async {
    List<RecordModel> records = [];
    var dbHelper = Helper();
    var db = await dbHelper.db;
    List<Map> maps =
        await db.rawQuery("select * from records where eventId = $eventId");
    if (maps.length > 0) {
      maps.forEach((f) {
        double val;
        if (f['value'] != null)
          val = double.parse(f['value']);
        else
          val = -1;
        records.add(RecordModel(eventId,
            id: f['id'],
            startTime: DateTime.parse(f['startTime']),
            endTime: DateTime.parse(f['endTime']),
            value: val));
      });
    }
    return records;
  }
}
