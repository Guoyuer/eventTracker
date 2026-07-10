import 'package:drift/drift.dart' hide isNull;
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:event_tracker/persistence/database/database_bootstrap.dart';
import 'package:event_tracker/persistence/record_lifecycle_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/database_test_helpers.dart';
import 'support/database_test_harness.dart';

void main() {
  late AppDatabase db;
  late RecordLifecycleStore lifecycle;

  setUpAll(initializeDatabaseTestEnvironment);

  setUp(() {
    db = openTestDatabase();
    lifecycle = RecordLifecycleStore(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('plain lifecycle writes completed records', () async {
    final activityId = await insertTestActivity(
      db,
      name: 'Push ups',
      careTime: false,
      unit: 'reps',
    );

    await lifecycle.addPlainRecord(
      activityId,
      DateTime(2026, 1, 1, 8),
      value: 20,
    );

    final records = await getCompletedTestRecordsForActivity(db, activityId);
    expect(records, hasLength(1));
    expect(records.single.startTime, isNull);
    expect(records.single.endTime, DateTime(2026, 1, 1, 8));
    expect(records.single.value, 20);
  });

  test('lifecycle rejects missing activities without orphan records', () async {
    await expectLater(
      lifecycle.addPlainRecord(404, DateTime(2026, 1, 1, 8)),
      throwsA(anything),
    );
    await expectLater(
      lifecycle.startTimedRecord(404, DateTime(2026, 1, 1, 8)),
      throwsA(anything),
    );

    expect(await db.select(db.records).get(), isEmpty);
  });

  test(
    'lifecycle rejects record operations for the wrong activity type',
    () async {
      final plainId = await insertTestActivity(
        db,
        name: 'Push ups',
        careTime: false,
      );
      final timedId = await insertTestActivity(
        db,
        name: 'Reading',
        careTime: true,
      );

      await expectLater(
        lifecycle.addPlainRecord(timedId, DateTime(2026, 1, 1, 8)),
        throwsStateError,
      );
      await expectLater(
        lifecycle.startTimedRecord(plainId, DateTime(2026, 1, 1, 8)),
        throwsStateError,
      );
      await expectLater(
        lifecycle.stopActiveTimedRecord(plainId, DateTime(2026, 1, 1, 9)),
        throwsStateError,
      );
      await expectLater(
        lifecycle.cancelActiveTimedRecord(plainId),
        throwsStateError,
      );

      expect(await db.select(db.records).get(), isEmpty);
    },
  );

  test('timed lifecycle starts and completes one record', () async {
    final activityId = await insertTestActivity(
      db,
      name: 'Reading',
      careTime: true,
    );
    final startedAt = DateTime(2026, 1, 1, 8);
    final stoppedAt = DateTime(2026, 1, 1, 8, 30);

    final recordId = await lifecycle.startTimedRecord(activityId, startedAt);
    expect((await getTestRecord(db, recordId)).endTime, isNull);

    await lifecycle.stopActiveTimedRecord(activityId, stoppedAt, value: 3);

    final record = await getTestRecord(db, recordId);
    expect(record.startTime, startedAt);
    expect(record.endTime, stoppedAt);
    expect(record.value, 3);
  });

  test(
    'second timed start fails without replacing the active record',
    () async {
      final activityId = await insertTestActivity(
        db,
        name: 'Reading',
        careTime: true,
      );
      final firstStart = DateTime(2026, 1, 1, 8);
      final firstId = await lifecycle.startTimedRecord(activityId, firstStart);

      await expectLater(
        lifecycle.startTimedRecord(activityId, DateTime(2026, 1, 1, 9)),
        throwsStateError,
      );

      final records = await db.select(db.records).get();
      expect(records, hasLength(1));
      expect(records.single.id, firstId);
      expect(records.single.startTime, firstStart);
    },
  );

  test('stop before start rolls back and leaves the record active', () async {
    final activityId = await insertTestActivity(
      db,
      name: 'Reading',
      careTime: true,
    );
    final recordId = await lifecycle.startTimedRecord(
      activityId,
      DateTime(2026, 1, 1, 9),
    );

    await expectLater(
      lifecycle.stopActiveTimedRecord(activityId, DateTime(2026, 1, 1, 8)),
      throwsStateError,
    );

    expect((await getTestRecord(db, recordId)).endTime, isNull);
  });

  test('cancel removes only the active timed record', () async {
    final activityId = await insertTestActivity(
      db,
      name: 'Practice',
      careTime: true,
    );
    final completedId = await lifecycle.startTimedRecord(
      activityId,
      DateTime(2026, 1, 1, 8),
    );
    await lifecycle.stopActiveTimedRecord(
      activityId,
      DateTime(2026, 1, 1, 8, 10),
    );
    final activeId = await lifecycle.startTimedRecord(
      activityId,
      DateTime(2026, 1, 1, 9),
    );

    await lifecycle.cancelActiveTimedRecord(activityId);

    expect(await getTestRecord(db, completedId), isA<Record>());
    expect(
      await (db.select(
        db.records,
      )..where((row) => row.id.equals(activeId))).getSingleOrNull(),
      isNull,
    );
  });

  test('database constraints reject malformed record shapes', () async {
    final activityId = await insertTestActivity(
      db,
      name: 'Reading',
      careTime: true,
    );
    final invalidRecords = [
      RecordsCompanion(eventId: Value(activityId)),
      RecordsCompanion(
        eventId: Value(activityId),
        startTime: Value(DateTime(2026, 1, 1, 8)),
        value: const Value(1),
      ),
      RecordsCompanion(
        eventId: Value(activityId),
        startTime: Value(DateTime(2026, 1, 1, 9)),
        endTime: Value(DateTime(2026, 1, 1, 8)),
      ),
    ];

    for (final record in invalidRecords) {
      await expectLater(db.into(db.records).insert(record), throwsA(anything));
    }
    expect(await db.select(db.records).get(), isEmpty);
  });

  test(
    'database enforces one active record and activity foreign key',
    () async {
      final activityId = await insertTestActivity(
        db,
        name: 'Reading',
        careTime: true,
      );
      await lifecycle.startTimedRecord(activityId, DateTime(2026, 1, 1, 8));

      await expectLater(
        db
            .into(db.records)
            .insert(
              RecordsCompanion(
                eventId: Value(activityId),
                startTime: Value(DateTime(2026, 1, 1, 9)),
              ),
            ),
        throwsA(anything),
      );
      await expectLater(
        db
            .into(db.records)
            .insert(
              RecordsCompanion(
                eventId: const Value(404),
                endTime: Value(DateTime(2026, 1, 1, 9)),
              ),
            ),
        throwsA(anything),
      );
    },
  );

  test('record lifecycle rejects non-finite numeric values', () async {
    final plainId = await insertTestActivity(
      db,
      name: 'Questions',
      careTime: false,
    );
    final timedId = await insertTestActivity(
      db,
      name: 'Running',
      careTime: true,
    );
    await lifecycle.startTimedRecord(timedId, DateTime(2026, 1, 1, 8));

    await expectLater(
      lifecycle.addPlainRecord(
        plainId,
        DateTime(2026, 1, 1, 8),
        value: double.nan,
      ),
      throwsArgumentError,
    );
    await expectLater(
      lifecycle.stopActiveTimedRecord(
        timedId,
        DateTime(2026, 1, 1, 9),
        value: double.infinity,
      ),
      throwsArgumentError,
    );

    expect(await getCompletedTestRecordsForActivity(db, plainId), isEmpty);
    expect((await db.select(db.records).get()).single.endTime, isNull);
  });

  test('default database executor uses explicit paths on desktop only', () {
    expect(
      usesExplicitDatabasePathOnPlatform(TargetPlatform.windows, isWeb: false),
      isTrue,
    );
    expect(
      usesExplicitDatabasePathOnPlatform(TargetPlatform.macOS, isWeb: false),
      isTrue,
    );
    expect(
      usesExplicitDatabasePathOnPlatform(TargetPlatform.linux, isWeb: false),
      isTrue,
    );
    expect(
      usesExplicitDatabasePathOnPlatform(TargetPlatform.android, isWeb: false),
      isFalse,
    );
    expect(
      usesExplicitDatabasePathOnPlatform(TargetPlatform.windows, isWeb: true),
      isFalse,
    );
  });
}
