import 'package:drift/drift.dart';

import '../../domain/input_validation.dart';
import 'database_bootstrap.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Units, Activities, Records], include: {'sql.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? defaultDatabaseExecutor());

  /// 改动此值前必须先运行:
  ///   dart run drift_dev schema dump lib/persistence/database/app_database.dart drift_schemas/
  ///   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
  /// 然后在 test/schema_verifier_test.dart 中为新版本加一条 migrateAndValidate 用例。
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
      await _ensureRecordValueTriggers();
    },
    onCreate: (Migrator m) {
      return m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        await _migrateToVersion3();
      }
      if (from < 4) {
        await _prepareDataForVersion5();
        await _migrateToVersion4();
      } else if (from < 5) {
        await _migrateToVersion5(m);
      }
      if (from < 6) {
        await _migrateToVersion6();
      }
      if (from < 7) {
        await _migrateToVersion7();
      }
    },
  );

  Future<void> _migrateToVersion3() async {
    await customStatement('DELETE FROM records WHERE event_id = -1');
    await customStatement('DROP INDEX IF EXISTS step_time');
    await customStatement('DROP TABLE IF EXISTS step_offset');
    await customStatement('DROP TABLE IF EXISTS steps');
  }

  Future<void> _migrateToVersion4() async {
    final malformedRecord = await customSelect('''
      SELECT records.id
      FROM records
      LEFT JOIN events ON events.id = records.event_id
      WHERE events.id IS NULL
         OR (events.care_time = 0 AND (
              records.start_time IS NOT NULL OR records.end_time IS NULL
            ))
         OR (events.care_time = 1 AND (
              records.start_time IS NULL OR
              (records.end_time IS NULL AND records.value IS NOT NULL) OR
              (records.end_time IS NOT NULL AND
               records.end_time < records.start_time)
            ))
      LIMIT 1
    ''').getSingleOrNull();
    if (malformedRecord != null) {
      throw StateError(
        'Cannot migrate malformed Record ${malformedRecord.read<int>('id')}',
      );
    }

    final duplicateActive = await customSelect('''
      SELECT event_id
      FROM records
      WHERE end_time IS NULL
      GROUP BY event_id
      HAVING COUNT(*) > 1
      LIMIT 1
    ''').getSingleOrNull();
    if (duplicateActive != null) {
      throw StateError(
        'Cannot migrate Activity '
        '${duplicateActive.read<int>('event_id')} with multiple active Records',
      );
    }
  }

  Future<void> _migrateToVersion5(Migrator migrator) async {
    await _prepareDataForVersion5();
    await migrator.alterTable(TableMigration(units));
  }

  Future<void> _prepareDataForVersion5() async {
    await _validateNamesForVersion5('events');
    await _validateNamesForVersion5('units');

    final invalidValue = await customSelect('''
      SELECT id FROM records
      WHERE value IS NOT NULL
        AND abs(value) > $maxRecordValue
      LIMIT 1
    ''').getSingleOrNull();
    if (invalidValue != null) {
      throw StateError(
        'Cannot migrate non-finite Record value '
        '${invalidValue.read<int>('id')}',
      );
    }

    await customStatement('UPDATE events SET name = trim(name)');
    await customStatement(
      "UPDATE events SET unit = NULLIF(trim(unit), '') WHERE unit IS NOT NULL",
    );
    await customStatement('UPDATE units SET name = trim(name)');
  }

  Future<void> _validateNamesForVersion5(String table) async {
    final blankName = await customSelect(
      'SELECT id FROM $table WHERE length(trim(name)) = 0 LIMIT 1',
    ).getSingleOrNull();
    if (blankName != null) {
      throw StateError(
        'Cannot migrate blank $table name ${blankName.read<int>('id')}',
      );
    }

    final duplicateName = await customSelect('''
      SELECT lower(trim(name)) AS normalized_name
      FROM $table
      GROUP BY lower(trim(name))
      HAVING COUNT(*) > 1
      LIMIT 1
    ''').getSingleOrNull();
    if (duplicateName != null) {
      throw StateError(
        'Cannot migrate duplicate $table name '
        '${duplicateName.read<String>('normalized_name')}',
      );
    }
  }

  Future<void> _migrateToVersion6() async {
    final danglingUnit = await customSelect('''
      SELECT events.id FROM events
      LEFT JOIN units ON units.name = events.unit
      WHERE events.unit IS NOT NULL AND units.id IS NULL
      LIMIT 1
    ''').getSingleOrNull();
    if (danglingUnit != null) {
      throw StateError(
        'Cannot migrate Activity ${danglingUnit.read<int>('id')} '
        'with an unknown Unit',
      );
    }

    await customStatement('ALTER TABLE events RENAME TO events_legacy');
    await customStatement('ALTER TABLE records RENAME TO records_legacy');
    await customStatement('''
      CREATE TABLE events (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE
          CHECK (name = trim(name) AND length(name) > 0),
        description TEXT NULL,
        care_time INTEGER NOT NULL CHECK (care_time IN (0, 1)),
        unit_id INTEGER NULL REFERENCES units(id) ON DELETE RESTRICT
      )
    ''');
    await customStatement('''
      INSERT INTO events (id, name, description, care_time, unit_id)
      SELECT events_legacy.id, events_legacy.name, events_legacy.description,
        events_legacy.care_time,
        (SELECT units.id FROM units WHERE units.name = events_legacy.unit)
      FROM events_legacy
    ''');
    await customStatement('''
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
        CHECK (value IS NULL OR abs(value) <= $maxRecordValue)
      )
    ''');
    await customStatement('''
      INSERT INTO records (id, event_id, start_time, end_time, value)
      SELECT id, event_id, start_time, end_time, value FROM records_legacy
    ''');
    await customStatement('DROP TABLE records_legacy');
    await customStatement('DROP TABLE events_legacy');
    await customStatement('CREATE INDEX records_end_time ON records(end_time)');
    await customStatement(
      'CREATE INDEX records_start_time ON records(start_time)',
    );
    await customStatement('CREATE INDEX records_event_id ON records(event_id)');
    await customStatement(
      'CREATE UNIQUE INDEX records_one_active_per_event '
      'ON records(event_id) WHERE end_time IS NULL',
    );
  }

  Future<void> _migrateToVersion7() async {
    await customStatement('ALTER TABLE events RENAME TO events_v6');
    await customStatement('ALTER TABLE records RENAME TO records_v6');

    await customStatement('''
      CREATE TABLE activities (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL COLLATE NOCASE UNIQUE
          CHECK (name = trim(name) AND length(name) > 0),
        description TEXT NULL,
        care_time INTEGER NOT NULL CHECK (care_time IN (0, 1)),
        unit_id INTEGER NULL REFERENCES units(id) ON DELETE RESTRICT
      )
    ''');
    await customStatement('''
      INSERT INTO activities (id, name, description, care_time, unit_id)
      SELECT id, name, description, care_time, unit_id FROM events_v6
    ''');
    await customStatement('''
      CREATE TABLE records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        activity_id INTEGER NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
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
    await customStatement('''
      INSERT INTO records (id, activity_id, start_time, end_time, value)
      SELECT id, event_id, start_time, end_time, value FROM records_v6
    ''');
    await customStatement('DROP TABLE records_v6');
    await customStatement('DROP TABLE events_v6');
    await customStatement('CREATE INDEX records_end_time ON records(end_time)');
    await customStatement(
      'CREATE INDEX records_start_time ON records(start_time)',
    );
    await customStatement(
      'CREATE INDEX records_activity_id ON records(activity_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX records_one_active_per_activity '
      'ON records(activity_id) WHERE end_time IS NULL',
    );
  }

  Future<void> _ensureRecordValueTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS records_value_matches_activity_unit_insert
      BEFORE INSERT ON records
      BEGIN
        SELECT CASE
          WHEN (SELECT unit_id FROM activities WHERE id = NEW.activity_id)
                 IS NULL AND NEW.value IS NOT NULL
          THEN RAISE(ABORT, 'Unitless Activities cannot have Record values')
          WHEN (SELECT unit_id FROM activities WHERE id = NEW.activity_id)
                 IS NOT NULL
               AND NEW.end_time IS NOT NULL
               AND (NEW.value IS NULL OR NEW.value <= 0
                    OR abs(NEW.value) > 1000000000000000.0)
          THEN RAISE(ABORT, 'Unit-backed Activities require positive Record values')
        END;
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS records_value_matches_activity_unit_update
      BEFORE UPDATE OF activity_id, end_time, value ON records
      BEGIN
        SELECT CASE
          WHEN (SELECT unit_id FROM activities WHERE id = NEW.activity_id)
                 IS NULL AND NEW.value IS NOT NULL
          THEN RAISE(ABORT, 'Unitless Activities cannot have Record values')
          WHEN (SELECT unit_id FROM activities WHERE id = NEW.activity_id)
                 IS NOT NULL
               AND NEW.end_time IS NOT NULL
               AND (NEW.value IS NULL OR NEW.value <= 0
                    OR abs(NEW.value) > 1000000000000000.0)
          THEN RAISE(ABORT, 'Unit-backed Activities require positive Record values')
        END;
      END
    ''');
  }
}
