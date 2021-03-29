import 'model/Event.dart';
import 'package:sqflite/sqlite_api.dart';

import 'AbstractProvider.dart';

class EventsDbProvider extends BaseDbProvider {
  ///表名
  final String name = 'events';

  final String columnId = "id";
  final String columnName = "name";
  final String columnDescription = "description";
  final String columnUnits = "units";

  EventsDbProvider();

  @override
  tableName() {
    return name;
  }

  @override
  createTableString() {
    return '''
        create table $name (
        $columnId integer primary key autoincrement,
        $columnName text unique not null,
        $columnDescription text,
        $columnUnits units
        )
      ''';
  }

  // ///查询数据库
  // Future _getUnitProvider(Database db, int id) async {
  //   List<Map<String, dynamic>> maps =
  //       await db.rawQuery("select * from $name where $columnId = $id");
  //   return maps;
  // }

  ///插入到数据库
  Future<int> insert(EventModel event) async {
    Database db = await getDataBase();
    return await db.rawInsert(
        "insert into $name ($columnName, $columnDescription, $columnUnits) values (?,?,?)",
        [event.name, event.description, event.units]);
  }

  ///删除记录
  Future<int> delete(EventModel model) async {
    Database db = await getDataBase();
    return await db
        .delete(tableName(), where: '$columnName = ?', whereArgs: [model.name]);
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

  Future<List<Map>> getEventsProfile() async {
    Database db = await getDataBase();
    List<Map> maps = await db.query(name, columns: [columnId, columnName]);
    return maps;
  }
}
