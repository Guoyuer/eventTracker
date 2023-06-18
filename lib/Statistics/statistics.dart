import 'dart:collection';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/commonWidget.dart';
import 'package:flutter_event_tracker/common/util.dart';
import 'package:intl/intl.dart';
import 'package:random_color/random_color.dart';

import '../DAO/base.dart';

class StatisticPage extends StatefulWidget {
  @override
  _StatisticPageState createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  DateTimeRange range = DateTimeRange(start: getDate(DateTime.now().add(Duration(days: -7))), end: DateTime.now());

  //TODO rangePicker最早时间的限制
  @override
  Widget build(BuildContext context) {
    String timeLStr = DateFormat('yyyy.MM.dd').format(range.start);
    String timeRStr = DateFormat('yyyy.MM.dd').format(range.end);
    return ListView(children: [
      Card(
          elevation: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  margin: EdgeInsets.only(left: 10),
                  height: 40,
                  child: Center(
                      child: Text(
                    timeLStr + ' 至 ' + timeRStr,
                    style: TextStyle(fontSize: 20),
                  ))),
              Container(
                  margin: EdgeInsets.only(right: 10),
                  child: myRaisedButton(Text("更改区间"), () async {
                    DateTimeRange? tmp = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now().add(Duration(days: -100)),
                        lastDate: DateTime.now());
                    if (tmp != null) {
                      setState(() {
                        range = DateTimeRange(start: tmp.start, end: tmp.end.add(Duration(days: 1)));
                      });
                    }
                  }))
            ],
          )),
      Charts(range)
    ]);
  }
}

class Charts extends StatefulWidget {
  @override
  _ChartsState createState() => _ChartsState();

  late final DateTimeRange range;

  Charts(this.range);
}

