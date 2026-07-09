import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:event_tracker/analytics/activity_detail_analytics.dart';
import 'package:event_tracker/common/commonWidget.dart';
import 'package:event_tracker/common/const.dart';
import 'package:event_tracker/common/util.dart';
import 'package:intl/intl.dart';
import 'package:sprintf/sprintf.dart';

import '../DAO/base.dart';
import '../heatmap_calendar/heatMap.dart';
import '../persistence/activity_repository.dart';

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
  final ActivityRepository _repository = activityRepository();
  List<String> toggleTexts = [];
  List<bool> isSelected = [true];
  final ScrollController _scrollController = ScrollController();
  DateTime month = nilTime;

  @override
  void initState() {
    super.initState();
    _records = _repository.getActivityRecords(widget.event.id);
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
    if (!_scrollController.hasClients) {
      return;
    }
    var scrollPosition = _scrollController.position;
    if (scrollPosition.maxScrollExtent > scrollPosition.minScrollExtent) {
      _scrollController.animateTo(scrollPosition.maxScrollExtent,
          duration: Duration(seconds: 1), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              final selectedIndex = getSelected(isSelected);
              final selectedMetric =
                  metricForActivitySelection(widget.event, selectedIndex);
              final heatMapSeries = buildActivityHeatmapSeries(
                records: records,
                activity: widget.event,
                metric: selectedMetric,
                now: DateTime.now(),
              );
              List<Record> recordsOfMonth = [];
              List<Widget> toggleChildren =
                  toggleTexts.map((e) => Text(e)).toList();
              int numOfRecords;
              String heading;
              if (month == nilTime) {
                numOfRecords = records.length;
                heading = "共进行";
              } else {
                recordsOfMonth = recordsInMonth(records, month);
                numOfRecords = recordsOfMonth.length;
                heading = month.month.toString() + "月共进行";
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                scrollToEnd(context);
              });
              var heatMap = Column(
                children: [
                  Center(
                      child: Text(
                    "统计数据 - " + toggleTexts[selectedIndex],
                    style: chartTitleStyle,
                  )),
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
              var barChart;
              if (recordsOfMonth.isNotEmpty) {
                barChart = getTimeSlotsBar(
                    recordsOfMonth, widget.event, selectedMetric);
              } else {
                barChart =
                    getTimeSlotsBar(records, widget.event, selectedMetric);
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
                    await _repository.deleteActivity(widget.event.id);
                    Navigator.of(context).pop(true);
                  }
                },
                icon: Icon(Icons.delete))
          ],
          title: Text(sprintf("%s - 项目详细", [widget.event.name])),
        ),
        body: NotificationListener(
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
    records = recordsOnDay(records, time);
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

  Widget getTimeSlotsBar(
    List<Record> records,
    BaseEventModel event,
    ActivityDetailMetric metric,
  ) {
    List<BarChartGroupData> bars = [];
    final timeSlotSeries = buildActivityTimeSlotSeries(
      records: records,
      activity: event,
      metric: metric,
    );
    final data = timeSlotSeries.hourlyValues;
    List<double> processedData = [];
    double maxVal = 0;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      processedData = combineAdjacentHourSlots(data);
      for (final val in processedData) {
        if (val > maxVal) maxVal = val;
      }
      for (int i = 0; i < 12; i++) {
        bars.add(BarChartGroupData(x: i * 2, barRods: [
          BarChartRodData(
              toY: processedData[i], width: 15, gradient: gradientColors)
        ]));
      }
    } else {
      for (int i = 0; i < 24; i++) {
        if (data[i] > maxVal) maxVal = data[i];
        bars.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: data[i], width: 15, gradient: gradientColors)
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
              // axisTitleData:
              //     FlAxisTitleData(topTitle: AxisTitle(textAlign: TextAlign.start, showTitle: true, titleText: unit)),
              barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(rod.toY.toInt().toString(),
                            TextStyle(color: Colors.white, fontSize: 18));
                      })),
              // groupsSpace: 30,
              // alignment: BarChartAlignment.start,
              titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double val, TitleMeta meta) {
                            return Text(val.floor().toString());
                          },
                          interval: maxVal / 6))),
              borderData: FlBorderData(show: false),
              barGroups: bars)))
    ]);
    return barChart;
  }
}
