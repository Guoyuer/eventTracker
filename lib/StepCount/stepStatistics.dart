import 'dart:async';
import 'dart:math';
import 'package:sprintf/sprintf.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/commonWidget.dart';
import 'package:intl/intl.dart';

import '../DAO/base.dart';
import '../common/const.dart';
import '../heatmap_calendar/heatMap.dart';
import '../heatmap_calendar/util.dart';

class StepStatPage extends StatelessWidget {
  StepStatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StepStatPageContent();
  }
}

class StepStatPageContent extends StatefulWidget {
  @override
  _StepStatPageContentState createState() => _StepStatPageContentState();
}

class _StepStatPageContentState extends State<StepStatPageContent> {
  // Stream<StepCount> _stepCountStream;
  // StreamSubscription _subscription;
  var db = DBHandle().db;
  late Future<List<Record>> _dailySteps;
  DateTime? displayMonth;
  DateTime? displayDay;
  bool accumulate = false;

  // StepDisplayModel countEvent; //初始的时候是null，注意判别
  // List<DateTime> _events = [];
  // int called = 0;

  // bool _BGEnabled;

  @override
  void initState() {
    super.initState();
    _dailySteps = db.getRecordsByEventId(-1);
  }

  void switchChange(bool val) {
    setState(() {
      accumulate = !accumulate;
    });
  }

