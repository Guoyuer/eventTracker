import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'package:sprintf/sprintf.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_event_tracker/common/util.dart';
import '../DAO/base.dart';
import 'util.dart';
import '../heatmap_calendar/heatMap.dart';

class EventDetailsWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BaseEventDisplayModel event = ModalRoute.of(context).settings.arguments;
    return EventDetails(event: event);
  }
}

class EventDetails extends StatefulWidget {
  EventDetails({Key key, this.event}) : super(key: key);
  final BaseEventDisplayModel event;

  @override
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  Future<List<Record>> _records;
  AppDatabase db = DBHandle().db;
  List<Widget> toggleChildren = [];
  List<bool> isSelected = [true];

  @override
  void initState() {
    super.initState();
    _records = db.getAllRecords(widget.event.id);
    if (widget.event is TimingEventDisplayModel) {
      toggleChildren.add(Text("时长"));
    } else {
      toggleChildren.add(Text("次数"));
    }
    if (widget.event.unit != null) {
      toggleChildren.add(Text(widget.event.unit));
      isSelected.add(false);
    }
  }


  @override
  Widget build(BuildContext context) {
    Map<DateTime, double> data = {};
    return FutureBuilder<List<Record>>(
        future: _records,
        builder: (ctx, snapshot) {
          Widget scaffoldBody;
          List<Record> records = snapshot.data;
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              DateTimeRange range;
              if (widget.event is TimingEventDisplayModel) {
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
              scaffoldBody =
                  ListView(scrollDirection: Axis.vertical, children: [
                Center(
                    child: Text(
                  "统计数据",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                          for (int i = 0; i < isSelected.length; i++) {
                            setState(() {
                              if (i == index) {
                                isSelected[i] = true;
                              } else {
                                isSelected[i] = false;
                              }
                            });
                          }
                        }))
              ]);
              break;
            default:
              scaffoldBody = loadingScreen();
          }
          return Scaffold(
              appBar: AppBar(
                title: Text(sprintf("%s - 项目详情", [widget.event.name])),
              ),
              body: scaffoldBody);
        });
  }
}
