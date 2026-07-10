import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/database_test_harness.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    initializeDatabaseTestEnvironment();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('event_tracker_migration_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'latest migration removes legacy schema and preserves records',
    () async {
      final dbPath = p.join(tempDir.path, 'db.sqlite');
      await _createVersion2DatabaseWithLegacyStepData(dbPath);

      final db = AppDatabase(executor: SqfliteQueryExecutor(path: dbPath));
      addTearDown(db.close);

      final records =
          await (db.select(db.records)..where(
                (record) => record.endTime.isBetweenValues(
                  DateTime(2026, 1, 1),
                  DateTime(2026, 1, 2),
                ),
              ))
              .get();

      expect(records, hasLength(1));
      expect(records.single.activityId, 1);
      expect((await db.select(db.activities).getSingle()).name, 'Read');

      final legacyArtifacts = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name IN "
            "('steps', 'step_offset', 'step_time')",
          )
          .get();
      expect(legacyArtifacts, isEmpty);

      final activityColumns = await db
          .customSelect('PRAGMA table_info(activities)')
          .map((row) => row.read<String>('name'))
          .get();
      expect(activityColumns, isNot(contains('last_record_id')));
      expect(activityColumns, isNot(contains('sum_val')));
      expect(activityColumns, isNot(contains('sum_time')));

      final foreignKeys = await db
          .customSelect('PRAGMA foreign_key_list(records)')
          .get();
      expect(foreignKeys, hasLength(1));
      expect(foreignKeys.single.read<String>('table'), 'activities');
      expect(foreignKeys.single.read<String>('on_delete'), 'CASCADE');

      final activeIndex = await db
          .customSelect(
            "SELECT sql FROM sqlite_master "
            "WHERE name = 'records_one_active_per_activity'",
          )
          .getSingle();
      expect(
        activeIndex.read<String>('sql'),
        contains('WHERE end_time IS NULL'),
      );
    },
  );

  test('version 4 migration rejects malformed record history', () async {
    final dbPath = p.join(tempDir.path, 'malformed.sqlite');
    await _createVersion3DatabaseWithMalformedHistory(dbPath);

    final db = AppDatabase(executor: SqfliteQueryExecutor(path: dbPath));
    addTearDown(db.close);

    await expectLater(db.select(db.activities).get(), throwsStateError);
  });

  test('version 5 migration normalizes existing names and units', () async {
    final dbPath = p.join(tempDir.path, 'version4.sqlite');
    await _createVersion4DatabaseWithUnnormalizedNames(dbPath);

    final db = AppDatabase(executor: SqfliteQueryExecutor(path: dbPath));
    addTearDown(db.close);

    final activity = await db.select(db.activities).getSingle();
    final unit = await db.select(db.units).getSingle();
    expect(activity.name, 'Read');
    expect(activity.unitId, unit.id);
    expect(unit.name, 'pages');
  });

  test(
    'version 6 migration retains Activities, Records, and foreign keys',
    () async {
      final dbPath = p.join(tempDir.path, 'version6.sqlite');
      await _createVersion6Database(dbPath);

      final db = AppDatabase(executor: SqfliteQueryExecutor(path: dbPath));
      addTearDown(db.close);

      final activity = await db.select(db.activities).getSingle();
      final record = await db.select(db.records).getSingle();
      expect(activity.id, 7);
      expect(activity.name, 'Read');
      expect(record.id, 11);
      expect(record.activityId, activity.id);

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name IN ('events', 'activities')",
          )
          .map((row) => row.read<String>('name'))
          .get();
      expect(tables, ['activities']);

      final recordColumns = await db
          .customSelect('PRAGMA table_info(records)')
          .map((row) => row.read<String>('name'))
          .get();
      expect(recordColumns, contains('activity_id'));
      expect(recordColumns, isNot(contains('event_id')));

      final foreignKeys = await db
          .customSelect('PRAGMA foreign_key_list(records)')
          .get();
      expect(foreignKeys.single.read<String>('table'), 'activities');
      expect(foreignKeys.single.read<String>('on_delete'), 'CASCADE');

      await (db.delete(
        db.activities,
      )..where((row) => row.id.equals(activity.id))).go();
      expect(await db.select(db.records).get(), isEmpty);
    },
  );
}

Future<void> _createVersion2DatabaseWithLegacyStepData(String dbPath) async {
  final rawDb = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    await rawDb.execute('''
      CREATE TABLE events (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NULL,
        care_time INTEGER NOT NULL,
        last_record_id INTEGER NULL,
        unit TEXT NULL,
        sum_val REAL NOT NULL DEFAULT 0,
        sum_time REAL NOT NULL DEFAULT 0
      );
    ''');
    await rawDb.execute('''
      CREATE TABLE records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        start_time INTEGER NULL,
        end_time INTEGER NULL,
        value REAL NULL
      );
    ''');
    await rawDb.execute('''
      CREATE TABLE units (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    ''');
    await rawDb.execute('''
      CREATE TABLE steps (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        step INTEGER NOT NULL DEFAULT 0,
        time INTEGER NOT NULL
      );
    ''');
    await rawDb.execute('''
      CREATE TABLE step_offset (
        id INTEGER NOT NULL,
        step INTEGER NOT NULL DEFAULT 0,
        time INTEGER NOT NULL
      );
    ''');
    await rawDb.execute('CREATE INDEX step_time ON steps(time);');
    await rawDb.execute('CREATE INDEX records_end_time ON records(end_time);');
    await rawDb.execute(
      'CREATE INDEX records_start_time ON records(start_time);',
    );
    await rawDb.execute('CREATE INDEX records_event_id ON records(event_id);');

    await rawDb.insert('events', {
      'id': 1,
      'name': '  Read  ',
      'care_time': 0,
      'last_record_id': 1,
      'sum_val': 0,
      'sum_time': 1,
    });
    await rawDb.insert('records', {
      'id': 1,
      'event_id': 1,
      'end_time': _toDriftTimestamp(DateTime(2026, 1, 1, 8)),
    });
    await rawDb.insert('records', {
      'id': 2,
      'event_id': -1,
      'end_time': _toDriftTimestamp(DateTime(2026, 1, 1, 9)),
      'value': 5000,
    });
    await rawDb.insert('steps', {
      'id': 1,
      'step': 5000,
      'time': _toDriftTimestamp(DateTime(2026, 1, 1)),
    });

    await rawDb.execute('PRAGMA user_version = 2;');
  } finally {
    await rawDb.close();
  }
}

