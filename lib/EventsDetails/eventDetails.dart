import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'package:sprintf/sprintf.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_event_tracker/common/util.dart';
import '../DAO/base.dart';
import 'util.dart';
import '../heatmap_calendar/heatMap.dart';

class EventDetails extends StatefulWidget {
  EventDetails({Key key}) : super(key: key);

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  Future<List<Record>> _records;
  AppDatabase db;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    db = DBHandle().db;
    BaseEventDisplayModel event = ModalRoute.of(context).settings.arguments;
    _records = db.getAllRecords(event.id);

    Map<DateTime, double> data = {};
    return FutureBuilder<List<Record>>(
        future: _records,
        builder: (ctx, snapshot) {
          List<Record> records = snapshot.data;
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              DateTimeRange range;
              List<Widget> toggleChildren = [];
              List<bool> isSelected = [true];
              if (event.unit != null) {
                toggleChildren.add(Text(event.unit));
                isSelected.add(false);
              }
              if (event is TimingEventDisplayModel) {
                toggleChildren.insert(0, Text("时长"));
                //得到统计信息
                range = DateTimeRange(
                    start: getDate(records[0].startTime),
                    end: getDate(records.last.startTime));
                Map<DateTime, Duration> tmp = {};
                records.forEach((record) {
                  var date = getDate(record.startTime);
                  if (tmp.containsKey(date)) {
                    tmp[date] += record.endTime.difference(record.startTime);
                  } else {
                    tmp[date] = record.endTime.difference(record.startTime);
                  }
                });
                tmp.forEach((key, value) {
                  data[key] = value.inSeconds.toDouble();
                }); //转换为数值
              } else {
                toggleChildren.insert(0, Text("次数"));

                range = DateTimeRange(
                    start: getDate(records[0].endTime),
                    end: getDate(records.last.endTime));
                //计次即可
                records.forEach((record) {
                  var date = getDate(record.endTime); //因为没有startTime
                  if (data.containsKey(date)) {
                    data[date] += 1;
                  } else {
                    data[date] = 1;
                  } //转换为数值
                });
              }
              print(isSelected);
              return Scaffold(
                  appBar: AppBar(
                    title: Text(sprintf("%s - 项目详情", [event.name])),
                  ),
                  body: ListView(scrollDirection: Axis.vertical, children: [
                    Center(
                        child: Text(
                      "统计数据",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    )),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: HeatMapCalendar(
                        dateRange: range,
                        input: data,
                      ),
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: ToggleButtons(
                            children: toggleChildren,
                            isSelected: isSelected,
                            onPressed: (int index) {
                              setState(() {
                                for (int i = 0; i < isSelected.length; i++) {
                                  print(i);
                                  if (i == index) {
                                    isSelected[i] = true;
                                  } else {
                                    isSelected[i] = false;
                                  }
                                }
                              });
                            }))
                  ]));
              break;
            default:
              return loadingScreen();
          }
        });
  }
}
