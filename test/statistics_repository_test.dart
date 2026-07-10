import 'package:event_tracker/domain/date_range.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/domain/statistics_repository.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:event_tracker/persistence/drift_statistics_repository.dart';
import 'package:event_tracker/persistence/record_lifecycle_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/database_test_helpers.dart';
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
    final readId = await insertTestActivity(db, name: 'Read', careTime: false);
    final runId = await insertTestActivity(db, name: 'Run', careTime: false);

    await lifecycle.addPlainRecord(readId, DateTime(2026, 1, 1, 8));
    await lifecycle.addPlainRecord(runId, DateTime(2026, 1, 2, 8));

    final data = await repository.getStatisticsData(
      CalendarDateRange(
        firstDay: DateTime(2026, 1, 1),
        lastDay: DateTime(2026, 1, 3),
      ),
    );

    expect(data.records.map((record) => record.activityId), [readId, runId]);
    expect(data.activitiesById[readId]!.name, 'Read');
    expect(data.activitiesById[runId]!.name, 'Run');
  });

  test('repository excludes records outside the requested range', () async {
    final activityId = await insertTestActivity(
      db,
      name: 'Read',
      careTime: false,
    );

    await lifecycle.addPlainRecord(activityId, DateTime(2025, 12, 31, 8));
    await lifecycle.addPlainRecord(activityId, DateTime(2026, 1, 1, 8));

    final data = await repository.getStatisticsData(
      CalendarDateRange(
        firstDay: DateTime(2026, 1, 1),
        lastDay: DateTime(2026, 1, 1),
      ),
    );

    expect(data.records, hasLength(1));
    expect(
      (data.records.single as CompletedActivityRecord).endedAt,
      DateTime(2026, 1, 1, 8),
    );
  });

  test('repository includes full end day and excludes next midnight', () async {
    final activityId = await insertTestActivity(
      db,
      name: 'Read',
      careTime: false,
    );
    for (final recordedAt in [
      DateTime(2025, 12, 31, 23, 59, 59),
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 31, 23, 59, 59),
      DateTime(2026, 2, 1),
    ]) {
      await lifecycle.addPlainRecord(activityId, recordedAt);
    }

    final data = await repository.getStatisticsData(
      CalendarDateRange(
        firstDay: DateTime(2026, 1, 1),
        lastDay: DateTime(2026, 1, 31),
      ),
    );

    expect(
      data.records.map((record) => (record as CompletedActivityRecord).endedAt),
      [DateTime(2026, 1, 1), DateTime(2026, 1, 31, 23, 59, 59)],
    );
  });

  test('repository excludes active Records from Statistics', () async {
    final activityId = await insertTestActivity(
      db,
      name: 'Practice',
      careTime: true,
    );
    await lifecycle.startTimedRecord(activityId, DateTime(2026, 1, 1, 8));

    final data = await repository.getStatisticsData(
      CalendarDateRange(
        firstDay: DateTime(2026, 1, 1),
        lastDay: DateTime(2026, 1, 1),
      ),
    );

    expect(data.records, isEmpty);
    expect(data.activitiesById[activityId]!.name, 'Practice');
  });
}
