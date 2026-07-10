import '../domain/activity_models.dart';

class ActivityCount {
  ActivityCount({required this.activity, required this.count});

  final StatisticsActivity activity;
  final int count;
}

class StatisticsSummary {
  StatisticsSummary({
    required this.activityCounts,
    required this.hourlyCountsByActivityName,
  });

  final List<ActivityCount> activityCounts;
  final Map<String, List<double>> hourlyCountsByActivityName;

  int get totalCount =>
      activityCounts.fold(0, (total, activity) => total + activity.count);
}

StatisticsSummary buildStatisticsSummary({
  required List<ActivityRecord> records,
  required Map<int, StatisticsActivity> eventsById,
}) {
  final activityCountsById = <int, int>{};
  final hourlyCountsByActivityName = <String, List<double>>{};

  for (final record in records) {
    if (record is! CompletedActivityRecord) {
      continue;
    }
    final activity = _activityForRecord(record, eventsById);
    activityCountsById[record.activityId] =
        (activityCountsById[record.activityId] ?? 0) + 1;

    final hourlyCounts = hourlyCountsByActivityName.putIfAbsent(
      activity.name,
      () => List<double>.filled(24, 0),
    );
    hourlyCounts[record.endedAt.hour] += 1;
  }

  return StatisticsSummary(
    activityCounts: [
      for (final entry in activityCountsById.entries)
        ActivityCount(
          activity: _activityForId(entry.key, eventsById),
          count: entry.value,
        ),
    ],
    hourlyCountsByActivityName: hourlyCountsByActivityName,
  );
}

List<double> combineStatisticsAdjacentHourSlots(List<double> hourlyValues) {
  return [
    for (var i = 0; i < 12; i++) hourlyValues[i * 2] + hourlyValues[i * 2 + 1],
  ];
}

StatisticsActivity _activityForRecord(
  CompletedActivityRecord record,
  Map<int, StatisticsActivity> eventsById,
) {
  final activity = _activityForId(record.activityId, eventsById);
  return activity;
}

StatisticsActivity _activityForId(
  int activityId,
  Map<int, StatisticsActivity> eventsById,
) {
  final activity = eventsById[activityId];
  if (activity == null) {
    throw StateError('Missing activity $activityId.');
  }
  return activity;
}
