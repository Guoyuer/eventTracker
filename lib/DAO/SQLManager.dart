import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLManager {
  static const _NAME = "EventTracker.db";

  static Database _database;

  ///初始化
  static init() async {
    // ignore: deprecated_member_use
    Sqflite.devSetDebugModeOn(true);
    var databasesPath = await getDatabasesPath();

    String path = join(databasesPath, _NAME);

    _database = await openDatabase(path,
        version: 1, onCreate: (Database db, int version) async {});
    // print(await _database.query("sqlite_master"));
    _database.rawQuery("PRAGMA journal_mode=DELETE");
  }

  ///判断表是否存在
  static isTableExits(String tableName) async {
    await getCurrentDatabase();
    var res = await _database.rawQuery(
        "select * from Sqlite_master where type = 'table' and name = '$tableName'");
    return res != null && res.length > 0;
  }

  ///获取当前数据库对象
  static Future<Database> getCurrentDatabase() async {
    if (_database == null) {
      await init();
    }
    return _database;
  }

  ///关闭
  static close() {
    _database?.close();
    _database = null;
  }
}
