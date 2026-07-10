import 'dart:math';

import '../common/util.dart';
import '../domain/activity_models.dart';
import '../domain/date_range.dart';

enum ActivityDetailMetric { duration, count, value }

class ActivityHeatmapSeries {
  ActivityHeatmapSeries({required this.range, required this.data});

  final CalendarDateRange range;
  final Map<DateTime, double> data;
}

class ActivityTimeSlotSeries {
  ActivityTimeSlotSeries({required this.hourlyValues});

  final List<double> hourlyValues;
}

ActivityDetailMetric metricForActivitySelection(
  Activity activity,
  int selectedIndex,
) {
  if (activity is TimedActivity && selectedIndex == 0) {
    return ActivityDetailMetric.duration;
  }
  if (selectedIndex == 0) {
    return ActivityDetailMetric.count;
  }
  return ActivityDetailMetric.value;
}

ActivityHeatmapSeries buildActivityHeatmapSeries({
  required List<ActivityRecord> records,
  required Activity activity,
  required ActivityDetailMetric metric,
  required DateTime now,
}) {
  final completedRecords = records.whereType<CompletedActivityRecord>().toList(
    growable: false,
  );
  final data = <DateTime, double>{};
  final range = CalendarDateRange(
    firstDay: completedRecords.isEmpty
        ? getDate(now)
        : getDate(completedRecords.first.endedAt),
    lastDay: getDate(now),
  );

  for (final record in completedRecords) {
    final date = getDate(record.endedAt);
    data[date] = (data[date] ?? 0) + _dailyRecordValue(record, metric);
  }

  return ActivityHeatmapSeries(range: range, data: data);
}

ActivityTimeSlotSeries buildActivityTimeSlotSeries({
  required List<ActivityRecord> records,
  required Activity activity,
  required ActivityDetailMetric metric,
}) {
  if (metric == ActivityDetailMetric.duration) {
    return _buildDurationTimeSlotSeries(records);
  }

  final values = List<double>.filled(24, 0);
  for (final record in records.whereType<CompletedActivityRecord>()) {
    final end = record.endedAt;
    values[end.hour] += _timeSlotRecordValue(record, metric);
  }

  return ActivityTimeSlotSeries(hourlyValues: values);
}

List<ActivityRecord> recordsInMonth(
  List<ActivityRecord> records,
  DateTime month,
) {
  return records
      .whereType<CompletedActivityRecord>()
      .where(
        (record) =>
            record.endedAt.month == month.month &&
            record.endedAt.year == month.year,
      )
      .toList();
}

List<ActivityRecord> recordsOnDay(List<ActivityRecord> records, DateTime day) {
  return records
      .whereType<CompletedActivityRecord>()
      .where(
        (record) =>
            record.endedAt.month == day.month &&
            record.endedAt.year == day.year &&
            record.endedAt.day == day.day,
      )
      .toList();
}

List<double> combineAdjacentHourSlots(List<double> hourlyValues) {
  return [
    for (var i = 0; i < 12; i++) hourlyValues[i * 2] + hourlyValues[i * 2 + 1],
  ];
}

double _dailyRecordValue(
  CompletedActivityRecord record,
  ActivityDetailMetric metric,
) {
  switch (metric) {
    case ActivityDetailMetric.duration:
      if (record case CompletedTimedRecord(:final duration)) {
        return duration.inMinutes.toDouble();
      }
      throw StateError('Duration metrics require completed timed Records');
    case ActivityDetailMetric.count:
      return 1;
    case ActivityDetailMetric.value:
      final value = record.value;
      if (value == null) {
        throw StateError('Value metrics require Record values');
      }
      return value;
  }
}

double _timeSlotRecordValue(
  CompletedActivityRecord record,
  ActivityDetailMetric metric,
) {
  switch (metric) {
    case ActivityDetailMetric.duration:
      throw StateError('duration values are split across occupied hours');
    case ActivityDetailMetric.count:
      return 1;
    case ActivityDetailMetric.value:
      final value = record.value;
      if (value == null) {
        throw StateError('Value metrics require Record values');
      }
      return value;
  }
}

ActivityTimeSlotSeries _buildDurationTimeSlotSeries(
  List<ActivityRecord> records,
) {
  final seconds = List<double>.filled(24, 0);

  for (final record in records.whereType<CompletedTimedRecord>()) {
    _addDurationByHour(
      seconds,
      DateInterval(start: record.startedAt, endExclusive: record.endedAt),
    );
  }

  final maxValue = seconds.reduce(max);
  if (maxValue <= 500) {
    return ActivityTimeSlotSeries(hourlyValues: seconds);
  }
  if (maxValue <= 500 * 60) {
    return ActivityTimeSlotSeries(
      hourlyValues: seconds.map((value) => value / 60).toList(),
    );
  }
  return ActivityTimeSlotSeries(
    hourlyValues: seconds.map((value) => value / 3600).toList(),
  );
}

void _addDurationByHour(List<double> seconds, DateInterval range) {
  final start = range.start;
  final end = range.endExclusive;
  if (start == end) {
    return;
  }

  if (start.day == end.day && start.hour == end.hour) {
    seconds[start.hour] += end.difference(start).inSeconds;
    return;
  }

  final left = DateTime(
    start.year,
    start.month,
    start.day,
    start.hour,
  ).add(const Duration(hours: 1));
  seconds[start.hour] += left.difference(start).inSeconds;

  final right = DateTime(end.year, end.month, end.day, end.hour);
  if (end.hour == left.hour) {
    seconds[left.hour] += end.difference(left).inSeconds;
    return;
  }

  seconds[right.hour] += end.difference(right).inSeconds;
  var cursor = left;
  while (cursor.compareTo(right) < 0) {
    seconds[cursor.hour] += const Duration(hours: 1).inSeconds;
    cursor = cursor.add(const Duration(hours: 1));
  }
}
