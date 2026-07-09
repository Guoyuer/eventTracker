import 'package:drift/drift.dart';

import '../domain/activity_models.dart';
import '../domain/date_range.dart';
import '../domain/statistics_repository.dart';
import 'database/app_database.dart';

class DriftStatisticsRepository implements StatisticsRepository {
  DriftStatisticsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<StatisticsData> getStatisticsData(CalendarDateRange range) {
    final interval = range.interval;
    return _db.transaction(() async {
      final records =
          await (_db.select(_db.records)
                ..where(
                  (record) =>
                      record.endTime.isBiggerOrEqualValue(interval.start) &
                      record.endTime.isSmallerThanValue(interval.endExclusive),
                )
                ..orderBy([
                  (record) => OrderingTerm.asc(record.endTime),
                  (record) => OrderingTerm.asc(record.id),
                ]))
              .get();
      final activities = await _db.select(_db.events).get();

      return StatisticsData(
        records: [for (final record in records) _toActivityRecord(record)],
        activitiesById: {
          for (final activity in activities)
            activity.id: StatisticsActivity(
              id: activity.id,
              name: activity.name,
            ),
        },
      );
    });
  }

  ActivityRecord _toActivityRecord(Record record) {
    final endTime = record.endTime;
    if (endTime == null) {
      throw StateError('Statistics query returned active Record ${record.id}');
    }
    return ActivityRecord(
      id: record.id,
      eventId: record.eventId,
      startTime: record.startTime,
      endTime: endTime,
      value: record.value,
    );
  }
}