class _ChartsState extends State<Charts> {
  // late Future<List<Record>> _records;
  AppDatabase db = DBHandle().db;
  RandomColor _randomColor = RandomColor();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 10; i++) {
      colors.add(_randomColor.randomColor(colorBrightness: ColorBrightness.light));
    }
  }

  List<Color> colors = [];

  @override
  Widget build(BuildContext context) {
    Future<List<Record>> _records = db.getRecordsInRange(widget.range);
    Future<Map<int, Event>> _eventsMap = db.getEventsMap();
    return FutureBuilder(
        future: Future.wait<Object>([_records, _eventsMap]),
        builder: (ctx, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              List<Object> tmp = snapshot.data!;
              List<Record> records = tmp[0] as List<Record>;
              Map<int, Event> eventsMap = tmp[1] as Map<int, Event>;

              if (records.isEmpty || eventsMap.isEmpty) return Card(elevation: 10, child: Text("暂无记录"));

              while (colors.length < eventsMap.length) {
                colors.add(_randomColor.randomColor(colorBrightness: ColorBrightness.light));
              }
              Map<String, Color> name2color = {}; //项目名称和颜色要统一
              int i = 0;
              eventsMap.forEach((key, value) {
                name2color[value.name] = colors[i];
                i++;
              });
              Map<int, int> eventId2Time = {}; //{eventId, 次数}

              records.forEach((record) {
                if (eventId2Time.containsKey(record.eventId)) {
                  eventId2Time[record.eventId] = eventId2Time[record.eventId]! + 1;
                } else {
                  eventId2Time[record.eventId] = 1;
                }
              });

              Map<Event, int> event2Time = {};
              eventId2Time.forEach((key, value) {
                event2Time[eventsMap[key]!] = value;
              });
              var pieChart = getPieChart(event2Time, name2color);
              Map<String, List<DateTime>> eventName2RecordEnds = {};
              records.forEach((record) {
                String eventName = eventsMap[record.eventId]!.name;
                if (eventName2RecordEnds.containsKey(eventName)) {
                  eventName2RecordEnds[eventName]!.add(record.endTime!);
                } else {
                  eventName2RecordEnds[eventName] = [record.endTime!];
                }
              });

              var timeSlotsBar = getTimeSlotsBar(eventName2RecordEnds, name2color);
              List<Widget> charts = [pieChart, timeSlotsBar];
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

  List<PieChartSectionData> getSections(Map<Event, int> data, Map<String, Color> name2color) {
    List<PieChartSectionData> res = [];
    data.forEach((event, time) {
      res.add(PieChartSectionData(
          color: name2color[event.name],
          radius: 80,
          titleStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          title: event.name + " " + time.toString(),
          value: time.toDouble()));
    });
    return res;
  }

  Widget getTimeSlotsBar(Map<String, List<DateTime>> eventName2RecordEnds, Map<String, Color> name2color) {
    List<BarChartGroupData> bars = [];
    LinkedHashMap<String, List<double>> eventName2SlotNum = LinkedHashMap<String, List<double>>();
    Orientation orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      eventName2RecordEnds.forEach((eventName, listOfEnds) {
        List<double> slots = getTimeSlotNum(listOfEnds);
        List<double> processedData = [];
        for (int i = 0; i < 12; i++) {
          double val = slots[i * 2] + slots[i * 2 + 1];
          processedData.add(val);
        }
        eventName2SlotNum[eventName] = processedData;
      });
    } else {
      eventName2RecordEnds.forEach((eventName, listOfEnds) {
        List<double> slots = getTimeSlotNum(listOfEnds);
        eventName2SlotNum[eventName] = slots;
      });
    }

    int numOfX;
    if (orientation == Orientation.portrait) {
      numOfX = 12;
    } else {
      numOfX = 24;
    }
    List<List<BarChartRodStackItem>> stacks = List.generate(numOfX, (i) => [], growable: false);
    List<double> lastY = List.filled(numOfX, 0);
    eventName2SlotNum.forEach((eventName, slots) {
      //每个项目都铺一层，颜色一样。
      for (int j = 0; j < numOfX; j++) {
        stacks[j].add(BarChartRodStackItem(lastY[j], lastY[j] + slots[j], name2color[eventName]!));
        lastY[j] += slots[j];
      }
    });
    for (int i = 0; i < numOfX; i++) {
      int x;
      if (orientation == Orientation.portrait)
        x = i * 2;
      else
        x = i;
      bars.add(BarChartGroupData(x: x, barRods: [
        BarChartRodData(
            borderRadius: BorderRadius.all(Radius.elliptical(5, 5)), rodStackItems: stacks[i], toY: lastY[i], width: 15)
      ]));
    }
    double maxY = 0;
    for (int i = 0; i < numOfX; i++) {
      if (lastY[i] > maxY) maxY = lastY[i];
    }

    var barChart = Container(
        margin: EdgeInsets.only(left: 5, top: 10, right: 10),
        child: Column(children: [
          Text(
            "时段活跃度",
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          SizedBox(
              height: 300,
              // width: 350,
              child: BarChart(BarChartData(
                  barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                                rod.toY.toInt().toString(), TextStyle(color: Colors.white, fontSize: 18));
                          })),
                  groupsSpace: 18,
                  // alignment: BarChartAlignment.start,
                  titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double val, TitleMeta meta) {
                                return Text(val.round().toString());
                              },
                              interval: maxY / 6))),
                  borderData: FlBorderData(show: false),
                  barGroups: bars)))
        ]));
    return barChart;
  }

  Widget getPieChart(Map<Event, int> event2Time, Map<String, Color> name2color) {
    int tot = 0;
    for (int i in event2Time.values) {
      tot += i;
    }
    var pieChart = SizedBox(
        height: 300,
        // width: 300,
        child: Stack(
          children: [
            PieChart(
                PieChartData(centerSpaceRadius: 70, sectionsSpace: 5, sections: getSections(event2Time, name2color))),
            Center(
                child: Container(
              child: Center(
                  child: Text(
                "共 $tot 次",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )),
              width: 110,
              height: 110,
              decoration: new BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ))
          ],
        ));
    return Column(
      children: [
        Text(
          "次数统计",
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 10),
        pieChart,
        SizedBox(height: 30)
      ],
    );
  }
}

List<double> getTimeSlotNum(List<DateTime> ends) {
  //结束时间+1就可以了
  List<double> data = List.filled(24, 0); //次数、时长（分钟）、物理量
  ends.forEach((end) {
    data[end.hour] += 1;
  });
  // List<double> processedData = [];
  // for (int i = 0; i < 12; i++) {
  //   double val = data[i * 2].toDouble() + data[i * 2 + 1];
  //   processedData.add(val);
  // }
  return data;
}
