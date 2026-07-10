import '../domain/activity_models.dart';
import 'statistics_analytics.dart';

class StatisticsChartModel {
  StatisticsChartModel({
    required this.totalCount,
    required this.pieSlices,
    required this.landscapeSlots,
    required this.portraitSlots,
  });

  final int totalCount;
  final List<StatisticsPieSlice> pieSlices;
  final StatisticsTimeSlotModel landscapeSlots;
  final StatisticsTimeSlotModel portraitSlots;

  bool get isEmpty => totalCount == 0 || pieSlices.isEmpty;
}

class StatisticsPieSlice {
  StatisticsPieSlice({
    required this.activityName,
    required this.count,
    required this.colorIndex,
  });

  final String activityName;
  final int count;
  final int colorIndex;
}

class StatisticsTimeSlotModel {
  StatisticsTimeSlotModel({required this.bars, required this.maxY});

  final List<StatisticsTimeSlotBar> bars;
  final double maxY;
}

class StatisticsTimeSlotBar {
  StatisticsTimeSlotBar({
    required this.x,
    required this.total,
    required this.segments,
  });

  final int x;
  final double total;
  final List<StatisticsTimeSlotSegment> segments;
}

class StatisticsTimeSlotSegment {
  StatisticsTimeSlotSegment({
    required this.activityName,
    required this.fromY,
    required this.toY,
    required this.colorIndex,
  });

  final String activityName;
  final double fromY;
  final double toY;
  final int colorIndex;
}

StatisticsChartModel buildStatisticsChartModel({
  required List<ActivityRecord> records,
  required Map<int, StatisticsActivity> activitiesById,
  required int colorCount,
}) {
  if (records.isEmpty || activitiesById.isEmpty) {
    return StatisticsChartModel(
      totalCount: 0,
      pieSlices: [],
      landscapeSlots: StatisticsTimeSlotModel(bars: [], maxY: 0),
      portraitSlots: StatisticsTimeSlotModel(bars: [], maxY: 0),
    );
  }

  final summary = buildStatisticsSummary(
    records: records,
    activitiesById: activitiesById,
  );
  final colorIndexByActivityName = _colorIndexByActivityName(
    activitiesById,
    colorCount,
  );

  return StatisticsChartModel(
    totalCount: summary.totalCount,
    pieSlices: [
      for (final activityCount in summary.activityCounts)
        StatisticsPieSlice(
          activityName: activityCount.activity.name,
          count: activityCount.count,
          colorIndex: colorIndexByActivityName[activityCount.activity.name]!,
        ),
    ],
    landscapeSlots: _buildTimeSlotModel(
      summary.hourlyCountsByActivityName,
      colorIndexByActivityName,
      combineAdjacentHours: false,
    ),
    portraitSlots: _buildTimeSlotModel(
      summary.hourlyCountsByActivityName,
      colorIndexByActivityName,
      combineAdjacentHours: true,
    ),
  );
}

Map<String, int> _colorIndexByActivityName(
  Map<int, StatisticsActivity> activitiesById,
  int colorCount,
) {
  return {
    for (final entry in activitiesById.entries)
      entry.value.name: entry.key.abs() % colorCount,
  };
}

StatisticsTimeSlotModel _buildTimeSlotModel(
  Map<String, List<double>> hourlyCountsByActivityName,
  Map<String, int> colorIndexByActivityName, {
  required bool combineAdjacentHours,
}) {
  final slotCounts = {
    for (final entry in hourlyCountsByActivityName.entries)
      entry.key: combineAdjacentHours
          ? combineStatisticsAdjacentHourSlots(entry.value)
          : entry.value,
  };
  final slotCount = slotCounts.isEmpty ? 0 : slotCounts.values.first.length;
  final stackHeights = List.filled(slotCount, 0.0);
  final segmentsBySlot = List.generate(
    slotCount,
    (_) => <StatisticsTimeSlotSegment>[],
  );

  slotCounts.forEach((activityName, slots) {
    for (var index = 0; index < slotCount; index++) {
      final fromY = stackHeights[index];
      final toY = fromY + slots[index];
      segmentsBySlot[index].add(
        StatisticsTimeSlotSegment(
          activityName: activityName,
          fromY: fromY,
          toY: toY,
          colorIndex: colorIndexByActivityName[activityName]!,
        ),
      );
      stackHeights[index] = toY;
    }
  });

  return StatisticsTimeSlotModel(
    bars: [
      for (var index = 0; index < slotCount; index++)
        StatisticsTimeSlotBar(
          x: slotCount == 12 ? index * 2 : index,
          total: stackHeights[index],
          segments: segmentsBySlot[index],
        ),
    ],
    maxY: stackHeights.fold<double>(0, (maxY, value) {
      return value > maxY ? value : maxY;
    }),
  );
}
