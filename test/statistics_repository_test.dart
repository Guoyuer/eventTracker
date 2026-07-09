import 'package:drift/drift.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:event_tracker/persistence/record_lifecycle_store.dart';
import 'package:event_tracker/persistence/statistics_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/database_test_harness.dart';

void main() {
  late AppDatabase db;
  late RecordLifecycleStore lifecycle;
  late StatisticsRepository repository;

  setUpAll(() {
    initializeDatabaseTestEnvironment();
  });

  setUp(() {
    db = openTestDatabase();
    lifecycle = RecordLifecycleStore(db);
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

    await lifecycle.addPlainRecord(readId, DateTime(2026, 1, 1, 8));
    await lifecycle.addPlainRecord(runId, DateTime(2026, 1, 2, 8));

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

    await lifecycle.addPlainRecord(eventId, DateTime(2025, 12, 31, 8));
    await lifecycle.addPlainRecord(eventId, DateTime(2026, 1, 1, 8));

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
