import 'model/Unit.dart';
import 'package:sqflite/sqlite_api.dart';

import 'AbstractProvider.dart';

class UnitDbProvider extends BaseDbProvider {
  ///表名
  final String name = 'units';

  final String columnId = "id";
  final String columnUnit = "unit";

  UnitDbProvider();

  @override
  tableName() {
    return name;
  }

  @override
  createTableString() {
    return '''
        create table $name (
        $columnId integer primary key autoincrement,$columnUnit text unique not null)
      ''';
  }

  ///查询数据库
  Future _getUnitProvider(Database db, int id) async {
    List<Map<String, dynamic>> maps =
        await db.rawQuery("select * from $name where $columnId = $id");
    return maps;
  }

  ///插入到数据库
  Future<int> insert(UnitModel unit) async {
    Database db = await getDataBase();
    // db.insert(table, values)
    return await db
        .rawInsert("insert into $name ($columnUnit) values (?)", [unit.unit]);
  }

  ///删除记录
  Future<int> delete(UnitModel model) async {
    Database db = await getDataBase();
    return await db
        .delete(tableName(), where: '$columnUnit = ?', whereArgs: [model.unit]);
  }

  ///获取事件数据
  Future<UnitModel> getUnitInfo(int id) async {
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await _getUnitProvider(db, id);
    if (maps.length > 0) {
      return UnitModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<String>> getAllUsers() async {
    List<String> units = List();
    Database db = await getDataBase();
    List<Map> maps = await db.query(name, columns: [columnId, columnUnit]);
    Future.delayed(Duration(seconds: 5));
    if (maps.length > 0) {
      maps.forEach((f) {
        units.add(f['unit']);
      });
    }
    return units;
  }
}