int _toDriftTimestamp(DateTime value) {
  return value.millisecondsSinceEpoch ~/ 1000;
}

Future<void> _createVersion3DatabaseWithMalformedHistory(String dbPath) async {
  final rawDb = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    await rawDb.execute('''
      CREATE TABLE events (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NULL,
        care_time INTEGER NOT NULL,
        last_record_id INTEGER NULL,
        unit TEXT NULL,
        sum_val REAL NOT NULL DEFAULT 0,
        sum_time REAL NOT NULL DEFAULT 0
      );
    ''');
    await rawDb.execute('''
      CREATE TABLE records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        start_time INTEGER NULL,
        end_time INTEGER NULL,
        value REAL NULL
      );
    ''');
    await rawDb.execute('''
      CREATE TABLE units (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    ''');
    await rawDb.insert('events', {'id': 1, 'name': 'Read', 'care_time': 0});
    await rawDb.insert('records', {
      'id': 1,
      'event_id': 1,
      'start_time': _toDriftTimestamp(DateTime(2026, 1, 1, 8)),
      'end_time': _toDriftTimestamp(DateTime(2026, 1, 1, 9)),
    });
    await rawDb.execute('PRAGMA user_version = 3;');
  } finally {
    await rawDb.close();
  }
}

Future<void> _createVersion4DatabaseWithUnnormalizedNames(String dbPath) async {
  final rawDb = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    await rawDb.execute('''
      CREATE TABLE events (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NULL,
        care_time INTEGER NOT NULL,
        unit TEXT NULL
      );
    ''');
    await rawDb.execute('''
      CREATE TABLE records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        start_time INTEGER NULL,
        end_time INTEGER NULL,
        value REAL NULL
      );
    ''');
    await rawDb.execute('''
      CREATE TABLE units (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    ''');
    await rawDb.insert('events', {
      'id': 1,
      'name': '  Read  ',
      'care_time': 0,
      'unit': '  pages  ',
    });
    await rawDb.insert('units', {'id': 1, 'name': '  pages  '});
    await rawDb.insert('records', {
      'id': 1,
      'event_id': 1,
      'end_time': _toDriftTimestamp(DateTime(2026, 1, 1, 8)),
    });
    await rawDb.execute('PRAGMA user_version = 4;');
  } finally {
    await rawDb.close();
  }
}

Future<void> _createVersion6Database(String dbPath) async {
  final rawDb = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    await rawDb.execute('''
      CREATE TABLE units (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE
          CHECK (name = trim(name) AND length(name) > 0)
      )
    ''');
    await rawDb.execute('''
      CREATE TABLE events (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE
          CHECK (name = trim(name) AND length(name) > 0),
        description TEXT NULL,
        care_time INTEGER NOT NULL,
        unit_id INTEGER NULL REFERENCES units(id) ON DELETE RESTRICT
      )
    ''');
    await rawDb.execute('''
      CREATE TABLE records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        start_time INTEGER NULL,
        end_time INTEGER NULL,
        value REAL NULL,
        CHECK (
          (start_time IS NULL AND end_time IS NOT NULL) OR
          (start_time IS NOT NULL AND end_time IS NULL AND value IS NULL) OR
          (start_time IS NOT NULL AND end_time IS NOT NULL
            AND end_time >= start_time)
        ),
        CHECK (value IS NULL OR abs(value) <= 1000000000000000.0)
      )
    ''');
    await rawDb.execute('CREATE INDEX records_end_time ON records(end_time)');
    await rawDb.execute(
      'CREATE INDEX records_start_time ON records(start_time)',
    );
    await rawDb.execute('CREATE INDEX records_event_id ON records(event_id)');
    await rawDb.execute(
      'CREATE UNIQUE INDEX records_one_active_per_event '
      'ON records(event_id) WHERE end_time IS NULL',
    );
    await rawDb.insert('units', {'id': 3, 'name': 'pages'});
    await rawDb.insert('events', {
      'id': 7,
      'name': 'Read',
      'description': 'Books',
      'care_time': 0,
      'unit_id': 3,
    });
    await rawDb.insert('records', {
      'id': 11,
      'event_id': 7,
      'end_time': _toDriftTimestamp(DateTime(2026, 1, 1, 8)),
      'value': 12,
    });
    await rawDb.execute('PRAGMA user_version = 6');
  } finally {
    await rawDb.close();
  }
}