  Widget getFakeTimeSlotBar() {
    List<BarChartGroupData> bars = [];
    final _random = new Random();
    int next(int min, int max) => min + _random.nextInt(max - min);
    List<int> data = [];
    double maxVal = 0;
    for (int i = 0; i < 24; i++) {
      int num = next(0, 1000);
      data.add(num);
      if (num > maxVal) maxVal = num.toDouble();
    }
    for (int i = 0; i < 24; i++) {
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(y: data[i].toDouble(), width: 8, colors: gradientColors)
      ]));
    }

    var barChart = Column(children: [
      Text(
        sprintf("%s月%s日步行情况",
            [displayDay!.month.toString(), displayDay!.day.toString()]),
        style: chartTitleStyle,
      ),
      SizedBox(height: 10),
      Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          height: 300,
          // width: 350,
          child: BarChart(BarChartData(
              axisTitleData: FlAxisTitleData(
                  topTitle: AxisTitle(
                      textAlign: TextAlign.start,
                      showTitle: true,
                      titleText: "步")),
              barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.lightBlueAccent)),
              // groupsSpace: 30,
              // alignment: BarChartAlignment.start,
              titlesData: FlTitlesData(
                  leftTitles: SideTitles(
                      showTitles: true,
                      getTitles: (double val) {
                        return val.floor().toString();
                      },
                      interval: maxVal / 6)),
              borderData: FlBorderData(show: false),
              barGroups: bars)))
    ]);

    return barChart;
  }

  @override
  Widget build(BuildContext context) {
    Map<DateTime, double> data = {};
    List<Widget> listChildren = [];
    listChildren.add(FutureBuilder<List<Record>>(
        future: _dailySteps,
        builder: (ctx, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              List<Record> records = snapshot.data!;
              if (records.isEmpty) return Text("No data");
              DateTimeRange range = DateTimeRange(
                  start: getDate(records[0].endTime!),
                  end: getDate(records.last.endTime!));
              records.forEach((record) {
                var date = getDate(record.endTime!);
                if (data.containsKey(date)) {
                  data[date] = data[date]! + record.value!;
                } else {
                  data[date] = record.value!;
                }
              });
              return Center(
                  child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HeatMapCalendar(
                  dateRange: range,
                  input: data,
                  unit: "步",
                ),
              ));
            default:
              return loadingScreen();
          }
        }));

    if (displayMonth != null) {
      listChildren.add(SizedBox(
        height: 50,
        child: Center(
            child: Text(
          displayMonth!.month.toString() + "月步数统计",
          style: chartTitleStyle,
        )),
      ));
      listChildren.add(
        Container(
            height: 300,
            margin: EdgeInsets.all(5),
            child: FutureBuilder<List<Record>>(
                future: _dailySteps,
                builder: (ctx, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.done:
                      List<Record> records = snapshot.data!;

                      records = records
                          .where((element) =>
                              element.endTime!.month == displayMonth!.month &&
                              element.endTime!.year == displayMonth!.year)
                          .toList(); //只保留本月的记录，

                      if (accumulate) {
                        List<FlSpot> spots = [];
                        List<double> values = [];
                        values.add(records[0].value!);
                        double max = values[0];
                        for (int i = 1; i < records.length; i++) {
                          values.add(values[i - 1] + records[i].value!);
                          if (values[i] > max) max = values[i];
                        }
                        for (int i = 0; i < records.length; i++) {
                          spots.add(FlSpot((i + 1).toDouble(), values[i]));
                        }
                        return LineChart(LineChartData(
                            lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey,
                                    getTooltipItems: (lines) {
                                      List<LineTooltipItem> l = [];
                                      l.add(LineTooltipItem(
                                          lines[0].y.toInt().toString(),
                                          TextStyle(
                                              color: Colors.white,
                                              fontSize: 18)));
                                      return l;
                                    })),
                            minY: 0,
                            axisTitleData: FlAxisTitleData(
                                bottomTitle: AxisTitle(
                                    showTitle: true,
                                    margin: 10,
                                    titleText: displayMonth!.year.toString() +
                                        '年' +
                                        displayMonth!.month.toString() +
                                        '月')),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                horizontalInterval: max / 6),
                            titlesData: FlTitlesData(
                                leftTitles: SideTitles(
                                    showTitles: true,
                                    getTitles: (double val) {
                                      return (val / 1000).round().toString() +
                                          'K';
                                    },
                                    interval: max / 6),
                                bottomTitles: SideTitles(
                                    showTitles: true,
                                    getTitles: (double val) {
                                      int tmp = val.toInt();
                                      if (tmp % 6 == 1) {
                                        return tmp.toString() + '日';
                                      } else {
                                        return "";
                                      }
                                    })),
                            lineBarsData: [
                              LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  colors: gradientColors,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    colors: gradientColors,
                                    // gradientFrom:Offset(0,1),
                                    // gradientTo:Offset(0,0)
                                    // cutOffY: cutOffYValue,
                                    // applyCutOffY: true,
                                  ))
                            ]));
                      } else {
                        List<double> values = [];
                        double max = 0;
                        for (int i = 0; i < records.length; i++) {
                          values.add(records[i].value!);
                          if (records[i].value! > max) max = records[i].value!;
                        }
                        List<BarChartGroupData> bars = [];
                        for (int i = 0; i < records.length; i++) {
                          bars.add(BarChartGroupData(x: i + 1, barRods: [
                            BarChartRodData(
                                y: values[i],
                                colors: gradientColors,
                                backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    y: max,
                                    colors: [Color(0xff72d8bf)]))
                          ]));
                        }

                        return BarChart(BarChartData(
                            // groupsSpace: 18,
                            // alignment: BarChartAlignment.start,
                            barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                          rod.y.toInt().toString(),
                                          TextStyle(
                                              color: Colors.white,
                                              fontSize: 18));
                                    })),
                            titlesData: FlTitlesData(
                                leftTitles: SideTitles(
                                    showTitles: true,
                                    getTitles: (double val) {
                                      return (val / 1000).round().toString() +
                                          'K';
                                    },
                                    interval: max / 6)),
                            borderData: FlBorderData(show: false),
                            barGroups: bars));
                      }
                    default:
                      return loadingScreen();
                  }
                })),
      );
      listChildren.add(SwitchListTile(
        title: Text("显示累加值"),
        value: accumulate,
        onChanged: switchChange,
      ));
    }

    if (displayDay != null) {
      listChildren.add(getFakeTimeSlotBar());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("行走统计"),
      ),
      body: NotificationListener(
        onNotification: (Notification n) {
          if (n is MonthTouchedN) {
            setState(() {
              displayMonth = n.month;
              displayDay = null;
            });
          }
          if (n is DayTouchedN) {
            setState(() {
              displayDay = n.day;
              displayMonth = null;
            });
          }
          return true;
        },
        child: ListView(children: listChildren),
      ),
    );
  }
}
