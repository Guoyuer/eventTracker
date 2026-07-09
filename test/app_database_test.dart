import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:event_tracker/persistence/record_lifecycle_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/database_test_harness.dart';

void main() {
  late AppDatabase db;
  late RecordLifecycleStore lifecycle;

  setUpAll(() {
    initializeDatabaseTestEnvironment();
  });

  setUp(() {
    db = openTestDatabase();
    lifecycle = RecordLifecycleStore(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('plain records update aggregate count, value, and last record',
      () async {
    final eventId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Push ups'),
        careTime: const Value(false),
        unit: const Value('reps'),
      ),
    );

    await lifecycle.addPlainRecord(
      eventId,
      DateTime(2026, 1, 1, 8),
      value: 20,
    );

    final event = await db.getEventById(eventId);
    final records = await db.getRecordsByEventId(eventId);

    expect(records, hasLength(1));
    expect(event.lastRecordId, records.single.id);
    expect(event.sumTime.inSeconds, 1);
    expect(event.sumVal, 20);
  });

  test('plain record aggregates accumulate across multiple records', () async {
    final eventId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Pages'),
        careTime: const Value(false),
        unit: const Value('pages'),
      ),
    );

    await lifecycle.addPlainRecord(
      eventId,
      DateTime(2026, 1, 1, 8),
      value: 12,
    );
    await lifecycle.addPlainRecord(
      eventId,
      DateTime(2026, 1, 2, 8),
      value: 8,
    );

    final event = await db.getEventById(eventId);
    final records = await db.getRecordsByEventId(eventId);

    expect(records, hasLength(2));
    expect(event.lastRecordId, records.last.id);
    expect(event.sumTime.inSeconds, 2);
    expect(event.sumVal, 20);
  });

  test('timed record start and stop update active state and totals', () async {
    final eventId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Reading'),
        careTime: const Value(true),
      ),
    );
    final start = DateTime(2026, 1, 1, 8);
    final end = DateTime(2026, 1, 1, 8, 30);

    final recordId = await lifecycle.startTimedRecord(eventId, start);

    var event = await db.getEventById(eventId);
    var record = await db.getRecordById(recordId);
    expect(event.lastRecordId, recordId);
    expect(record.endTime, isNull);

    await lifecycle.stopActiveTimedRecord(eventId, end);

    event = await db.getEventById(eventId);
    record = await db.getRecordById(recordId);
    expect(record.endTime, end);
    expect(event.sumTime, end.difference(start));
  });

  test('timed record stop accumulates duration and value', () async {
    final eventId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Running'),
        careTime: const Value(true),
        unit: const Value('km'),
      ),
    );

    await lifecycle.startTimedRecord(
      eventId,
      DateTime(2026, 1, 1, 8),
    );
    await lifecycle.stopActiveTimedRecord(
      eventId,
      DateTime(2026, 1, 1, 8, 20),
      value: 3,
    );

    final secondRecordId = await lifecycle.startTimedRecord(
      eventId,
      DateTime(2026, 1, 2, 8),
    );
    await lifecycle.stopActiveTimedRecord(
      eventId,
      DateTime(2026, 1, 2, 8, 30),
      value: 5,
    );

    final event = await db.getEventById(eventId);

    expect(event.lastRecordId, secondRecordId);
    expect(event.sumTime, const Duration(minutes: 50));
    expect(event.sumVal, 8);
  });

  test('canceling an active timed record restores previous last record',
      () async {
    final eventId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Practice'),
        careTime: const Value(true),
      ),
    );

    final firstRecordId = await lifecycle.startTimedRecord(
      eventId,
      DateTime(2026, 1, 1, 8),
    );
    await lifecycle.stopActiveTimedRecord(
      eventId,
      DateTime(2026, 1, 1, 8, 10),
    );

    final activeRecordId = await lifecycle.startTimedRecord(
      eventId,
      DateTime(2026, 1, 1, 9),
    );

    await lifecycle.cancelActiveTimedRecord(eventId);

    final event = await db.getEventById(eventId);
    final deletedRecord = await (db.select(db.records)
          ..where((record) => record.id.equals(activeRecordId)))
        .getSingleOrNull();

    expect(deletedRecord, isNull);
    expect(event.lastRecordId, firstRecordId);
  });

  test('default database executor uses explicit paths on desktop only', () {
    expect(
      usesExplicitDatabasePathOnPlatform(
        TargetPlatform.windows,
        isWeb: false,
      ),
      isTrue,
    );
    expect(
      usesExplicitDatabasePathOnPlatform(
        TargetPlatform.macOS,
        isWeb: false,
      ),
      isTrue,
    );
    expect(
      usesExplicitDatabasePathOnPlatform(
        TargetPlatform.linux,
        isWeb: false,
      ),
      isTrue,
    );
    expect(
      usesExplicitDatabasePathOnPlatform(
        TargetPlatform.android,
        isWeb: false,
      ),
      isFalse,
    );
    expect(
      usesExplicitDatabasePathOnPlatform(
        TargetPlatform.windows,
        isWeb: true,
      ),
      isFalse,
    );
  });
}
