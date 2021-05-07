import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/commonWidget.dart';

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
  DateTime? displayDate;
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
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HeatMapCalendar(
                  dateRange: range,
                  input: data,
                  unit: "步",
                ),
              );
            default:
              return loadingScreen();
          }
        }));

    if (displayDate != null) {
      listChildren.add(Divider(
        height: 50,
      ));
      listChildren.add(SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
            margin: EdgeInsets.only(left: 10, top: 10),
            child: SizedBox(
                height: 300,
                width: 400,
                child: FutureBuilder<List<Record>>(
                    future: _dailySteps,
                    builder: (ctx, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.done:
                          List<Record> records = snapshot.data!;

                          records = records
                              .where((element) =>
                                  element.endTime!.month ==
                                      displayDate!.month &&
                                  element.endTime!.year == displayDate!.year)
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
                                minY: 0,
                                axisTitleData: FlAxisTitleData(
                                    bottomTitle: AxisTitle(
                                        showTitle: true,
                                        margin: 10,
                                        titleText:
                                            displayDate!.year.toString() +
                                                '年' +
                                                displayDate!.month.toString() +
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
                                          return (val / 1000)
                                                  .round()
                                                  .toString() +
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
                              if (records[i].value! > max)
                                max = records[i].value!;
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
                                titlesData: FlTitlesData(
                                    leftTitles: SideTitles(
                                        showTitles: true,
                                        getTitles: (double val) {
                                          return (val / 1000)
                                                  .round()
                                                  .toString() +
                                              'K';
                                        },
                                        interval: max / 6)),
                                borderData: FlBorderData(show: false),
                                barGroups: bars));
                          }
                        default:
                          return loadingScreen();
                      }
                    }))),
      ));
      listChildren.add(SwitchListTile(
        title: Text("显示累加值"),
        value: accumulate,
        onChanged: switchChange,
      ));
    }
    return Scaffold(
        appBar: AppBar(
          title: Text("行走统计"),
        ),
        body: Center(
            child: NotificationListener(
          onNotification: (MonthTouchedNotification n) {
            setState(() {
              displayDate = n.month;
            });
            return true;
          },
          child: ListView(
            children: listChildren,
          ),
        )));
  }
}
