import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:event_tracker/DAO/base.dart';
import 'package:event_tracker/persistence/statistics_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;
  late StatisticsRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    db = AppDatabase(SqfliteQueryExecutor(path: inMemoryDatabasePath));
    repository = DriftStatisticsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('repository loads range records with activities by id', () async {
    final readId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Read'),
        careTime: const Value(false),
      ),
    );
    final runId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Run'),
        careTime: const Value(false),
      ),
    );

    await db.addPlainRecordInDB(
      RecordsCompanion(
        eventId: Value(readId),
        endTime: Value(DateTime(2026, 1, 1, 8)),
      ),
    );
    await db.addPlainRecordInDB(
      RecordsCompanion(
        eventId: Value(runId),
        endTime: Value(DateTime(2026, 1, 2, 8)),
      ),
    );

    final data = await repository.getStatisticsData(
      DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 3),
      ),
    );

    expect(data.records.map((record) => record.eventId), [readId, runId]);
    expect(data.activitiesById[readId]!.name, 'Read');
    expect(data.activitiesById[runId]!.name, 'Run');
  });

  test('repository excludes records outside the requested range', () async {
    final eventId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Read'),
        careTime: const Value(false),
      ),
    );

    await db.addPlainRecordInDB(
      RecordsCompanion(
        eventId: Value(eventId),
        endTime: Value(DateTime(2025, 12, 31, 8)),
      ),
    );
    await db.addPlainRecordInDB(
      RecordsCompanion(
        eventId: Value(eventId),
        endTime: Value(DateTime(2026, 1, 1, 8)),
      ),
    );

    final data = await repository.getStatisticsData(
      DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 2),
      ),
    );

    expect(data.records, hasLength(1));
    expect(data.records.single.endTime, DateTime(2026, 1, 1, 8));
  });
}
