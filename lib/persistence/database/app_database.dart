import 'package:drift/drift.dart';

import 'database_bootstrap.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Units, Events, Records], include: {'sql.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? defaultDatabaseExecutor());

  @override
  int get schemaVersion => 4;

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
        await _migrateToVersion4(m);
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
}
