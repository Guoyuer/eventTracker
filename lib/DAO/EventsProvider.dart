import 'package:flutter/material.dart';

import 'model/Event.dart';
import 'package:sqflite/sqlite_api.dart';

import 'foundation.dart';

class EventsDbProvider {
  ///表名
  static final EventsDbProvider _ins = new EventsDbProvider.internal();

  EventsDbProvider.internal();

  factory EventsDbProvider() => _ins;

  final String name = 'events';

  final String columnId = "id";
  final String columnName = "name";
  final String columnDescription = "description";
  final String columnUnit = "unit";
  final String columnCareTime = "careTime";
  final String columnLastRecord = "lastRecord";

  void createTableHook() async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
  }

  ///插入到数据库
  Future<int> insert(EventModel event) async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
    return await db.rawInsert(
        "insert into $name ($columnName, $columnDescription, $columnUnit,$columnCareTime) values (?,?,?,?)",
        [event.name, event.description, event.unit, event.careTime]);
  }

  ///删除记录
  Future<int> delete(EventModel model) async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
    return await db
        .delete('events', where: '$columnName = ?', whereArgs: [model.name]);
  }

  ///获取事件数据
  // Future<UnitModel> getUnitInfo(int id) async {
  //   Database db = await getDataBase();
  //   List<Map<String, dynamic>> maps = await _getUnitProvider(db, id);
  //   if (maps.length > 0) {
  //     return UnitModel.fromMap(maps.first);
  //   }
  //   return null;
  // }

  Future<List<EventModelDisplay>> getEventsProfile() async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
    List<Map> tmpEvents = await db.query('events', columns: [
      columnId,
      columnName,
      columnCareTime,
      columnUnit,
      columnLastRecord
    ]);
    List<EventModelDisplay> events = [];

    for (int i = 0; i < tmpEvents.length; i++) {
      bool careTime;
      bool isActive = false;
      if (tmpEvents[i]['careTime'] == 1) {
        careTime = true;
      } else {
        careTime = false;
      }
      //检索每个events对应的状态
      if (tmpEvents[i]['lastRecord'] != null) {
        List<Map> records = await db.query('records',
            columns: ['endTime'],
            where: 'id = ?',
            whereArgs: [tmpEvents[i]['lastRecord']]);
        //只有careTime = true时，isActive才有意义
        Map record = records[0];
        if (record['endTime'] == null) {
          isActive = true;
        } else {
          isActive = false;
        }
      }
      events.add(EventModelDisplay(
          tmpEvents[i]['id'], tmpEvents[i]['name'], careTime, isActive));
    }

    return events;
  }
}
