import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/common/customWidget.dart';
import 'package:sprintf/sprintf.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_event_tracker/common/util.dart';
import '../DAO/base.dart';
import '../heatmap_calendar/heatMap.dart';
import 'package:intl/intl.dart';
import 'dart:collection';
import 'package:fl_chart/fl_chart.dart';

class StatisticPage extends StatefulWidget {
  @override
  _StatisticPageState createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  DateTimeRange? range;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    children.add(RangeSelector());
    if (range != null) {
      print(range);
      children.add(DisplayWidget(range!));
    }
    return NotificationListener(
        onNotification: (PageChangedNotification n) {
          setState(() {
            range = n.range;
          });
          return true;
        },
        child: ListView(children: children));
  }
}

class RangeSelector extends StatefulWidget {
  @override
  _RangeSelectorState createState() => _RangeSelectorState();
}

class _RangeSelectorState extends State<RangeSelector> {
  List<bool> isSelected = [true, false, false];
  DateTimeRange range =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());

  @override
  Widget build(BuildContext context) {
    late Duration tick;
    switch (getSelected(isSelected)) {
      case 0:
        tick = Duration(days: 1);
        break;
      case 1:
        tick = Duration(days: 7);
        break;
      case 2:
        tick = Duration(days: 30);
        break;
    }
    return Container(
        alignment: Alignment.topCenter,
        child: Column(children: [
          ToggleButtons(
              children: [Text("日"), Text("周"), Text("月")],
              isSelected: isSelected,
              onPressed: (int index) {
                if (index != getSelected(isSelected)) {
                  for (int i = 0; i < isSelected.length; i++) {
                    setState(() {
                      if (i == index) {
                        isSelected[i] = true;
                      } else {
                        isSelected[i] = false;
                      }
                    });
                  }
                }
              }),
          RangeSlider(DateTime.now(), tick)
        ]));
  }
}

class RangeSlider extends StatefulWidget {
  @override
  _RangeSliderState createState() => _RangeSliderState();
  late final DateTime current;
  late final Duration tick;

  RangeSlider(DateTime cur, Duration t) {
    current = DateTime(cur.year, cur.month, cur.day, 23, 59, 59);
    tick = t;
  }
}

class _RangeSliderState extends State<RangeSlider> {
  @override
  Widget build(BuildContext context) {
    List<Widget> pageViewChildren = [];
    List<DateTimeRange> ranges = [];
    for (int i = 100; i >= 0; i--) {
      DateTime timeR = widget.current.add(widget.tick * (-i));
      DateTime tmp = timeR.add(widget.tick * (-1));
      DateTime timeL = getDate(tmp);

      String timeLStr = DateFormat('yyyy.MM.dd').format(timeL);
      String timeRStr = DateFormat('yyyy.MM.dd').format(timeR);
      ranges.add(DateTimeRange(start: timeL, end: timeR));
      pageViewChildren.add(Center(child: Text(timeLStr + '~' + timeRStr)));
    }
    PageController _c = PageController(initialPage: 102);

    @override
    void dispose() {
      _c.dispose();
      super.dispose();
    }

    var pageView = PageView(
      controller: _c,
      onPageChanged: (page) {
        DateTimeRange range = ranges[page];
        PageChangedNotification(range: range).dispatch(context);
      },
      children: pageViewChildren,
    );
    return Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black38)),
        child: SizedBox(height: 80, width: 200, child: pageView));
  }
}

class DisplayWidget extends StatefulWidget {
  @override
  _DisplayWidgetState createState() => _DisplayWidgetState();

  late final DateTimeRange range;

  DisplayWidget(this.range);
}

class _DisplayWidgetState extends State<DisplayWidget> {
  late Future<List<Record>> _records;
  late Map<int, Event> _events = {};
  AppDatabase db = DBHandle().db;

  @override
  void initState() {
    super.initState();
    _records = db.getRecordsInRange(widget.range);
    // getEvents();
  }

  @override
  Widget build(BuildContext context) {
    getEvents();
    print("Build Start!");
    return FutureBuilder<List<Record>>(
        future: _records,
        builder: (ctx, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              List<Record> records = snapshot.data!;
              Map<int, int> eventId2Time = {}; //{eventId, 次数}
              records.forEach((record) {
                if (eventId2Time.containsKey(record.eventId)) {
                  eventId2Time[record.eventId] =
                      eventId2Time[record.eventId]! + 1;
                } else {
                  eventId2Time[record.eventId] = 1;
                }
              });
              Map<Event, int> event2Time = {};
              eventId2Time.forEach((key, value) {
                event2Time[_events[key]!] = value;
              });

              var pieChart = SizedBox(
                  height: 300,
                  width: 300,
                  child: PieChart(
                      PieChartData(sections: getSections(event2Time))));
              return pieChart;
            // return Text("OKK");
            default:
              return loadingScreen();
          }
        });
  }

  void getEvents() async {
    List<Event> l = await db.getRawEvents();
    l.forEach((element) {
      _events[element.id] = element;
    });
    print("getEvents done");
  }

  List<PieChartSectionData> getSections(Map<Event, int> data) {
    List<PieChartSectionData> res = [];
    data.forEach((event, time) {
      res.add(PieChartSectionData(title: event.name, value: time.toDouble()));
    });
    return res;
  }
}


// class MyPieChart extends StatefulWidget{
//
//
// }
//
// class _MyPieChart extends StatefulWidget{
//
//
// }