import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'package:sprintf/sprintf.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_event_tracker/common/util.dart';
import '../DAO/base.dart';
import 'util.dart';
import '../heatmap_calendar/heatMap.dart';
import 'package:intl/intl.dart';
import 'dart:collection';
import '../common/const.dart';
import 'package:fl_chart/fl_chart.dart';

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

  DateTime month = nilTime;
  List<Record> recordsOfMonth = [];

  // DateTime dayOfRecords = nilTime;

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



  Map<String, dynamic> processRecord(List<Record> records) {
    // DateTimeRange range;
    Map<DateTime, double> data = {};
    DateTimeRange range = DateTimeRange(
        start: getDate(records[0].endTime!),
        end: getDate(records.last.endTime!));
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

  //keep your build pure
  @override
  Widget build(BuildContext context) {
    List<Widget> listChildren = [];
    listChildren.add(DividerWithText("项目描述"));
    bool timeVisible = true;
    if (widget.event.description == null) {
      listChildren.add(
        ListTile(title: Center(child: Text("无项目描述"))),
      );
    } else {
      listChildren
          .add(Center(child: ListTile(title: Text(widget.event.description!))));
    }

    ///前三项紧密关联，共用一个FutureBuilder
    if (widget.event.lastRecordId != null) {
      listChildren.add(FutureBuilder<List<Record>>(
          future: _records,
          builder: (ctx, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                List<Record> records = snapshot.data!;
                var map = processRecord(records);
                List<Widget> toggleChildren = [];
                toggleTexts.forEach((element) {
                  toggleChildren.add(Text(element));
                });
                int numOfRecords = records.length;
                String heading = "共进行 ";
                if (month != nilTime) {
                  List<Record> recordsOfMonth =
                      getRecordPerMonth(records, month);
                  listChildren.add(getTimeSlotsBar(recordsOfMonth, month));
                  numOfRecords = recordsOfMonth.length;
                  heading = month.month.toString() + "月共进行 ";
                }
                return Column(
                  // shrinkWrap: true,
                  // scrollDirection: Axis.vertical,
                  children: [
                    Center(
                        child: Text(
                      "统计数据 - " + toggleTexts[getSelected(isSelected)],
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    )),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: HeatMapCalendar(
                          dateRange: map['range'],
                          input: map['data'],
                          unit: toolTipUnit,
                        ),
                      ),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Visibility(
                              visible: timeVisible,
                              child: Container(
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
                                  ))),
                          Container(
                              margin: EdgeInsets.only(right: 10),
                              child: ToggleButtons(
                                  children: toggleChildren,
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
                break;
              default:
                return loadingScreen();
            }
          }));
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
                    ReloadEventsNotification().dispatch(context);
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(Icons.delete))
          ],
          title: Text(sprintf("%s - 项目详情", [widget.event.name])),
        ),
        body: NotificationListener(
            //在更高处监听，避免setState影响heatMap
            onNotification: (Notification notification) {
              if (notification is MonthTouchedNotification) {
                setState(() {
                  month = notification.month;
                });
              }
              if (notification is DayTouchedNotification) {
                showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "dismiss",
                    transitionDuration: Duration(milliseconds: 500),
                    transitionBuilder: (ctx, animation, animation2, child) {
                      var fadeTween = CurveTween(curve: Curves.fastOutSlowIn);
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
    if (records.isEmpty) return Text("该日无记录");
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
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: tiles.length,
        itemBuilder: (ctx, idx) {
          return tiles[idx];
        });
  }

  List<Record> getRecordPerMonth(List<Record> records, DateTime month) {
    records = records
        .where((element) =>
            element.endTime!.month == month.month &&
            element.endTime!.year == month.year)
        .toList(); //只保留本月的记录，
    return records;
  }

  Widget getTimeSlotsBar(List<Record> records, DateTime month) {
    List<BarChartGroupData> bars = [];
    List<int> data = List.filled(24, 0); //次数、时长（分钟）、物理量
    if (widget.event is TimingEventModel) {
      if (getSelected(isSelected) == 0) {
        //得到时长统计信息
        List<DateTimeRange> ranges = [
          for (Record record in records)
            DateTimeRange(start: record.startTime!, end: record.endTime!)
        ];
        data = getTimeSlotSumTime(ranges);
      } else {
        data = getTimeSlotSumVal(records);
      }
    } else {
      //plain
      if (getSelected(isSelected) == 0) {
        data = getTimeSlotSumNum(records);
      } else {
        data = getTimeSlotSumVal(records);
      }
    }
    List<double> processedData = [];
    double max = 0;
    for (int i = 0; i < 12; i++) {
      double val = data[i * 2].toDouble() + data[i * 2 + 1];
      if (val > max) max = val;
      processedData.add(val);
    }
    for (int i = 0; i < 12; i++) {
      bars.add(BarChartGroupData(x: i * 2, barRods: [
        BarChartRodData(y: processedData[i], width: 15, colors: gradientColors)
      ]));
    }
    var barChart = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
            margin: EdgeInsets.only(left: 5, top: 10, right: 5),
            child: Column(children: [
              Text("时段活跃度"),
              SizedBox(height: 10),
              SizedBox(
                  height: 300,
                  width: 350,
                  child: BarChart(BarChartData(
                      groupsSpace: 18,
                      // alignment: BarChartAlignment.start,
                      titlesData: FlTitlesData(
                          leftTitles: SideTitles(
                              showTitles: true,
                              getTitles: (double val) {
                                return val.round().toString();
                              },
                              interval: max / 6)),
                      borderData: FlBorderData(show: false),
                      barGroups: bars)))
            ])));
    return barChart;
  }
}
