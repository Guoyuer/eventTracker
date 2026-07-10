import '../domain/activity_models.dart';
import 'activity_detail_analytics.dart';

class ActivityDetailChartModel {
  ActivityDetailChartModel({
    required this.metric,
    required this.availableMetrics,
    required this.heatmapSeries,
    required this.visibleRecordCount,
    required this.selectedMonth,
    required this.timeSlotBars,
    required this.maxTimeSlotValue,
  });

  final ActivityDetailMetric metric;
  final List<ActivityDetailMetric> availableMetrics;
  final ActivityHeatmapSeries heatmapSeries;
  final int visibleRecordCount;
  final DateTime? selectedMonth;
  final List<ActivityTimeSlotBar> timeSlotBars;
  final double maxTimeSlotValue;
}

class ActivityTimeSlotBar {
  ActivityTimeSlotBar({required this.x, required this.value});

  final int x;
  final double value;
}

class ActivityRecordDetail {
  const ActivityRecordDetail({
    required this.endedAt,
    required this.startedAt,
    required this.value,
    required this.unit,
  });

  final DateTime endedAt;
  final DateTime? startedAt;
  final double? value;
  final String? unit;
}

ActivityDetailChartModel buildActivityDetailChartModel({
  required Activity activity,
  required List<ActivityRecord> records,
  required int selectedMetricIndex,
  required DateTime? selectedMonth,
  required DateTime now,
  required bool combineHourSlots,
}) {
  final availableMetrics = activityDetailMetrics(activity);
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
    availableMetrics: availableMetrics,
    heatmapSeries: heatmapSeries,
    visibleRecordCount: visibleRecords.length,
    selectedMonth: selectedMonth,
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

List<ActivityDetailMetric> activityDetailMetrics(Activity activity) {
  return [
    if (activity is TimedActivity)
      ActivityDetailMetric.duration
    else
      ActivityDetailMetric.count,
    if (activity.unit != null) ActivityDetailMetric.value,
  ];
}

List<ActivityRecordDetail> activityRecordDetailsForDay({
  required Activity activity,
  required List<ActivityRecord> records,
  required DateTime day,
}) {
  return [
    for (final record in recordsOnDay(records, day))
      activityRecordDetail(activity: activity, record: record),
  ];
}

ActivityRecordDetail activityRecordDetail({
  required Activity activity,
  required ActivityRecord record,
}) {
  return switch ((activity, record)) {
    (TimedActivity(), final CompletedTimedRecord timedRecord) =>
      _timedRecordDetail(
        timedRecord,
        activity.unit ?? '',
        hasUnit: activity.unit != null,
      ),
    (PlainActivity(), final PlainRecord plainRecord) => _plainRecordDetail(
      plainRecord,
      activity.unit ?? '',
      hasUnit: activity.unit != null,
    ),
    (_, ActiveTimedRecord()) => throw StateError(
      'Active Records do not have detail labels',
    ),
    _ => throw StateError('Activity and Record shapes do not match'),
  };
}

ActivityRecordDetail _timedRecordDetail(
  CompletedTimedRecord record,
  String unit, {
  required bool hasUnit,
}) {
  if (hasUnit && record.value == null) {
    throw StateError('Unit-backed Record ${record.id} has no value');
  }
  return ActivityRecordDetail(
    startedAt: record.startedAt,
    endedAt: record.endedAt,
    value: record.value,
    unit: hasUnit ? unit : null,
  );
}

ActivityRecordDetail _plainRecordDetail(
  PlainRecord record,
  String unit, {
  required bool hasUnit,
}) {
  if (hasUnit && record.value == null) {
    throw StateError('Unit-backed Record ${record.id} has no value');
  }
  return ActivityRecordDetail(
    startedAt: null,
    endedAt: record.endedAt,
    value: record.value,
    unit: hasUnit ? unit : null,
  );
}
