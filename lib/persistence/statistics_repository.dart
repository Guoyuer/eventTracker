import 'package:flutter/material.dart' show DateTimeRange;

import '../DAO/base.dart';

class StatisticsData {
  StatisticsData({
    required this.records,
    required this.activitiesById,
  });

  final List<Record> records;
  final Map<int, Event> activitiesById;
}

abstract class StatisticsRepository {
  Future<StatisticsData> getStatisticsData(DateTimeRange range);
}

class DriftStatisticsRepository implements StatisticsRepository {
  DriftStatisticsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<StatisticsData> getStatisticsData(DateTimeRange range) async {
    final records = await _db.getRecordsInRange(range);
    final activitiesById = await _db.getEventsMap();

    return StatisticsData(
      records: records,
      activitiesById: activitiesById,
    );
  }
}

StatisticsRepository statisticsRepository() {
  return DriftStatisticsRepository(DBHandle().db);
}
