import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_event_tracker/common/commonWidget.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/common/util.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';

import '../DAO/base.dart';
import '../common/const.dart';
import '../heatmap_calendar/heatMap.dart';
import 'util.dart';

class EventDetailsWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BaseEventModel event =
        ModalRoute.of(context)!.settings.arguments as BaseEventModel;
    return EventDetails(event: event);
  }
}

class EventDetails extends StatefulWidget {
  EventDetails({Key? key, required this.event}) : super(key: key);
  final BaseEventModel event;

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  Future<List<Record>>? _records;
  AppDatabase db = DBHandle().db;
  List<String> toggleTexts = [];
  List<bool> isSelected = [true];
  late String toolTipUnit;
  ScrollController _c = ScrollController();
  DateTime month = nilTime;

  @override
  void initState() {
    super.initState();
    _records = db.getRecordsByEventId(widget.event.id);
    if (widget.event is TimingEventModel) {
      toggleTexts.add("时长");
    } else {
      toggleTexts.add("次数");
    }
    if (widget.event.unit != null) {
      toggleTexts.add(widget.event.unit!);
      isSelected.add(false);
    }
  }

  void scrollToEnd(BuildContext context) {
    if (!_c.hasClients) {
      return;
    }
    var scrollPosition = _c.position;
    if (scrollPosition.maxScrollExtent > scrollPosition.minScrollExtent) {
      _c.animateTo(scrollPosition.maxScrollExtent,
          duration: Duration(seconds: 1), curve: Curves.easeOutCubic);
    }
  }

  Map<String, dynamic> processRecord(List<Record> records) {
    // DateTimeRange range;
    Map<DateTime, double> data = {};
    DateTimeRange range = DateTimeRange(
        start: getDate(records[0].endTime!), end: getDate(DateTime.now()));
    if (widget.event is TimingEventModel) {
      if (getSelected(isSelected) == 0) {
        //得到时长统计信息
        toolTipUnit = "分钟";
        Map<DateTime, Duration> tmp = {};
        records.forEach((record) {
          var date = getDate(record.endTime!);
          if (tmp.containsKey(date) && record.endTime != null) {
            tmp[date] =
                tmp[date]! + record.endTime!.difference(record.startTime!);
          } else {
            tmp[date] = record.endTime!.difference(record.startTime!);
          }
        });
        tmp.forEach((key, value) {
          data[key] = value.inMinutes.toDouble();
        }); //转换为数值
      } else {
        //得到物理量统计信息
        toolTipUnit = widget.event.unit!;
        records.forEach((record) {
          var date = getDate(record.endTime!);
          if (data.containsKey(date)) {
            data[date] = data[date]! + record.value!;
          } else {
            data[date] = record.value!;
          }
        });
      }
    } else {
      //plain
      // range = DateTimeRange(
      //     start: getDate(records[0].endTime!),
      //     end: getDate(records.last.endTime!));
      if (getSelected(isSelected) == 0) {
        toolTipUnit = "次数";
        //得到次数统计信息
        records.forEach((record) {
          var date = getDate(record.endTime!); //因为没有startTime
          if (data.containsKey(date)) {
            data[date] = data[date]! + 1;
          } else {
            data[date] = 1;
          } //转换为数值
        });
      } else {
        //得到数值统计信息
        toolTipUnit = widget.event.unit!;
        records.forEach((record) {
          var date = getDate(record.endTime!); //因为没有startTime
          if (data.containsKey(date)) {
            data[date] = data[date]! + record.value!;
          } else {
            data[date] = record.value!;
          } //转换为数值
        });
      }
    }
    return {"range": range, "data": data};
  }

