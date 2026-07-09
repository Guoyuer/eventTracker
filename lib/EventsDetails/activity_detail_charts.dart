import 'package:event_tracker/analytics/activity_detail_analytics.dart';
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
  late final List<String> _metricLabels;
  int _selectedMetricIndex = 0;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _metricLabels = [
      if (widget.activity is TimingEventModel) "时长" else "次数",
      if (widget.activity.unit != null) widget.activity.unit!,
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metric =
        metricForActivitySelection(widget.activity, _selectedMetricIndex);
    final heatMapSeries = buildActivityHeatmapSeries(
      records: widget.records,
      activity: widget.activity,
      metric: metric,
      now: DateTime.now(),
    );
    final visibleRecords = _selectedMonth == null
        ? widget.records
        : recordsInMonth(widget.records, _selectedMonth!);
    final barRecords = visibleRecords.isEmpty ? widget.records : visibleRecords;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });

    return Column(
      children: [
        _chartCard(_buildHeatmap(heatMapSeries, visibleRecords.length)),
        _chartCard(_buildTimeSlotChart(barRecords, metric)),
      ],
    );
  }

  Widget _chartCard(Widget child) {
    return Card(
      elevation: 10,
      child: child,
    );
  }

  Widget _buildHeatmap(
    ActivityHeatmapSeries heatMapSeries,
    int visibleRecordCount,
  ) {
    return Column(
      children: [
        Center(
          child: Text(
            "统计数据 - ${_metricLabels[_selectedMetricIndex]}",
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
              dateRange: heatMapSeries.range,
              input: heatMapSeries.data,
              unit: heatMapSeries.unit,
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
                  TextSpan(text: _recordCountHeading()),
                  TextSpan(
                    text: '$visibleRecordCount',
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
              children: _metricLabels.map((label) => Text(label)).toList(),
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderWidth: 2,
              selectedBorderColor: Colors.blueAccent,
              isSelected: [
                for (var index = 0; index < _metricLabels.length; index++)
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

  String _recordCountHeading() {
    final month = _selectedMonth;
    if (month == null) {
      return "共进行";
    }
    return "${month.month}月共进行";
  }

  Widget _buildTimeSlotChart(
    List<ActivityRecord> records,
    ActivityDetailMetric metric,
  ) {
    final timeSlotSeries = buildActivityTimeSlotSeries(
      records: records,
      activity: widget.activity,
      metric: metric,
    );
    final bars = _barGroupsForOrientation(timeSlotSeries.hourlyValues);
    final maxValue = _maxValueForOrientation(timeSlotSeries.hourlyValues);

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
                interval: maxValue / 6,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: bars,
        )),
      )
    ]);
  }

  List<BarChartGroupData> _barGroupsForOrientation(List<double> hourlyValues) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      final values = combineAdjacentHourSlots(hourlyValues);
      return [
        for (var index = 0; index < 12; index++)
          _barGroup(index * 2, values[index])
      ];
    }

    return [
      for (var index = 0; index < 24; index++)
        _barGroup(index, hourlyValues[index])
    ];
  }

  BarChartGroupData _barGroup(int x, double value) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: value, width: 15, gradient: gradientColors)
    ]);
  }

  double _maxValueForOrientation(List<double> hourlyValues) {
    final values = MediaQuery.of(context).orientation == Orientation.portrait
        ? combineAdjacentHourSlots(hourlyValues)
        : hourlyValues;
    return values.fold<double>(0, (maxValue, value) {
      return value > maxValue ? value : maxValue;
    });
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
    final dayRecords = recordsOnDay(records, day);
    if (dayRecords.isEmpty) {
      return Text("当日无记录");
    }

    return SizedBox(
      width: 300,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: dayRecords.length,
        itemBuilder: (ctx, index) {
          return Text(_recordLabel(dayRecords[index]));
        },
      ),
    );
  }

  String _recordLabel(ActivityRecord record) {
    if (widget.activity is TimingEventModel) {
      final startTimeStr = DateFormat('MM-dd kk:mm').format(record.startTime!);
      final endTimeStr = DateFormat('MM-dd kk:mm').format(record.endTime);
      if (widget.activity.unit != null) {
        return "$startTimeStr ~ $endTimeStr, ${record.value!.toInt()}${widget.activity.unit!}  ";
      }
      return "$startTimeStr ~ $endTimeStr  ";
    }

    final endTimeStr = DateFormat('kk:mm').format(record.endTime);
    if (widget.activity.unit != null) {
      return "$endTimeStr, ${record.value!.toInt()}${widget.activity.unit!}  ";
    }
    return "$endTimeStr  ";
  }
}
