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
    'version 4 migration removes legacy schema and aggregate caches',
    () async {
      final dbPath = p.join(tempDir.path, 'db.sqlite');
      await _createVersion2DatabaseWithLegacyStepData(dbPath);

      final db = AppDatabase(SqfliteQueryExecutor(path: dbPath));
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
      expect(records.single.eventId, 1);
      expect((await db.select(db.events).getSingle()).name, 'Read');

      final legacyArtifacts = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name IN "
            "('steps', 'step_offset', 'step_time')",
          )
          .get();
      expect(legacyArtifacts, isEmpty);

      final eventColumns = await db
          .customSelect('PRAGMA table_info(events)')
          .map((row) => row.read<String>('name'))
          .get();
      expect(eventColumns, isNot(contains('last_record_id')));
      expect(eventColumns, isNot(contains('sum_val')));
      expect(eventColumns, isNot(contains('sum_time')));

      final foreignKeys = await db
          .customSelect('PRAGMA foreign_key_list(records)')
          .get();
      expect(foreignKeys, hasLength(1));
      expect(foreignKeys.single.read<String>('table'), 'events');
      expect(foreignKeys.single.read<String>('on_delete'), 'CASCADE');

      final activeIndex = await db
          .customSelect(
            "SELECT sql FROM sqlite_master "
            "WHERE name = 'records_one_active_per_event'",
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

    final db = AppDatabase(SqfliteQueryExecutor(path: dbPath));
    addTearDown(db.close);

    await expectLater(db.select(db.events).get(), throwsA(anything));
  });

  test('version 5 migration normalizes existing names and units', () async {
    final dbPath = p.join(tempDir.path, 'version4.sqlite');
    await _createVersion4DatabaseWithUnnormalizedNames(dbPath);

    final db = AppDatabase(SqfliteQueryExecutor(path: dbPath));
    addTearDown(db.close);

    final activity = await db.select(db.events).getSingle();
    final unit = await db.select(db.units).getSingle();
    expect(activity.name, 'Read');
    expect(activity.unitId, unit.id);
    expect(unit.name, 'pages');
  });
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
