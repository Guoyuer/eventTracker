import 'package:drift/drift.dart' hide isNull;
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/domain/activity_repository.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:event_tracker/persistence/drift_activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/database_test_helpers.dart';
import 'support/database_test_harness.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repository;

  setUpAll(() {
    initializeDatabaseTestEnvironment();
  });

  setUp(() {
    db = openTestDatabase();
    repository = DriftActivityRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'repository records a plain activity without exposing database companions',
    () async {
      final activityId = await insertTestActivity(
        db,
        name: 'Questions',
        careTime: false,
        unit: 'questions',
      );

      await repository.addPlainRecord(
        activityId,
        DateTime(2026, 1, 1, 8),
        value: 3,
      );

      final activities = await repository.getActivities();
      final activity = activities.single as PlainActivity;

      expect(activity.id, activityId);
      expect(activity.occurrenceCount, 1);
      expect(activity.totalValue, 3);
    },
  );

  test(
    'repository creates an activity without exposing database companions',
    () async {
      final activityId = await repository.createActivity(
        name: 'Read',
        careTime: false,
        unit: 'pages',
        description: 'Books and articles',
      );

      final activity = await getTestActivity(db, activityId);

      expect(activity.name, 'Read');
      expect(activity.careTime, false);
      expect(activity.unit, 'pages');
      expect(activity.description, 'Books and articles');
    },
  );

  test('repository keeps database uniqueness for activity names', () async {
    await repository.createActivity(name: 'Read', careTime: false);

    expect(
      repository.createActivity(name: 'Read', careTime: true),
      throwsA(anything),
    );
  });

  test(
    'repository reads one Activity Snapshot by id and fails when absent',
    () async {
      final readId = await repository.createActivity(
        name: 'Read',
        careTime: false,
      );
      await repository.createActivity(name: 'Run', careTime: true);

      final activity = await repository.getActivity(readId);

      expect(activity, isA<PlainActivity>());
      expect(activity.id, readId);
      expect(repository.getActivity(404), throwsStateError);
    },
  );

  test(
    'active snapshot derives from Records instead of cached lastRecordId',
    () async {
      final activityId = await repository.createActivity(
        name: 'Practice',
        careTime: true,
      );
      final startedAt = DateTime(2026, 1, 1, 8);
      await repository.startTimedRecord(activityId, startedAt);
      await (db.update(db.events)
            ..where((event) => event.id.equals(activityId)))
          .write(const EventsCompanion(lastRecordId: Value(null)));

      final activity = await repository.getActivity(activityId);

      expect(activity, isA<ActiveTimedActivity>());
      expect((activity as ActiveTimedActivity).startedAt, startedAt);
    },
  );

  test(
    'snapshot fails fast when a Timed Activity has two active Records',
    () async {
      final activityId = await repository.createActivity(
        name: 'Practice',
        careTime: true,
      );
      for (final startedAt in [
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 9),
      ]) {
        await db
            .into(db.records)
            .insert(
              RecordsCompanion(
                eventId: Value(activityId),
                startTime: Value(startedAt),
              ),
            );
      }

      expect(repository.getActivity(activityId), throwsStateError);
    },
  );

  test(
    'snapshot fails fast when an active Timed Record has no start',
    () async {
      final activityId = await repository.createActivity(
        name: 'Practice',
        careTime: true,
      );
      await db
          .into(db.records)
          .insert(RecordsCompanion(eventId: Value(activityId)));

      expect(repository.getActivity(activityId), throwsStateError);
    },
  );

  test(
    'snapshot fails fast when a Plain Activity has an active Record',
    () async {
      final activityId = await repository.createActivity(
        name: 'Read',
        careTime: false,
      );
      await db
          .into(db.records)
          .insert(
            RecordsCompanion(
              eventId: Value(activityId),
              startTime: Value(DateTime(2026, 1, 1, 8)),
            ),
          );

      expect(repository.getActivity(activityId), throwsStateError);
    },
  );

  test('repository reads records for one activity', () async {
    final firstActivityId = await repository.createActivity(
      name: 'Read',
      careTime: false,
    );
    final secondActivityId = await repository.createActivity(
      name: 'Run',
      careTime: false,
    );

    await repository.addPlainRecord(firstActivityId, DateTime(2026, 1, 1, 8));
    await repository.addPlainRecord(secondActivityId, DateTime(2026, 1, 1, 9));

    final records = await repository.getActivityRecords(firstActivityId);

    expect(records, hasLength(1));
    expect(records.single.eventId, firstActivityId);
  });

  test('repository updates activity description', () async {
    final activityId = await repository.createActivity(
      name: 'Read',
      careTime: false,
      description: 'Initial',
    );

    await repository.updateActivityDescription(activityId, 'Updated');

    expect(await repository.getActivityDescription(activityId), 'Updated');
  });

  test('repository deletes an activity with its records', () async {
    final activityId = await repository.createActivity(
      name: 'Read',
      careTime: false,
    );
    await repository.addPlainRecord(activityId, DateTime(2026, 1, 1, 8));

    await repository.deleteActivity(activityId);

    expect(() => getTestActivity(db, activityId), throwsA(anything));
    expect(await repository.getActivityRecords(activityId), isEmpty);
  });

  test(
    'repository completes a timed activity without exposing database companions',
    () async {
      final activityId = await insertTestActivity(
        db,
        name: 'Run',
        careTime: true,
        unit: 'km',
      );
      final start = DateTime(2026, 1, 1, 8);
      final end = DateTime(2026, 1, 1, 8, 25);

      await repository.startTimedRecord(activityId, start);
      await repository.stopActiveTimedRecord(activityId, end, value: 4);

      final activities = await repository.getActivities();
      final activity = activities.single as InactiveTimedActivity;

      expect(activity.id, activityId);
      expect(activity.totalDuration, const Duration(minutes: 25));
      expect(activity.totalValue, 4);
    },
  );

  test(
    'repository stops the active timed record using the provided stop time',
    () async {
      final activityId = await repository.createActivity(
        name: 'Practice',
        careTime: true,
      );
      final start = DateTime(2026, 1, 1, 8);
      final stoppedAt = DateTime(2026, 1, 1, 8, 25);

      await repository.startTimedRecord(activityId, start);
      await repository.stopActiveTimedRecord(activityId, stoppedAt);

      final activity =
          (await repository.getActivities()).single as InactiveTimedActivity;
      final records = await repository.getActivityRecords(activityId);

      expect(activity.totalDuration, const Duration(minutes: 25));
      expect(records.single.startTime, start);
      expect(records.single.endTime, stoppedAt);
    },
  );

  test(
    'repository fails fast when stopping without an active timed record',
    () async {
      final activityId = await repository.createActivity(
        name: 'Practice',
        careTime: true,
      );

      expect(
        repository.stopActiveTimedRecord(activityId, DateTime(2026, 1, 1, 8)),
        throwsStateError,
      );
    },
  );

  test(
    'repository cancels an active timed record without accumulating totals',
    () async {
      final activityId = await repository.createActivity(
        name: 'Practice',
        careTime: true,
      );
      final firstStart = DateTime(2026, 1, 1, 8);
      final activeStart = DateTime(2026, 1, 1, 9);

      await repository.startTimedRecord(activityId, firstStart);
      await repository.stopActiveTimedRecord(
        activityId,
        DateTime(2026, 1, 1, 8, 10),
      );
      final activeRecordId = await repository.startTimedRecord(
        activityId,
        activeStart,
      );

      await repository.cancelActiveTimedRecord(activityId);

      final activity =
          (await repository.getActivities()).single as InactiveTimedActivity;
      final canceledRecord = await (db.select(
        db.records,
      )..where((record) => record.id.equals(activeRecordId))).getSingleOrNull();

      expect(canceledRecord, isNull);
      expect(activity.totalDuration, const Duration(minutes: 10));
    },
  );

  test('repository repairs drifted aggregate totals', () async {
    final activityId = await repository.createActivity(
      name: 'Questions',
      careTime: false,
      unit: 'questions',
    );
    await repository.addPlainRecord(
      activityId,
      DateTime(2026, 1, 1, 8),
      value: 3,
    );
    await repository.addPlainRecord(
      activityId,
      DateTime(2026, 1, 2, 8),
      value: 5,
    );
    await _corruptAggregateTotals(
      db,
      activityId,
      lastRecordId: null,
      sumTime: const Duration(days: 99),
      sumValue: 999,
    );

    await repository.repairAggregateTotals();

    final activity = (await repository.getActivities()).single as PlainActivity;
    final records = await getCompletedTestRecordsForActivity(db, activityId);
    final storedActivity = await getTestActivity(db, activityId);

    expect(storedActivity.lastRecordId, records.last.id);
    expect(activity.occurrenceCount, 2);
    expect(activity.totalValue, 8);
  });

  test('repository repair preserves active timed records', () async {
    final activityId = await repository.createActivity(
      name: 'Practice',
      careTime: true,
      unit: 'pages',
    );
    final firstRecordId = await repository.startTimedRecord(
      activityId,
      DateTime(2026, 1, 1, 8),
    );
    await repository.stopActiveTimedRecord(
      activityId,
      DateTime(2026, 1, 1, 8, 10),
      value: 4,
    );
    final activeRecordId = await repository.startTimedRecord(
      activityId,
      DateTime(2026, 1, 1, 9),
    );
    await _corruptAggregateTotals(
      db,
      activityId,
      lastRecordId: firstRecordId,
      sumTime: const Duration(days: 99),
      sumValue: 999,
    );

    await repository.repairAggregateTotals();

    final storedActivity = await getTestActivity(db, activityId);
    final activity =
        (await repository.getActivities()).single as ActiveTimedActivity;

    expect(storedActivity.lastRecordId, activeRecordId);
    expect(storedActivity.sumTime, const Duration(minutes: 10));
    expect(storedActivity.sumVal, 4);
    expect(activity.startedAt, DateTime(2026, 1, 1, 9));
    expect(activity.totalDuration, const Duration(minutes: 10));
  });
}

Future<void> _corruptAggregateTotals(
  AppDatabase db,
  int activityId, {
  required int? lastRecordId,
  required Duration sumTime,
  required double sumValue,
}) async {
  await (db.update(
    db.events,
  )..where((event) => event.id.equals(activityId))).write(
    EventsCompanion(
      lastRecordId: Value(lastRecordId),
      sumTime: Value(sumTime),
      sumVal: Value(sumValue),
    ),
  );
}
