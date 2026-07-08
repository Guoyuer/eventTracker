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

    final recordId = await repository.startTimedRecord(activityId, start);
    await repository.stopTimedRecord(
      activityId,
      recordId,
      end,
      end.difference(start),
      value: 4,
    );

    final activities = await repository.getActivities();
    final activity = activities.single as TimingEventModel;

    expect(activity.id, activityId);
    expect(activity.status, EventStatus.notActive);
    expect(activity.sumDuration, const Duration(minutes: 25));
    expect(activity.sumVal, 4);
  });
}
