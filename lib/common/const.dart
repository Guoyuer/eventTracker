import 'package:flutter/material.dart';

// ignore: must_be_immutable

enum EventStatus {
  plain, // 不care时间
  active, //正在进行
  paused, //暂停中，这个暂时不做，会让逻辑复杂。
  notActive, //不在进行
}

class PageChangedNotification extends Notification {
  final DateTimeRange range;

  PageChangedNotification({required this.range});
}

class ReloadEventsNotification extends Notification {
  ReloadEventsNotification();
}

class MonthTouchedNotification extends Notification {
  final DateTime month;

  MonthTouchedNotification({required this.month});
}

class DayTouchedNotification extends Notification {
  final DateTime day;

  DayTouchedNotification({required this.day});
}
var chartTitleStyle = TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold);
const Map<int, Color> heatmapColorMap = {
  -1: Color.fromARGB(0, 255, 255, 255), //透明，用于占位
  0: Color.fromARGB(255, 235, 237, 240),
  1: Color.fromARGB(255, 155, 233, 168),
  2: Color.fromARGB(255, 64, 196, 99),
  3: Color.fromARGB(255, 48, 161, 78),
  4: Color.fromARGB(255, 33, 110, 57),
};

List<Color> gradientColors = [
  Color.fromARGB(255, 235, 237, 240),
  Color.fromARGB(255, 155, 233, 168),
  Color.fromARGB(255, 64, 196, 99),
  Color.fromARGB(255, 48, 161, 78),
  Color.fromARGB(255, 33, 110, 57),
];
