import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import '../heatmap_calendar/heatMap.dart';
import '../heatmap_calendar/util.dart';
import '../heatmap_calendar/heatMapBuildingBlocks.dart';
import '../DAO/base.dart';
import '../common/const.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:background_fetch/background_fetch.dart';
import 'dart:async';
import '../main.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepDisplayModel {
  int step = 0;
  DateTime time = nilTime;

  StepDisplayModel({this.step, this.time});
}

class PedometerPage extends StatelessWidget {
  PedometerPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PedometerPageBuildingBlock();
  }
}

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class PedometerPageBuildingBlock extends StatefulWidget {
  @override
  _PedometerPageBuildingBlockState createState() =>
      _PedometerPageBuildingBlockState();
}

class _PedometerPageBuildingBlockState
    extends State<PedometerPageBuildingBlock> {
  // Stream<StepCount> _stepCountStream;
  // StreamSubscription _subscription;
  var db = DBHandle().db;
  Future<List<Record>> _dailySteps;
  DateTime displayDate = DateTime(2021, 2);
  bool accumulate = false;

  // StepDisplayModel countEvent; //初始的时候是null，注意判别
  // List<DateTime> _events = [];
  // int called = 0;

  // bool _BGEnabled;

  @override
  void initState() {
    super.initState();
    _dailySteps = db.getRecordsByEventId(-1);
    // initPlatformState();
    // getLastStep();
  }

  // void getLastStep() async {
  //   var tmp = await db.getLatestStep();
  //   if (tmp != null) {
  //     countEvent = StepDisplayModel(step: tmp.step, time: tmp.time);
  //   }
  // }

  // void wrapper(Future<StepCount> event) {
  //   print("wrapper called");
  //   event.then((value) => onStepCount(value));
  // }

  // void onStepCount(StepCount event) async {
  //   print("onStepCount called");
  //   print(event);
  //   //处理offset
  //   int offset = 0;
  //   StepOffsetData lastOffset = await db.getStepOffset();
  //   if (lastOffset == null) {
  //     await db.writeStepOffset(event.steps, event.timeStamp);
  //     offset = event.steps;
  //   } else {
  //     if ((lastOffset.time.day != event.timeStamp.day) ||
  //         lastOffset.step > event.steps) {
  //       //与上次记录相比过了一天 或者 系统重启
  //       await db.updateStepOffset(event.steps, event.timeStamp);
  //       offset = event.steps;
  //     } else {
  //       offset = lastOffset.step;
  //     }
  //   }
  //   //计算步数
  //
  //   setState(() {
  //     countEvent =
  //         StepDisplayModel(step: event.steps - offset, time: event.timeStamp);
  //   });
  //   db.writeStep(event.steps - offset, event.timeStamp);
  // }

  // void onStepCountError(error) {
  //   print('onStepCountError: $error');
  // }
  //
  // void _onBackgroundFetch(String taskId) async {
  //   // _stepCountStream.listen(onStepCount);
  //   // print("add a listen");
  //   var event = _stepCountStream.last;
  //   wrapper(event);
  //   BackgroundFetch.finish(taskId);
  // }
  //
  // void _onBackgroundFetchTimeout(String taskId) {
  //   print("[Step Count] TIMEOUT: $taskId");
  //   BackgroundFetch.finish(taskId);
  // }

//   void _onBackgroundFetch (String taskId) async {
//   var event = await _stepCountStream.last;
//   print(event);
//   onStepCount(event);
//   // _stepCountStream.listen(onStepCount).onError(onStepCountError);
//   print("Stream元素：");
//   print(_stepCountStream.length);
//   // <-- Event handler
//   // This is the fetch-event callback.
//   print("[Step Count] Event received $taskId");
//
//   // IMPORTANT:  You must signal completion of your task or the OS can punish your app
//   // for taking too long in the background.
//   BackgroundFetch.finish(taskId);
// }
  void initPlatformState() async {
    // _stepCountStream = Pedometer.stepCountStream;
    // _subscription = _stepCountStream.listen(onStepCount);

    // int status = await BackgroundFetch.configure(
    //     BackgroundFetchConfig(
    //         minimumFetchInterval: 15,
    //         stopOnTerminate: false,
    //         enableHeadless: true,
    //         requiresBatteryNotLow: false,
    //         requiresCharging: false,
    //         requiresStorageNotLow: false,
    //         requiresDeviceIdle: false,
    //         requiredNetworkType: NetworkType.NONE),
    //     _onBackgroundFetch,
    //     _onBackgroundFetchTimeout);
    // print('[Step Count] configure success: $status');
    // if (!mounted) return;
  }

  // void _onClickBGEnable(enabled) {
  //   setState(() {
  //     _BGEnabled = enabled;
  //   });
  //   if (enabled) {
  //     BackgroundFetch.start().then((int status) {
  //       print("BG启动成功");
  //     }).catchError((e) {
  //       print("BG启动失败: $e");
  //     });
  //   } else {
  //     BackgroundFetch.stop().then((int status) {
  //       print("BG停止成功");
  //     });
  //   }
  // }

  void switchChange(bool val) {
    setState(() {
      accumulate = !accumulate;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<DateTime, double> data = {};
    return Center(
        child: NotificationListener(
      onNotification: (MonthTouchedNotification n) {
        setState(() {
          displayDate = n.month;
        });
        return true;
      },
      child: ListView(
        children: [
          FutureBuilder<List<Record>>(
              future: _dailySteps,
              builder: (ctx, snapshot) {
                List<Record> records = snapshot.data;
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    if (records.isEmpty) return Text("No data");
                    DateTimeRange range = DateTimeRange(
                        start: getDate(records[0].endTime),
                        end: getDate(records.last.endTime));
                    records.forEach((record) {
                      var date = getDate(record.endTime);
                      if (data.containsKey(date)) {
                        data[date] += record.value;
                      } else {
                        data[date] = record.value;
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
              }),
          Divider(
            height: 50,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
                margin: EdgeInsets.only(left: 10, top: 10),
                child: SizedBox(
                    height: 300,
                    width: 400,
                    child: FutureBuilder<List<Record>>(
                        future: _dailySteps,
                        builder: (ctx, snapshot) {
                          List<Record> records = snapshot.data;
                          switch (snapshot.connectionState) {
                            case ConnectionState.done:
                              List<Color> gradientColors = [
                                Color.fromARGB(255, 235, 237, 240),
                                Color.fromARGB(255, 155, 233, 168),
                                Color.fromARGB(255, 64, 196, 99),
                                Color.fromARGB(255, 48, 161, 78),
                                Color.fromARGB(255, 33, 110, 57),
                              ];
                              records = records
                                  .where((element) =>
                                      element.endTime.month ==
                                          displayDate.month &&
                                      element.endTime.year == displayDate.year)
                                  .toList(); //只保留本月的记录，

                              if (accumulate) {
                                List<FlSpot> spots = [];
                                List<double> values = [];
                                values.add(records[0].value);
                                double max = values[0];
                                for (int i = 1; i < records.length; i++) {
                                  values.add(values[i - 1] + records[i].value);
                                  if (values[i] > max) max = values[i];
                                }
                                for (int i = 0; i < records.length; i++) {
                                  spots.add(
                                      FlSpot((i + 1).toDouble(), values[i]));
                                }
                                return LineChart(LineChartData(
                                    minY: 0,
                                    axisTitleData: FlAxisTitleData(
                                        bottomTitle: AxisTitle(
                                            showTitle: true,
                                            margin: 10,
                                            titleText: displayDate.year
                                                    .toString() +
                                                '年' +
                                                displayDate.month.toString() +
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
                                  values.add(records[i].value);
                                  if (records[i].value > max)
                                    max = records[i].value;
                                }
                                List<BarChartGroupData> bars = [];
                                for (int i = 0; i < records.length; i++) {
                                  bars.add(
                                      BarChartGroupData(x: i + 1, barRods: [
                                    BarChartRodData(
                                        y: values[i],
                                        colors: gradientColors,
                                        backDrawRodData:
                                            BackgroundBarChartRodData(
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
                              break;
                            default:
                              return loadingScreen();
                          }
                        }))),
          ),
          SwitchListTile(
            title: Text("显示累加值"),
            value: accumulate,
            onChanged: switchChange,
          )
        ],
      ),
    ));
  }
}
