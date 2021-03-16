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
  Future insert(UnitModel unit) async {
    Database db = await getDataBase();
    return await db.rawInsert(
        "insert into $name ($columnId,$columnUnit) values (?,?)",
        [unit.id, unit.unit]);
  }

  ///更新数据库
  // Future<void> update(UnitModel model) async {
  //   Database database = await getDataBase();
  //   await database.rawUpdate(
  //       "update $name set $columnMobile = ?,$columnHeadImage = ? where $columnId= ?",
  //       [model.mobile, model.headImage, model.id]);
  // }

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
    if (maps.length > 0) {
      maps.forEach((f) {
        units.add(f['unit']);
      });
    }
    return units;
  }
}
