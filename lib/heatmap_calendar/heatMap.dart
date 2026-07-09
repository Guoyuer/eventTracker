import 'package:flutter/material.dart';
import 'util.dart';
import 'heatMapBuildingBlocks.dart';
import '../common/const.dart';

var nilTime = DateTime.fromMicrosecondsSinceEpoch(0);

class HeatMapSetting {
  final Map<int, Color> colorMap; //int indicates level
  final double dayTileSize;
  final double dayTileMargin;
  final double weekTileMargin;
  final double monthTileMargin;

  const HeatMapSetting(
      {this.colorMap = heatmapColorMap,
      this.dayTileSize = 15,
      this.dayTileMargin = 5,
      this.weekTileMargin = 6,
      this.monthTileMargin = 2});
}

class HeatMapDataHolder extends InheritedWidget {
  final HeatMapSetting setting;
  final Map<DateTime, int> date2level;
  final Map<DateTime, double> data; // 用于toolTip
  final DateTimeRange dateRange; //因为map无序
  final ValueChanged<DateTime>? onMonthTouched;
  final ValueChanged<DateTime>? onDayTouched;
  final String? unit;

  HeatMapDataHolder(
      {required this.setting,
      required this.data,
      required this.date2level,
      required this.dateRange,
      this.unit,
      this.onMonthTouched,
      this.onDayTouched,
      required Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(HeatMapDataHolder oldWidget) {
    return setting != oldWidget.setting;
  }

  static HeatMapDataHolder of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HeatMapDataHolder>()!;
  }
}

class HeatMapCalendar extends StatefulWidget {
  final HeatMapSetting setting;
  final Map<DateTime, double> data;
  final DateTimeRange dateRange;
  final ValueChanged<DateTime>? onMonthTouched;
  final ValueChanged<DateTime>? onDayTouched;
  final String unit; //Tooltip显示的单位
  final double maxVal;

  HeatMapCalendar(
      {Key? key,
      this.setting = const HeatMapSetting(),
      required Map<DateTime, double> input,
      required this.dateRange,
      required this.unit,
      this.onMonthTouched,
      this.onDayTouched})
      : data = _normalizeInput(input),
        maxVal = _maxInputValue(input),
        super(key: key);

  static Map<DateTime, double> _normalizeInput(Map<DateTime, double> input) {
    return {
      for (final entry in input.entries) getDate(entry.key): entry.value,
    };
  }

  static double _maxInputValue(Map<DateTime, double> input) {
    if (input.isEmpty) {
      return 0;
    }
    return input.values.reduce((maxValue, value) {
      return value > maxValue ? value : maxValue;
    });
  }

  @override
  HeatMapCalendarState createState() {
    return HeatMapCalendarState();
  }
}

class HeatMapCalendarState extends State<HeatMapCalendar> {
  @override
  Widget build(BuildContext context) {
    //把date:double转化为date:level
    List<double> threshold = [0];
    int colorNum = widget.setting.colorMap.length - 1; //还有一个是透明
    for (int i = 0; i < colorNum - 1; i++) {
      threshold.add(i * widget.maxVal / colorNum);
    }
    Map<DateTime, int> date2level = Map<DateTime, int>();
    date2level[nilTime] = -1; //用于留白
    for (DateTime i = widget.dateRange.start;
        i.compareTo(widget.dateRange.end) <= 0;
        i = i.add(Duration(days: 1))) {
      if (widget.data.containsKey(i)) {
        int level = 0;
        for (int j = 0; j < threshold.length; j++) {
          if (widget.data[i]! > threshold[j]) level = j;
        }
        date2level[i] = level;
        //可能并不是所有日期都有数据，要允许这样的留白;
      } else {
        date2level[i] = 0;
      }
    }
    return HeatMapDataHolder(
        setting: widget.setting,
        date2level: date2level,
        data: widget.data,
        dateRange: widget.dateRange,
        unit: widget.unit,
        onMonthTouched: widget.onMonthTouched,
        onDayTouched: widget.onDayTouched,
        child: Container(
          child: HeatMapDisplay(),
        ));
  }
}
