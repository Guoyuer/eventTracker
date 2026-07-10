import 'package:drift/drift.dart';

import 'database_bootstrap.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Units, Events, Records], include: {'sql.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? defaultDatabaseExecutor());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA synchronous = OFF');
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
        await _migrateToVersion4(m);
      } else if (from < 5) {
        await _migrateToVersion5(m);
      }
    },
  );

  Future<void> _migrateToVersion3() async {
    await customStatement('DELETE FROM records WHERE event_id = -1');
    await customStatement('DROP INDEX IF EXISTS step_time');
    await customStatement('DROP TABLE IF EXISTS step_offset');
    await customStatement('DROP TABLE IF EXISTS steps');
  }

  Future<void> _migrateToVersion4(Migrator migrator) async {
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

    await migrator.alterTable(TableMigration(events));
    await migrator.alterTable(TableMigration(records));
    await customStatement(
      'CREATE INDEX IF NOT EXISTS records_end_time ON records(end_time)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS records_start_time ON records(start_time)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS records_event_id ON records(event_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS records_one_active_per_event '
      'ON records(event_id) WHERE end_time IS NULL',
    );
  }

  Future<void> _migrateToVersion5(Migrator migrator) async {
    await _prepareDataForVersion5();
    await migrator.alterTable(TableMigration(events));
    await migrator.alterTable(TableMigration(units));
    await migrator.alterTable(TableMigration(records));
  }

  Future<void> _prepareDataForVersion5() async {
    await _validateNamesForVersion5('events');
    await _validateNamesForVersion5('units');

    final invalidValue = await customSelect('''
      SELECT id FROM records
      WHERE value IS NOT NULL
        AND abs(value) > 1.7976931348623157e308
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
}
