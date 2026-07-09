import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:event_tracker/analytics/statistics_analytics.dart';
import 'package:event_tracker/common/commonWidget.dart';
import 'package:event_tracker/common/util.dart';
import 'package:intl/intl.dart';
import 'package:random_color/random_color.dart';

import '../persistence/statistics_repository.dart';

class StatisticPage extends StatefulWidget {
  @override
  _StatisticPageState createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  DateTimeRange range = DateTimeRange(
      start: getDate(DateTime.now().add(Duration(days: -7))),
      end: DateTime.now());

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
                        range = DateTimeRange(
                            start: tmp.start,
                            end: tmp.end.add(Duration(days: 1)));
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
  final StatisticsRepository _repository = statisticsRepository();
  RandomColor _randomColor = RandomColor();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 10; i++) {
      colors.add(
          _randomColor.randomColor(colorBrightness: ColorBrightness.light));
    }
  }

  List<Color> colors = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StatisticsData>(
        future: _repository.getStatisticsData(widget.range),
        builder: (ctx, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Card(elevation: 10, child: Text("加载统计失败"));
              }
              final statisticsData = snapshot.data!;
              final records = statisticsData.records;
              final eventsMap = statisticsData.activitiesById;

              if (records.isEmpty || eventsMap.isEmpty)
                return Card(elevation: 10, child: Text("暂无记录"));

              while (colors.length < eventsMap.length) {
                colors.add(_randomColor.randomColor(
                    colorBrightness: ColorBrightness.light));
              }
              Map<String, Color> name2color = {};
              int i = 0;
              eventsMap.forEach((key, value) {
                name2color[value.name] = colors[i];
                i++;
              });
              final summary = buildStatisticsSummary(
                records: records,
                eventsById: eventsMap,
              );

              var timeSlotsBar = getTimeSlotsBar(
                  summary.hourlyCountsByActivityName, name2color);
              List<Widget> charts = [
                getPieChart(summary, name2color),
                timeSlotsBar
              ];
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

  List<PieChartSectionData> getSections(
      StatisticsSummary summary, Map<String, Color> name2color) {
    List<PieChartSectionData> res = [];
    for (final activityCount in summary.activityCounts) {
      final event = activityCount.activity;
      final time = activityCount.count;
      res.add(PieChartSectionData(
          color: name2color[event.name],
          radius: 80,
          titleStyle: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          title: event.name + " " + time.toString(),
          value: time.toDouble()));
    }
    return res;
  }

  Widget getTimeSlotsBar(Map<String, List<double>> hourlyCountsByActivityName,
      Map<String, Color> name2color) {
    List<BarChartGroupData> bars = [];
    Map<String, List<double>> eventName2SlotNum = {};
    Orientation orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      hourlyCountsByActivityName.forEach((eventName, slots) {
        eventName2SlotNum[eventName] =
            combineStatisticsAdjacentHourSlots(slots);
      });
    } else {
      hourlyCountsByActivityName.forEach((eventName, slots) {
        eventName2SlotNum[eventName] = slots;
      });
    }

    int numOfX;
    if (orientation == Orientation.portrait) {
      numOfX = 12;
    } else {
      numOfX = 24;
    }
    List<List<BarChartRodStackItem>> stacks =
        List.generate(numOfX, (i) => [], growable: false);
    List<double> lastY = List.filled(numOfX, 0);
    eventName2SlotNum.forEach((eventName, slots) {
      for (int j = 0; j < numOfX; j++) {
        stacks[j].add(BarChartRodStackItem(
            lastY[j], lastY[j] + slots[j], name2color[eventName]!));
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
            borderRadius: BorderRadius.all(Radius.elliptical(5, 5)),
            rodStackItems: stacks[i],
            toY: lastY[i],
            width: 15)
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
              child: BarChart(BarChartData(
                  barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(rod.toY.toInt().toString(),
                                TextStyle(color: Colors.white, fontSize: 18));
                          })),
                  groupsSpace: 18,
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

  Widget getPieChart(StatisticsSummary summary, Map<String, Color> name2color) {
    var pieChart = SizedBox(
        height: 300,
        child: Stack(
          children: [
            PieChart(PieChartData(
                centerSpaceRadius: 70,
                sectionsSpace: 5,
                sections: getSections(summary, name2color))),
            Center(
                child: Container(
              child: Center(
                  child: Text(
                "共 ${summary.totalCount} 次",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )),
              width: 110,
              height: 110,
              decoration: BoxDecoration(
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
