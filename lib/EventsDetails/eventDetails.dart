import 'package:flutter/material.dart';
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

//OK TODO 增加删除Event按钮
//OK TODO 按照val或sum的热力图
//OK TODO 热力图点上去显示值
//OK TODO 点击热力图某月自动显示月份记录
//OK TODO 将FutureBuilder最小化: HeatMap、Button、Text共用一个；recordInMonth共用一个避免不必要的重加载

//TODO 修复没有数据和少量数据时的Heatmap显示BUG
class EventDetailsWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BaseEventDisplayModel event =
        ModalRoute.of(context)!.settings.arguments as BaseEventDisplayModel;
    return EventDetails(event: event);
  }
}

class EventDetails extends StatefulWidget {
  EventDetails({Key? key, required this.event}) : super(key: key);
  final BaseEventDisplayModel event;

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  Future<List<Record>>? _records;
  AppDatabase db = DBHandle().db;
  List<String> toggleTexts = [];
  List<bool> isSelected = [true];
  late String toolTipUnit;

  DateTime monthOfRecords = nilTime;

  @override
  void initState() {
    super.initState();
    _records = db.getRecordsByEventId(widget.event.id);
    if (widget.event is TimingEventDisplayModel) {
      toggleTexts.add("时长");
    } else {
      toggleTexts.add("次数");
    }
    if (widget.event.unit != null) {
      toggleTexts.add(widget.event.unit!);
      isSelected.add(false);
    }
  }

  int getSelected(List<bool> list) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] == true) return i;
    }
    return -1;
  }

  //keep your build pure
  @override
  Widget build(BuildContext context) {
    Map<DateTime, double> data = {};
    List<Widget> listChildren = [];
    listChildren.add(DividerWithText("项目描述"));
    if (widget.event.description == null) {
      listChildren.add(Center(
        child: ListTile(title: Text("无项目描述")),
      ));
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
                if (records.isEmpty) {
                } else {}
                DateTimeRange range;
                if (widget.event is TimingEventDisplayModel) {
                  range = DateTimeRange(
                      start: getDate(records[0].startTime!),
                      end: getDate(records.last.startTime!));
                  if (getSelected(isSelected) == 0) {
                    //得到时长统计信息
                    toolTipUnit = "分钟";
                    Map<DateTime, Duration> tmp = {};
                    records.forEach((record) {
                      var date = getDate(record.startTime!);
                      if (tmp.containsKey(date) && record.endTime != null) {
                        tmp[date] = tmp[date]! +
                            record.endTime!.difference(record.startTime!);
                      } else {
                        tmp[date] =
                            record.endTime!.difference(record.startTime!);
                      }
                    });
                    tmp.forEach((key, value) {
                      data[key] = value.inMinutes.toDouble();
                    }); //转换为数值
                  } else {
                    //得到物理量统计信息
                    toolTipUnit = widget.event.unit!;
                    records.forEach((record) {
                      var date = getDate(record.startTime!);
                      if (data.containsKey(date)) {
                        data[date] = data[date]! + record.value!;
                      } else {
                        data[date] = record.value!;
                      }
                    });
                  }
                } else {
                  //plain
                  range = DateTimeRange(
                      start: getDate(records[0].endTime!),
                      end: getDate(records.last.endTime!));
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
                List<Widget> toggleChildren = [];
                toggleTexts.forEach((element) {
                  toggleChildren.add(Text(element));
                });
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
                          dateRange: range,
                          input: data,
                          unit: toolTipUnit,
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Container(
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
                                }))),
                  ],
                );
                break;
              default:
                return loadingScreen();
            }
          }));
      //显示月份records则再用一个FutureBuilder
      listChildren.add(FutureBuilder<List<Record>>(
          future: _records,
          builder: (ctx, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                List<Record> records = snapshot.data!;
                return getMonthRecordsWidgets(
                    records, monthOfRecords, widget.event);
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
            onNotification: (MonthTouchedNotification notification) {
              setState(() {
                monthOfRecords = notification.month;
              });
              return true;
            },
            child: ListView(children: listChildren)));
  }
}

Widget getMonthRecordsWidgets(
    List<Record> records, DateTime month, BaseEventDisplayModel event) {
  List<Widget> tiles = [];
  if (month != nilTime) {
    String yearStr = month.year.toString();
    String monthStr = month.month.toString();
    tiles.add(ListTile(title: Text(yearStr + "年" + monthStr + "月数据")));
  }

  records = records
      .where((element) =>
          element.endTime!.month == month.month &&
          element.endTime!.year == month.year)
      .toList(); //只保留本月的记录，

  // records.sort((a, b) => a.endTime.millisecondsSinceEpoch
  //     .compareTo(b.endTime.millisecondsSinceEpoch));
  // 一般是按照时间顺序写入数据库的，读取时也是。但以防万一还是再次排序

  //按照日来分
  LinkedHashMap<DateTime, List<Record>> recordsOfDays =
      new LinkedHashMap<DateTime, List<Record>>();
  records.forEach((record) {
    DateTime date = getDate(record.endTime!);
    if (!recordsOfDays.containsKey(date)) {
      List<Record> tmp = [];
      tmp.add(record);
      recordsOfDays[date] = tmp;
    } else {
      recordsOfDays[date]!.add(record);
    }
  });
  // records = null; //使其被垃圾回收
  recordsOfDays.forEach((date, recordsInDay) {
    //处理同一天的，他们放在一个Tile
    String dateStr = DateFormat('MM-dd').format(date);
    List<Widget> eachRecords = [];
    recordsInDay.forEach((element) {
      if (event is TimingEventDisplayModel) {
        String startTimeStr = DateFormat('kk:mm').format(element.startTime!);
        String endTimeStr = DateFormat('kk:mm').format(element.endTime!);
        if (event.unit != null) {
          int value = element.value!.toInt();
          String unit = event.unit!;
          eachRecords.add(Text("$startTimeStr ~ $endTimeStr, $value$unit  "));
        } else {
          eachRecords.add(Text("$startTimeStr ~ $endTimeStr  "));
        }
      } else {
        String endTimeStr = DateFormat('kk:mm').format(element.endTime!);
        if (event.unit != null) {
          int value = element.value!.toInt();
          String unit = event.unit!;
          eachRecords.add(Text("$endTimeStr, $value$unit  "));
        } else {
          eachRecords.add(Text("$endTimeStr  "));
        }
      }
    });
    tiles.add(ListTile(
      title: Text(dateStr),
      subtitle: Wrap(children: eachRecords),
    ));
  });
  return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: tiles.length,
      itemBuilder: (ctx, idx) {
        return tiles[idx];
      });
}
