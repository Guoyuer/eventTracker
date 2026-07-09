import 'package:intl/intl.dart';

import '../domain/activity_models.dart';
import 'activity_detail_analytics.dart';

class ActivityDetailChartModel {
  ActivityDetailChartModel({
    required this.metric,
    required this.metricLabels,
    required this.selectedMetricLabel,
    required this.heatmapSeries,
    required this.visibleRecordCount,
    required this.recordCountHeading,
    required this.timeSlotBars,
    required this.maxTimeSlotValue,
  });

  final ActivityDetailMetric metric;
  final List<String> metricLabels;
  final String selectedMetricLabel;
  final ActivityHeatmapSeries heatmapSeries;
  final int visibleRecordCount;
  final String recordCountHeading;
  final List<ActivityTimeSlotBar> timeSlotBars;
  final double maxTimeSlotValue;
}

class ActivityTimeSlotBar {
  ActivityTimeSlotBar({required this.x, required this.value});

  final int x;
  final double value;
}

ActivityDetailChartModel buildActivityDetailChartModel({
  required Activity activity,
  required List<ActivityRecord> records,
  required int selectedMetricIndex,
  required DateTime? selectedMonth,
  required DateTime now,
  required bool combineHourSlots,
}) {
  final metricLabels = activityDetailMetricLabels(activity);
  final metric = metricForActivitySelection(activity, selectedMetricIndex);
  final heatmapSeries = buildActivityHeatmapSeries(
    records: records,
    activity: activity,
    metric: metric,
    now: now,
  );
  final visibleRecords = selectedMonth == null
      ? records
      : recordsInMonth(records, selectedMonth);
  final barRecords = visibleRecords.isEmpty ? records : visibleRecords;
  final timeSlotSeries = buildActivityTimeSlotSeries(
    records: barRecords,
    activity: activity,
    metric: metric,
  );
  final timeSlotValues = combineHourSlots
      ? combineAdjacentHourSlots(timeSlotSeries.hourlyValues)
      : timeSlotSeries.hourlyValues;

  return ActivityDetailChartModel(
    metric: metric,
    metricLabels: metricLabels,
    selectedMetricLabel: metricLabels[selectedMetricIndex],
    heatmapSeries: heatmapSeries,
    visibleRecordCount: visibleRecords.length,
    recordCountHeading: activityRecordCountHeading(selectedMonth),
    timeSlotBars: [
      for (var index = 0; index < timeSlotValues.length; index++)
        ActivityTimeSlotBar(
          x: timeSlotValues.length == 12 ? index * 2 : index,
          value: timeSlotValues[index],
        ),
    ],
    maxTimeSlotValue: timeSlotValues.fold<double>(0, (maxValue, value) {
      return value > maxValue ? value : maxValue;
    }),
  );
}

List<String> activityDetailMetricLabels(Activity activity) {
  return [
    if (activity is TimedActivity) '时长' else '次数',
    if (activity.unit != null) activity.requiredUnit,
  ];
}

String activityRecordCountHeading(DateTime? selectedMonth) {
  if (selectedMonth == null) {
    return '共进行';
  }
  return '${selectedMonth.month}月共进行';
}

List<String> activityRecordLabelsForDay({
  required Activity activity,
  required List<ActivityRecord> records,
  required DateTime day,
}) {
  return [
    for (final record in recordsOnDay(records, day))
      activityRecordLabel(activity: activity, record: record),
  ];
}

String activityRecordLabel({
  required Activity activity,
  required ActivityRecord record,
}) {
  if (activity is TimedActivity) {
    final startTimeStr = DateFormat(
      'MM-dd kk:mm',
    ).format(record.requiredStartTime);
    final endTimeStr = DateFormat('MM-dd kk:mm').format(record.endTime);
    if (activity.unit != null) {
      return '$startTimeStr ~ $endTimeStr, ${record.requiredValue.toInt()}${activity.requiredUnit}  ';
    }
    return '$startTimeStr ~ $endTimeStr  ';
  }

  final endTimeStr = DateFormat('kk:mm').format(record.endTime);
  if (activity.unit != null) {
    return '$endTimeStr, ${record.requiredValue.toInt()}${activity.requiredUnit}  ';
  }
  return '$endTimeStr  ';
}
