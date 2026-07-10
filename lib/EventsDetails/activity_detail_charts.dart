import 'package:event_tracker/analytics/activity_detail_chart_models.dart';
import 'package:event_tracker/common/const.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/heatmap_calendar/heatMap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../analytics/activity_detail_analytics.dart';
import '../l10n/app_localizations.dart';

class ActivityDetailCharts extends StatefulWidget {
  final Activity activity;
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
        _chartCard(_buildHeatmap(context, model)),
        _chartCard(_buildTimeSlotChart(context, model)),
      ],
    );
  }

  Widget _chartCard(Widget child) {
    return Card(elevation: 10, child: child);
  }

  Widget _buildHeatmap(BuildContext context, ActivityDetailChartModel model) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        Center(
          child: Text(
            localizations.statisticsForMetric(
              _metricLabel(localizations, model.metric),
            ),
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
                start: model.heatmapSeries.range.firstDay,
                end: model.heatmapSeries.range.lastDay,
              ),
              input: model.heatmapSeries.data,
              onMonthTouched: (selectedMonth) {
                setState(() {
                  _selectedMonth = selectedMonth;
                });
              },
              onDayTouched: _showDayRecordsDialog,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: EdgeInsets.only(left: 10),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(
                      text: localizations.recordCountHeading(
                        _monthLabel(localizations, model.selectedMonth),
                      ),
                    ),
                    TextSpan(
                      text: '${model.visibleRecordCount}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: localizations.recordCountSuffix),
                  ],
                ),
              ),
            ),
            Container(
              height: 35,
              margin: EdgeInsets.all(10),
              child: ToggleButtons(
                children: model.availableMetrics
                    .map((metric) => Text(_metricLabel(localizations, metric)))
                    .toList(),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderWidth: 2,
                selectedBorderColor: Colors.blueAccent,
                isSelected: [
                  for (
                    var index = 0;
                    index < model.availableMetrics.length;
                    index++
                  )
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
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSlotChart(
    BuildContext context,
    ActivityDetailChartModel model,
  ) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.timeSlotActivity,
          style: chartTitleStyle,
        ),
        SizedBox(height: 10),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
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
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _barGroups(List<ActivityTimeSlotBar> bars) {
    return [for (final bar in bars) _barGroup(bar.x, bar.value)];
  }

  BarChartGroupData _barGroup(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: value, width: 15, gradient: gradientColors),
      ],
    );
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
      barrierLabel: AppLocalizations.of(context)!.dismissDialog,
      transitionDuration: Duration(milliseconds: 500),
      transitionBuilder: (ctx, animation, animation2, child) {
        final fadeTween = CurveTween(curve: Curves.easeInOut);
        final fadeAnimation = fadeTween.animate(animation);
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final timeStr = DateFormat('yyyy.MM.dd').format(day);
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.recordsOnDay(timeStr)),
          content: _buildDayRecords(context, widget.records, day),
        );
      },
    );
  }

  Widget _buildDayRecords(
    BuildContext context,
    List<ActivityRecord> records,
    DateTime day,
  ) {
    final details = activityRecordDetailsForDay(
      activity: widget.activity,
      records: records,
      day: day,
    );
    if (details.isEmpty) {
      return Text(AppLocalizations.of(context)!.noRecordsOnDay);
    }

    return SizedBox(
      width: 300,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: details.length,
        itemBuilder: (ctx, index) {
          return Text(_formatRecordDetail(context, details[index]));
        },
      ),
    );
  }

  String _metricLabel(
    AppLocalizations localizations,
    ActivityDetailMetric metric,
  ) {
    return switch (metric) {
      ActivityDetailMetric.duration => localizations.metricDuration,
      ActivityDetailMetric.count => localizations.metricCount,
      ActivityDetailMetric.value => widget.activity.requiredUnit,
    };
  }

  String _monthLabel(AppLocalizations localizations, DateTime? month) {
    if (month == null) {
      return '';
    }
    return DateFormat.MMM(localizations.localeName).format(month);
  }

  String _formatRecordDetail(
    BuildContext context,
    ActivityRecordDetail detail,
  ) {
    final locale = AppLocalizations.of(context)!.localeName;
    final endFormat = DateFormat.Md(locale).add_Hm();
    final end = endFormat.format(detail.endedAt);
    final timeRange = switch (detail.startedAt) {
      final start? => '${endFormat.format(start)} ~ $end',
      null => end,
    };
    final value = detail.value;
    if (value == null) {
      return timeRange;
    }
    return '$timeRange, ${NumberFormat.decimalPattern(locale).format(value)}${detail.unit}';
  }
}
