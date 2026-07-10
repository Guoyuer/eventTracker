import 'package:event_tracker/analytics/statistics_chart_models.dart';
import 'package:event_tracker/domain/statistics_repository.dart'
    show StatisticsData;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class StatisticsCharts extends StatelessWidget {
  final StatisticsData statisticsData;

  const StatisticsCharts(this.statisticsData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = buildStatisticsChartModel(
      records: statisticsData.records,
      activitiesById: statisticsData.activitiesById,
      colorCount: Colors.primaries.length,
    );

    if (model.isEmpty) {
      return Card(
        elevation: 10,
        child: Text(AppLocalizations.of(context)!.noRecords),
      );
    }

    return Column(
      children: [
        _chartCard(_PieStatisticsChart(model)),
        _chartCard(_TimeSlotStatisticsChart(model)),
      ],
    );
  }

  Widget _chartCard(Widget child) {
    return Card(elevation: 10, child: child);
  }
}

class _PieStatisticsChart extends StatelessWidget {
  final StatisticsChartModel model;

  const _PieStatisticsChart(this.model);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.countStatistics,
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 70,
                  sectionsSpace: 5,
                  sections: _sections(),
                ),
              ),
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
                      AppLocalizations.of(
                        context,
                      )!.totalCount(model.totalCount),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  List<PieChartSectionData> _sections() {
    return [
      for (final slice in model.pieSlices)
        PieChartSectionData(
          color: _color(slice.colorIndex),
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          title: "${slice.activityName} ${slice.count}",
          value: slice.count.toDouble(),
        ),
    ];
  }

  Color _color(int colorIndex) {
    return Colors.primaries[colorIndex].shade300;
  }
}

class _TimeSlotStatisticsChart extends StatelessWidget {
  final StatisticsChartModel model;

  const _TimeSlotStatisticsChart(this.model);

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final slots = orientation == Orientation.portrait
        ? model.portraitSlots
        : model.landscapeSlots;
    final bars = _barGroups(slots);

    return Container(
      margin: EdgeInsets.only(left: 5, top: 10, right: 10),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.timeSlotActivity,
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey,
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
                      interval: _axisInterval(slots.maxY),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: bars,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _barGroups(StatisticsTimeSlotModel slots) {
    return [
      for (final bar in slots.bars)
        BarChartGroupData(
          x: bar.x,
          barRods: [
            BarChartRodData(
              borderRadius: BorderRadius.all(Radius.elliptical(5, 5)),
              rodStackItems: [
                for (final segment in bar.segments)
                  BarChartRodStackItem(
                    segment.fromY,
                    segment.toY,
                    _color(segment.colorIndex),
                  ),
              ],
              toY: bar.total,
              width: 15,
            ),
          ],
        ),
    ];
  }

  Color _color(int colorIndex) {
    return Colors.primaries[colorIndex].shade300;
  }

  double _axisInterval(double maxValue) {
    return maxValue <= 0 ? 1 : maxValue / 6;
  }
}