  Widget getEventDescWidget() {
    return Card(
        elevation: 10,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Align(
                alignment: Alignment.center,
                child: Text(
                  "项目描述",
                  style: chartTitleStyle,
                )),
            Align(
                alignment: Alignment.center,
                child: DescEditable(widget.event.id))
          ],
        ));
  }

  Widget get2Charts() {
    return FutureBuilder<List<Record>>(
        future: _records,
        builder: (ctx, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              List<Record> records = snapshot.data!;
              var dataForHeatMap = processRecord(records);
              List<Record> recordsOfMonth = [];
              List<Widget> toggleChildren =
                  toggleTexts.map((e) => Text(e)).toList();
              int numOfRecords;
              String heading;
              if (month == nilTime) {
                numOfRecords = records.length;
                heading = "共进行";
              } else {
                recordsOfMonth = getRecordPerMonth(records, month);
                numOfRecords = recordsOfMonth.length;
                heading = month.month.toString() + "月共进行";
              }
              WidgetsBinding.instance!.addPostFrameCallback((_) {
                scrollToEnd(context);
              });
              var heatMap = Column(
                //heatMap, title,
                // shrinkWrap: true,
                // scrollDirection: Axis.vertical,
                children: [
                  Center(
                      child: Text(
                    "统计数据 - " + toggleTexts[getSelected(isSelected)],
                    style: chartTitleStyle,
                  )),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    width: double.infinity,
                    child: SingleChildScrollView(
                      controller: _c,
                      scrollDirection: Axis.horizontal,
                      child: HeatMapCalendar(
                        dateRange: dataForHeatMap['range'],
                        input: dataForHeatMap['data'],
                        unit: toolTipUnit,
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
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black),
                                  children: [
                                    TextSpan(text: heading),
                                    TextSpan(
                                        text: '$numOfRecords',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    TextSpan(text: " 次")
                                  ]),
                            )),
                        Container(
                            height: 35,
                            margin: EdgeInsets.all(10),
                            child: ToggleButtons(
                                children: toggleChildren,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderWidth: 2,
                                selectedBorderColor: Colors.blueAccent,
                                isSelected: isSelected,
                                onPressed: (int index) {
                                  if (index != getSelected(isSelected)) {
                                    for (int i = 0;
                                        i < isSelected.length;
                                        i++) {
                                      setState(() {
                                        if (i == index) {
                                          isSelected[i] = true;
                                        } else {
                                          isSelected[i] = false;
                                        }
                                      });
                                    }
                                  }
                                }))
                      ]),
                ],
              );
              // _c.jumpTo(value)
              var barChart;
              if (recordsOfMonth.isNotEmpty) {
                barChart = getTimeSlotsBar(recordsOfMonth, widget.event);
              } else {
                barChart = getTimeSlotsBar(records, widget.event);
              }
              List<Widget> charts = [heatMap, barChart];
              charts = charts
                  .map((e) => Card(
                        elevation: 10,
                        child: e,
                      ))
                  .toList();

              return Column(
                children: charts,
              );
            default:
              return loadingScreen();
          }
        });
  }

  //keep your build pure
  @override
  Widget build(BuildContext context) {
    List<Widget> listChildren = [getEventDescWidget()];

    if (widget.event.lastRecordId != null) {
      listChildren.add(get2Charts());
    } else {
      listChildren.add(Text("暂无记录"));
    }

    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () async {
                  bool? delete = await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("是否删除该项目及所有记录？"),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text("否")),
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text("是"))
                          ],
                        );
                      });
                  if (delete != null && delete) {
                    var db = DBHandle().db;
                    db.deleteEvent(widget.event.id);
                    Navigator.of(context).pop(true);
                  }
                },
                icon: Icon(Icons.delete))
          ],
          title: Text(sprintf("%s - 项目详细", [widget.event.name])),
        ),
        body: NotificationListener(
            //在更高处监听，避免setState影响heatMap
            onNotification: (Notification notification) {
              if (notification is MonthTouchedN) {
                setState(() {
                  month = notification.month;
                });
              }
              if (notification is DayTouchedN) {
                showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "dismiss",
                    transitionDuration: Duration(milliseconds: 500),
                    transitionBuilder: (ctx, animation, animation2, child) {
                      var fadeTween = CurveTween(curve: Curves.easeInOut);
                      var fadeAnimation = fadeTween.animate(animation);
                      return FadeTransition(
                          opacity: fadeAnimation, child: child);
                    },
                    pageBuilder: (BuildContext context,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation) {
                      DateTime day = notification.day;
                      String timeStr = DateFormat('yyyy.MM.dd').format(day);
                      return AlertDialog(
                        title: Text(timeStr + "的记录"),
                        content: FutureBuilder<List<Record>>(
                            future: _records,
                            builder: (ctx, snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.done:
                                  List<Record> records = snapshot.data!;
                                  return getDayRecordsWidgets(
                                      records, day, widget.event);
                                default:
                                  return loadingScreen();
                              }
                            }),
                      );
                    });
              }
              return true;
            },
            child: ListView(children: listChildren)));
  }

  Widget getDayRecordsWidgets(
      List<Record> records, DateTime time, BaseEventModel event) {
    List<Widget> tiles = [];
    records = records
        .where((element) =>
            element.endTime!.month == time.month &&
            element.endTime!.year == time.year &&
            element.endTime!.day == time.day)
        .toList(); //只保留本日的记录，
    if (records.isEmpty) return Text("当日无记录");
    records.forEach((record) {
      if (event is TimingEventModel) {
        String startTimeStr =
            DateFormat('MM-dd kk:mm').format(record.startTime!);
        // if (startTimeStr.substring(0, 2) == '24')
        //   startTimeStr = '00' + startTimeStr.substring(2);
        String endTimeStr = DateFormat('MM-dd kk:mm').format(record.endTime!);
        // if (endTimeStr.substring(0, 2) == '24')
        //   endTimeStr = '00' + endTimeStr.substring(2);
        if (event.unit != null) {
          int value = record.value!.toInt();
          String unit = event.unit!;
          tiles.add(Text("$startTimeStr ~ $endTimeStr, $value$unit  "));
        } else {
          tiles.add(Text("$startTimeStr ~ $endTimeStr  "));
        }
      } else {
        String endTimeStr = DateFormat('kk:mm').format(record.endTime!);
        if (event.unit != null) {
          int value = record.value!.toInt();
          String unit = event.unit!;
          tiles.add(Text("$endTimeStr, $value$unit  "));
        } else {
          tiles.add(Text("$endTimeStr  "));
        }
      }
    });
    return Container(
        width: 300,
        // height: 500,
        child: ListView.builder(
            // physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: tiles.length,
            itemBuilder: (ctx, idx) {
              return tiles[idx];
            }));
  }

  List<Record> getRecordPerMonth(List<Record> records, DateTime month) {
    records = records
        .where((element) =>
            element.endTime!.month == month.month &&
            element.endTime!.year == month.year)
        .toList(); //只保留本月的记录，
    return records;
  }

  Widget getTimeSlotsBar(List<Record> records, BaseEventModel event) {
    String unit = "";
    List<BarChartGroupData> bars = [];
    List<double> data = List.filled(24, 0); //次数、时长（分钟）、物理量
    if (widget.event is TimingEventModel) {
      if (getSelected(isSelected) == 0) {
        //得到时长统计信息
        List<DateTimeRange> ranges = [
          for (Record record in records)
            DateTimeRange(start: record.startTime!, end: record.endTime!)
        ];
        data = getTimeSlotSumTime(ranges);
        double maxVal = data.reduce(max);
        //原始是秒
        //不让y轴显示200以上的值
        if (maxVal <= 500) {
          unit = "秒";
        } else {
          if (maxVal <= 500 * 60) {
            data = data.map((e) => e / 60).toList();
            unit = "分钟";
          } else {
            data = data.map((e) => e / 3600).toList();
            unit = "小时";
          }
        }
      } else {
        data = getTimeSlotSumVal(records);
        unit = "${event.unit}";
      }
    } else {
      //plain
      if (getSelected(isSelected) == 0) {
        data = getTimeSlotSumNum(records);
        unit = "次数";
      } else {
        data = getTimeSlotSumVal(records);
        unit = "${event.unit}";
      }
    }
    List<double> processedData = [];
    double maxVal = 0;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      for (int i = 0; i < 12; i++) {
        double val = data[i * 2] + data[i * 2 + 1];
        if (val > maxVal) maxVal = val;
        processedData.add(val);
      }
      for (int i = 0; i < 12; i++) {
        bars.add(BarChartGroupData(x: i * 2, barRods: [
          BarChartRodData(
              y: processedData[i], width: 15, colors: gradientColors)
        ]));
      }
    } else {
      for (int i = 0; i < 24; i++) {
        if (data[i] > maxVal) maxVal = data[i];
        bars.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(y: data[i], width: 15, colors: gradientColors)
        ]));
      }
    }
    var barChart = Column(children: [
      Text(
        "时段活跃度",
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
                      titleText: unit)),
              barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(rod.y.toInt().toString(),
                            TextStyle(color: Colors.white, fontSize: 18));
                      })),
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
}
