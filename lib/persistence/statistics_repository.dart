import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../domain/activity_models.dart';
import 'database/app_database.dart';

class StatisticsData {
  StatisticsData({
    required this.records,
    required this.activitiesById,
  });

  final List<ActivityRecord> records;
  final Map<int, StatisticsActivity> activitiesById;
}

abstract class StatisticsRepository {
  Future<StatisticsData> getStatisticsData(DateTimeRange range);
}

class DriftStatisticsRepository implements StatisticsRepository {
  DriftStatisticsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<StatisticsData> getStatisticsData(DateTimeRange range) async {
    final records = await (_db.select(_db.records)
          ..where((record) =>
              record.endTime.isBetweenValues(range.start, range.end)))
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
          activity.id: StatisticsActivity(
            id: activity.id,
            name: activity.name,
          ),
      },
    );
  }
}
