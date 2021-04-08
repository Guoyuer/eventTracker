import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Helper {
  static final Helper _instance = new Helper.internal();

  Helper.internal();

  factory Helper() => _instance;

  static Database _db;

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  initDb() async {
    Sqflite.devSetDebugModeOn(true);
    var databasesPath = await getDatabasesPath();

    String path = join(databasesPath, 'EventTracker.db');

    // print(await _database.query("sqlite_master"));

    var theDb = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // events表
      await db.execute('''
        create table events
        (
          id integer
            constraint events_pk
              primary key autoincrement,
          name text not null
            unique,
          description text,
          careTime integer not null,
          unit text,
          lastRecord integer
        )
        ''');
      await db
          .execute('''create unique index events_id_uindex on events (id)''');

      //record表
      await db.execute('''
        create table records
        (
          id integer
            constraint records_pk
              primary key autoincrement,
          eventId integer not null,
          startTime text,
          endTime text,
          value real,
          duration integer
        )
          ''');
      await db.execute('''create index records_eventId_index
          on records (eventId)''');
      await db.execute('''create unique index records_id_uindex
          on records (id)''');
      // units表
      await db.execute('''create table units (
        id integer primary key autoincrement,
        unit text unique not null)''');
    });
    theDb.rawQuery("PRAGMA journal_mode=DELETE");
    return theDb;
  }

  Future close() async {
    var dbClient = await db;
    dbClient.close();
  }
}
