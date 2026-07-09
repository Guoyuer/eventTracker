import 'package:drift/drift.dart';

import '../domain/activity_models.dart';
import '../domain/date_range.dart';
import 'database/app_database.dart';

class StatisticsData {
  StatisticsData({required this.records, required this.activitiesById});

  final List<ActivityRecord> records;
  final Map<int, StatisticsActivity> activitiesById;
}

abstract class StatisticsRepository {
  Future<StatisticsData> getStatisticsData(DateRange range);
}

class DriftStatisticsRepository implements StatisticsRepository {
  DriftStatisticsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<StatisticsData> getStatisticsData(DateRange range) async {
    final records =
        await (_db.select(_db.records)..where(
              (record) =>
                  record.endTime.isBetweenValues(range.start, range.end),
            ))
            .get();
    final activities = await _db.select(_db.events).get();

    return StatisticsData(
      records: [
        for (final record in records)
          ActivityRecord(
            id: record.id,
            eventId: record.eventId,
            startTime: record.startTime,
            endTime: record.endTime!,
            value: record.value,
          ),
      ],
      activitiesById: {
        for (final activity in activities)
          activity.id: StatisticsActivity(id: activity.id, name: activity.name),
      },
    );
  }
}
