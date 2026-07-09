import 'package:event_tracker/analytics/statistics_analytics.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/persistence/statistics_repository.dart'
    show StatisticsData;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatisticsCharts extends StatelessWidget {
  final StatisticsData statisticsData;

  const StatisticsCharts(this.statisticsData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final records = statisticsData.records;
    final activitiesById = statisticsData.activitiesById;

    if (records.isEmpty || activitiesById.isEmpty) {
      return Card(elevation: 10, child: Text("暂无记录"));
    }

    final activityColors = _activityColors(activitiesById);
    final summary = buildStatisticsSummary(
      records: records,
      eventsById: activitiesById,
    );

    return Column(
      children: [
        _chartCard(_PieStatisticsChart(summary, activityColors)),
        _chartCard(_TimeSlotStatisticsChart(
          summary.hourlyCountsByActivityName,
          activityColors,
        )),
      ],
    );
  }

  Widget _chartCard(Widget child) {
    return Card(
      elevation: 10,
      child: child,
    );
  }

  Map<String, Color> _activityColors(Map<int, StatisticsActivity> activities) {
    final colors = <String, Color>{};
    activities.forEach((activityId, activity) {
      colors[activity.name] =
          Colors.primaries[activityId.abs() % Colors.primaries.length].shade300;
    });
    return colors;
  }
}

class _PieStatisticsChart extends StatelessWidget {
  final StatisticsSummary summary;
  final Map<String, Color> activityColors;

  const _PieStatisticsChart(this.summary, this.activityColors);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "次数统计",
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              PieChart(PieChartData(
                centerSpaceRadius: 70,
                sectionsSpace: 5,
                sections: _sections(),
              )),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "共 ${summary.totalCount} 次",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        SizedBox(height: 30)
      ],
    );
  }

  List<PieChartSectionData> _sections() {
    return [
      for (final activityCount in summary.activityCounts)
        PieChartSectionData(
          color: activityColors[activityCount.activity.name],
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          title:
              "${activityCount.activity.name} ${activityCount.count.toString()}",
          value: activityCount.count.toDouble(),
        )
    ];
  }
}

class _TimeSlotStatisticsChart extends StatelessWidget {
  final Map<String, List<double>> hourlyCountsByActivityName;
  final Map<String, Color> activityColors;

  const _TimeSlotStatisticsChart(
    this.hourlyCountsByActivityName,
    this.activityColors,
  );

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final slotCounts = _slotCountsForOrientation(orientation);
    final bars = _barGroups(slotCounts);
    final maxY = _maxStackHeight(slotCounts);

    return Container(
      margin: EdgeInsets.only(left: 5, top: 10, right: 10),
      child: Column(children: [
        Text(
          "时段活跃度",
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: BarChart(BarChartData(
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    TextStyle(color: Colors.white, fontSize: 18),
                  );
                },
              ),
            ),
            groupsSpace: 18,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double val, TitleMeta meta) {
                    return Text(val.round().toString());
                  },
                  interval: maxY / 6,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: bars,
          )),
        )
      ]),
    );
  }

  Map<String, List<double>> _slotCountsForOrientation(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return {
        for (final entry in hourlyCountsByActivityName.entries)
          entry.key: combineStatisticsAdjacentHourSlots(entry.value),
      };
    }

    return Map.of(hourlyCountsByActivityName);
  }

  List<BarChartGroupData> _barGroups(Map<String, List<double>> slotCounts) {
    final slotCount = slotCounts.isEmpty ? 0 : slotCounts.values.first.length;
    final stacks =
        List.generate(slotCount, (index) => <BarChartRodStackItem>[]);
    final stackHeights = List.filled(slotCount, 0.0);

    slotCounts.forEach((activityName, slots) {
      for (var index = 0; index < slotCount; index++) {
        stacks[index].add(BarChartRodStackItem(
          stackHeights[index],
          stackHeights[index] + slots[index],
          activityColors[activityName]!,
        ));
        stackHeights[index] += slots[index];
      }
    });

    return [
      for (var index = 0; index < slotCount; index++)
        BarChartGroupData(
          x: slotCount == 12 ? index * 2 : index,
          barRods: [
            BarChartRodData(
              borderRadius: BorderRadius.all(Radius.elliptical(5, 5)),
              rodStackItems: stacks[index],
              toY: stackHeights[index],
              width: 15,
            )
          ],
        )
    ];
  }

  double _maxStackHeight(Map<String, List<double>> slotCounts) {
    if (slotCounts.isEmpty) {
      return 0;
    }

    final slotCount = slotCounts.values.first.length;
    var maxY = 0.0;
    for (var index = 0; index < slotCount; index++) {
      var slotTotal = 0.0;
      for (final slots in slotCounts.values) {
        slotTotal += slots[index];
      }
      if (slotTotal > maxY) {
        maxY = slotTotal;
      }
    }
    return maxY;
  }
}
