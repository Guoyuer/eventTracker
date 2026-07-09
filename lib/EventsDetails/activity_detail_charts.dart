import 'package:event_tracker/analytics/activity_detail_chart_models.dart';
import 'package:event_tracker/common/const.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/heatmap_calendar/heatMap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityDetailCharts extends StatefulWidget {
  final BaseEventModel activity;
  final List<ActivityRecord> records;

  const ActivityDetailCharts({
    Key? key,
    required this.activity,
    required this.records,
  }) : super(key: key);

  @override
  State<ActivityDetailCharts> createState() => _ActivityDetailChartsState();
}

class _ActivityDetailChartsState extends State<ActivityDetailCharts> {
  final ScrollController _scrollController = ScrollController();
  int _selectedMetricIndex = 0;
  DateTime? _selectedMonth;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = buildActivityDetailChartModel(
      records: widget.records,
      activity: widget.activity,
      selectedMetricIndex: _selectedMetricIndex,
      selectedMonth: _selectedMonth,
      now: DateTime.now(),
      combineHourSlots:
          MediaQuery.of(context).orientation == Orientation.portrait,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });

    return Column(
      children: [
        _chartCard(_buildHeatmap(model)),
        _chartCard(_buildTimeSlotChart(model)),
      ],
    );
  }

  Widget _chartCard(Widget child) {
    return Card(
      elevation: 10,
      child: child,
    );
  }

  Widget _buildHeatmap(ActivityDetailChartModel model) {
    return Column(
      children: [
        Center(
          child: Text(
            "统计数据 - ${model.selectedMetricLabel}",
            style: chartTitleStyle,
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          width: double.infinity,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: HeatMapCalendar(
              dateRange: DateTimeRange(
                start: model.heatmapSeries.range.start,
                end: model.heatmapSeries.range.end,
              ),
              input: model.heatmapSeries.data,
              unit: model.heatmapSeries.unit,
              onMonthTouched: (selectedMonth) {
                setState(() {
                  _selectedMonth = selectedMonth;
                });
              },
              onDayTouched: _showDayRecordsDialog,
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            margin: EdgeInsets.only(left: 10),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(text: model.recordCountHeading),
                  TextSpan(
                    text: '${model.visibleRecordCount}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: " 次")
                ],
              ),
            ),
          ),
          Container(
            height: 35,
            margin: EdgeInsets.all(10),
            child: ToggleButtons(
              children: model.metricLabels.map((label) => Text(label)).toList(),
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderWidth: 2,
              selectedBorderColor: Colors.blueAccent,
              isSelected: [
                for (var index = 0; index < model.metricLabels.length; index++)
                  index == _selectedMetricIndex,
              ],
              onPressed: (index) {
                if (index == _selectedMetricIndex) {
                  return;
                }
                setState(() {
                  _selectedMetricIndex = index;
                });
              },
            ),
          )
        ]),
      ],
    );
  }

  Widget _buildTimeSlotChart(ActivityDetailChartModel model) {
    return Column(children: [
      Text(
        "时段活跃度",
        style: chartTitleStyle,
      ),
      SizedBox(height: 10),
      Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
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
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double val, TitleMeta meta) {
                  return Text(val.floor().toString());
                },
                interval: _axisInterval(model.maxTimeSlotValue),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _barGroups(model.timeSlotBars),
        )),
      )
    ]);
  }

  List<BarChartGroupData> _barGroups(List<ActivityTimeSlotBar> bars) {
    return [
      for (final bar in bars) _barGroup(bar.x, bar.value),
    ];
  }

  BarChartGroupData _barGroup(int x, double value) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: value, width: 15, gradient: gradientColors)
    ]);
  }

  double _axisInterval(double maxValue) {
    return maxValue <= 0 ? 1 : maxValue / 6;
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) {
      return;
    }
    final scrollPosition = _scrollController.position;
    if (scrollPosition.maxScrollExtent > scrollPosition.minScrollExtent) {
      _scrollController.animateTo(
        scrollPosition.maxScrollExtent,
        duration: Duration(seconds: 1),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showDayRecordsDialog(DateTime day) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "dismiss",
      transitionDuration: Duration(milliseconds: 500),
      transitionBuilder: (ctx, animation, animation2, child) {
        final fadeTween = CurveTween(curve: Curves.easeInOut);
        final fadeAnimation = fadeTween.animate(animation);
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final timeStr = DateFormat('yyyy.MM.dd').format(day);
        return AlertDialog(
          title: Text("$timeStr的记录"),
          content: _buildDayRecords(widget.records, day),
        );
      },
    );
  }

  Widget _buildDayRecords(List<ActivityRecord> records, DateTime day) {
    final labels = activityRecordLabelsForDay(
      activity: widget.activity,
      records: records,
      day: day,
    );
    if (labels.isEmpty) {
      return Text("当日无记录");
    }

    return SizedBox(
      width: 300,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: labels.length,
        itemBuilder: (ctx, index) {
          return Text(labels[index]);
        },
      ),
    );
  }
}
