import 'dart:math';

import '../common/util.dart';
import '../domain/activity_models.dart';
import '../domain/date_range.dart';

enum ActivityDetailMetric { duration, count, value }

class ActivityHeatmapSeries {
  ActivityHeatmapSeries({
    required this.range,
    required this.data,
    required this.unit,
  });

  final DateRange range;
  final Map<DateTime, double> data;
  final String unit;
}

class ActivityTimeSlotSeries {
  ActivityTimeSlotSeries({
    required this.hourlyValues,
    required this.unit,
  });

  final List<double> hourlyValues;
  final String unit;
}

ActivityDetailMetric metricForActivitySelection(
  BaseEventModel activity,
  int selectedIndex,
) {
  if (activity is TimingEventModel && selectedIndex == 0) {
    return ActivityDetailMetric.duration;
  }
  if (selectedIndex == 0) {
    return ActivityDetailMetric.count;
  }
  return ActivityDetailMetric.value;
}

ActivityHeatmapSeries buildActivityHeatmapSeries({
  required List<ActivityRecord> records,
  required BaseEventModel activity,
  required ActivityDetailMetric metric,
  required DateTime now,
}) {
  final data = <DateTime, double>{};
  final range = DateRange(
    start: records.isEmpty ? getDate(now) : getDate(records.first.endTime),
    end: getDate(now),
  );

  for (final record in records) {
    final date = getDate(record.endTime);
    data[date] = (data[date] ?? 0) + _dailyRecordValue(record, metric);
  }

  return ActivityHeatmapSeries(
    range: range,
    data: data,
    unit: _heatmapUnit(activity, metric),
  );
}

ActivityTimeSlotSeries buildActivityTimeSlotSeries({
  required List<ActivityRecord> records,
  required BaseEventModel activity,
  required ActivityDetailMetric metric,
}) {
  if (metric == ActivityDetailMetric.duration) {
    return _buildDurationTimeSlotSeries(records);
  }

  final values = List<double>.filled(24, 0);
  for (final record in records) {
    final end = record.endTime;
    values[end.hour] += _timeSlotRecordValue(record, metric);
  }

  return ActivityTimeSlotSeries(
    hourlyValues: values,
    unit: _timeSlotUnit(activity, metric),
  );
}

List<ActivityRecord> recordsInMonth(
    List<ActivityRecord> records, DateTime month) {
  return records
      .where((record) =>
          record.endTime.month == month.month &&
          record.endTime.year == month.year)
      .toList();
}

List<ActivityRecord> recordsOnDay(List<ActivityRecord> records, DateTime day) {
  return records
      .where((record) =>
          record.endTime.month == day.month &&
          record.endTime.year == day.year &&
          record.endTime.day == day.day)
      .toList();
}

List<double> combineAdjacentHourSlots(List<double> hourlyValues) {
  return [
    for (var i = 0; i < 12; i++) hourlyValues[i * 2] + hourlyValues[i * 2 + 1],
  ];
}

double _dailyRecordValue(ActivityRecord record, ActivityDetailMetric metric) {
  switch (metric) {
    case ActivityDetailMetric.duration:
      return record.endTime.difference(record.startTime!).inMinutes.toDouble();
    case ActivityDetailMetric.count:
      return 1;
    case ActivityDetailMetric.value:
      return record.value!;
  }
}

double _timeSlotRecordValue(
    ActivityRecord record, ActivityDetailMetric metric) {
  switch (metric) {
    case ActivityDetailMetric.duration:
      throw StateError('duration values are split across occupied hours');
    case ActivityDetailMetric.count:
      return 1;
    case ActivityDetailMetric.value:
      return record.value!;
  }
}

ActivityTimeSlotSeries _buildDurationTimeSlotSeries(
    List<ActivityRecord> records) {
  final seconds = List<double>.filled(24, 0);

  for (final record in records) {
    _addDurationByHour(
      seconds,
      DateRange(start: record.startTime!, end: record.endTime),
    );
  }

  final maxValue = seconds.reduce(max);
  if (maxValue <= 500) {
    return ActivityTimeSlotSeries(hourlyValues: seconds, unit: '秒');
  }
  if (maxValue <= 500 * 60) {
    return ActivityTimeSlotSeries(
      hourlyValues: seconds.map((value) => value / 60).toList(),
      unit: '分钟',
    );
  }
  return ActivityTimeSlotSeries(
    hourlyValues: seconds.map((value) => value / 3600).toList(),
    unit: '小时',
  );
}

void _addDurationByHour(List<double> seconds, DateRange range) {
  final start = range.start;
  final end = range.end;
  assert(start.compareTo(end) < 0);

  if (start.day == end.day && start.hour == end.hour) {
    seconds[start.hour] += end.difference(start).inSeconds;
    return;
  }

  final left = DateTime(start.year, start.month, start.day, start.hour)
      .add(const Duration(hours: 1));
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

String _heatmapUnit(BaseEventModel activity, ActivityDetailMetric metric) {
  switch (metric) {
    case ActivityDetailMetric.duration:
      return '分钟';
    case ActivityDetailMetric.count:
      return '次数';
    case ActivityDetailMetric.value:
      return activity.unit!;
  }
}

String _timeSlotUnit(BaseEventModel activity, ActivityDetailMetric metric) {
  switch (metric) {
    case ActivityDetailMetric.duration:
      return '秒';
    case ActivityDetailMetric.count:
      return '次数';
    case ActivityDetailMetric.value:
      return activity.unit!;
  }
}
