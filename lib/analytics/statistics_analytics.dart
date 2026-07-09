import 'dart:collection';

import '../DAO/base.dart';

class ActivityCount {
  ActivityCount({
    required this.activity,
    required this.count,
  });

  final Event activity;
  final int count;
}

class StatisticsSummary {
  StatisticsSummary({
    required this.activityCounts,
    required this.hourlyCountsByActivityName,
  });

  final List<ActivityCount> activityCounts;
  final LinkedHashMap<String, List<double>> hourlyCountsByActivityName;

  int get totalCount =>
      activityCounts.fold(0, (total, activity) => total + activity.count);
}

StatisticsSummary buildStatisticsSummary({
  required List<Record> records,
  required Map<int, Event> eventsById,
}) {
  final activityCountsById = LinkedHashMap<int, int>();
  final hourlyCountsByActivityName = LinkedHashMap<String, List<double>>();

  for (final record in records) {
    final activity = _activityForRecord(record, eventsById);
    activityCountsById[record.eventId] =
        (activityCountsById[record.eventId] ?? 0) + 1;

    final hourlyCounts = hourlyCountsByActivityName.putIfAbsent(
      activity.name,
      () => List<double>.filled(24, 0),
    );
    hourlyCounts[record.endTime!.hour] += 1;
  }

  return StatisticsSummary(
    activityCounts: [
      for (final entry in activityCountsById.entries)
        ActivityCount(activity: eventsById[entry.key]!, count: entry.value),
    ],
    hourlyCountsByActivityName: hourlyCountsByActivityName,
  );
}

List<double> combineStatisticsAdjacentHourSlots(List<double> hourlyValues) {
  return [
    for (var i = 0; i < 12; i++) hourlyValues[i * 2] + hourlyValues[i * 2 + 1],
  ];
}

Event _activityForRecord(Record record, Map<int, Event> eventsById) {
  final activity = eventsById[record.eventId];
  if (activity == null) {
    throw StateError('Record ${record.id} references missing activity '
        '${record.eventId}.');
  }
  return activity;
}
