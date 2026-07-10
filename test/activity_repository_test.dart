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

  setUp(() async {
    db = openTestDatabase();
    repository = DriftActivityRepository(db);
    for (final name in ['pages', 'km', 'questions']) {
      await db.into(db.units).insert(UnitsCompanion(name: Value(name)));
    }
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
      expect(activity.unitId, isA<int>());
      expect(activity.description, 'Books and articles');
    },
  );

  test('repository keeps database uniqueness for activity names', () async {
    await repository.createActivity(name: 'Read', careTime: false);

    expect(
      repository.createActivity(name: 'READ', careTime: true),
      throwsA(anything),
    );
  });

  test('repository normalizes activity names and optional units', () async {
    final activityId = await repository.createActivity(
      name: '  Read  ',
      careTime: false,
      unit: '   ',
    );

    final activity = await repository.getActivity(activityId);
    expect(activity.name, 'Read');
    expect(activity.unit, isNull);
    expect(
      repository.createActivity(name: '   ', careTime: false),
      throwsArgumentError,
    );
  });

  test('repository rejects an Activity with an unknown Unit', () async {
    expect(
      repository.createActivity(name: 'Swim', careTime: true, unit: 'laps'),
      throwsStateError,
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

  test('snapshot derives active state and totals from Records', () async {
    final activityId = await repository.createActivity(
      name: 'Practice',
      careTime: true,
      unit: 'km',
    );
    await repository.startTimedRecord(activityId, DateTime(2026, 1, 1, 8));
    await repository.stopActiveTimedRecord(
      activityId,
      DateTime(2026, 1, 1, 8, 25),
      value: 3,
    );
    final activeStartedAt = DateTime(2026, 1, 1, 9);
    await repository.startTimedRecord(activityId, activeStartedAt);

    final activity = await repository.getActivity(activityId);

    expect(activity, isA<ActiveTimedActivity>());
    expect((activity as ActiveTimedActivity).startedAt, activeStartedAt);
    expect(activity.totalDuration, const Duration(minutes: 25));
    expect(activity.totalValue, 3);
  });

  test('snapshot rejects Record shapes for the wrong Activity type', () async {
    final plainId = await repository.createActivity(
      name: 'Read',
      careTime: false,
    );
    final timedId = await repository.createActivity(
      name: 'Practice',
      careTime: true,
    );
    await db
        .into(db.records)
        .insert(
          RecordsCompanion(
            eventId: Value(plainId),
            startTime: Value(DateTime(2026, 1, 1, 8)),
            endTime: Value(DateTime(2026, 1, 1, 9)),
          ),
        );
    await db
        .into(db.records)
        .insert(
          RecordsCompanion(
            eventId: Value(timedId),
            endTime: Value(DateTime(2026, 1, 1, 9)),
          ),
        );

    expect(repository.getActivity(plainId), throwsStateError);
    expect(repository.getActivity(timedId), throwsStateError);
  });

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
}
