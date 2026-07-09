import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:event_tracker/DAO/base.dart';
import 'package:event_tracker/common/const.dart';
import 'package:event_tracker/persistence/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    db = AppDatabase(SqfliteQueryExecutor(path: inMemoryDatabasePath));
    repository = DriftActivityRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'repository records a plain activity without exposing database companions',
      () async {
    final activityId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Questions'),
        careTime: const Value(false),
        unit: const Value('questions'),
      ),
    );

    await repository.addPlainRecord(
      activityId,
      DateTime(2026, 1, 1, 8),
      value: 3,
    );

    final activities = await repository.getActivities();
    final activity = activities.single as PlainEventModel;

    expect(activity.id, activityId);
    expect(activity.time, 1);
    expect(activity.sumVal, 3);
  });

  test('repository creates an activity without exposing database companions',
      () async {
    final activityId = await repository.createActivity(
      name: 'Read',
      careTime: false,
      unit: 'pages',
      description: 'Books and articles',
    );

    final activity = await db.getEventById(activityId);

    expect(activity.name, 'Read');
    expect(activity.careTime, false);
    expect(activity.unit, 'pages');
    expect(activity.description, 'Books and articles');
  });

  test('repository keeps database uniqueness for activity names', () async {
    await repository.createActivity(name: 'Read', careTime: false);

    expect(
      repository.createActivity(name: 'Read', careTime: true),
      throwsA(anything),
    );
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

    await repository.addPlainRecord(
      firstActivityId,
      DateTime(2026, 1, 1, 8),
    );
    await repository.addPlainRecord(
      secondActivityId,
      DateTime(2026, 1, 1, 9),
    );

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
    await repository.addPlainRecord(
      activityId,
      DateTime(2026, 1, 1, 8),
    );

    await repository.deleteActivity(activityId);

    expect(() => db.getEventById(activityId), throwsA(anything));
    expect(await repository.getActivityRecords(activityId), isEmpty);
  });

  test(
      'repository completes a timed activity without exposing database companions',
      () async {
    final activityId = await db.addEventInDB(
      EventsCompanion(
        name: const Value('Run'),
        careTime: const Value(true),
        unit: const Value('km'),
      ),
    );
    final start = DateTime(2026, 1, 1, 8);
    final end = DateTime(2026, 1, 1, 8, 25);

    await repository.startTimedRecord(activityId, start);
    await repository.stopActiveTimedRecord(activityId, end, value: 4);

    final activities = await repository.getActivities();
    final activity = activities.single as TimingEventModel;

    expect(activity.id, activityId);
    expect(activity.status, EventStatus.notActive);
    expect(activity.sumDuration, const Duration(minutes: 25));
    expect(activity.sumVal, 4);
  });

  test('repository stops the active timed record using the provided stop time',
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
        (await repository.getActivities()).single as TimingEventModel;
    final records = await repository.getActivityRecords(activityId);

    expect(activity.status, EventStatus.notActive);
    expect(activity.sumDuration, const Duration(minutes: 25));
    expect(records.single.startTime, start);
    expect(records.single.endTime, stoppedAt);
  });

  test('repository fails fast when stopping without an active timed record',
      () async {
    final activityId = await repository.createActivity(
      name: 'Practice',
      careTime: true,
    );

    expect(
      repository.stopActiveTimedRecord(activityId, DateTime(2026, 1, 1, 8)),
      throwsStateError,
    );
  });
}
