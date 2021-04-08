import 'model/Unit.dart';
import 'package:sqflite/sqlite_api.dart';

import 'foundation.dart';

class UnitsDbProvider {
  ///表名
  final String name = 'units';

  final String columnId = "id";
  final String columnUnit = "unit";

  static final UnitsDbProvider _ins = new UnitsDbProvider.internal();

  UnitsDbProvider.internal();

  factory UnitsDbProvider() => _ins;

  ///插入到数据库
  Future<int> insert(UnitModel unit) async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
    // db.insert(table, values)
    return await db
        .rawInsert("insert into $name ($columnUnit) values (?)", [unit.unit]);
  }

  ///删除记录
  Future<int> delete(UnitModel model) async {
    var dbHelper = Helper();
    var db = await dbHelper.db;
    return await db
        .delete('units', where: '$columnUnit = ?', whereArgs: [model.unit]);
  }

  Future<List<String>> getAllUnits() async {
    List<String> units = List();
    var dbHelper = Helper();
    var db = await dbHelper.db;
    List<Map> maps = await db.query(name, columns: [columnId, columnUnit]);
    if (maps.length > 0) {
      maps.forEach((f) {
        units.add(f['unit']);
      });
    }
    return units;
  }
}
