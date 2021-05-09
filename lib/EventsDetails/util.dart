import 'package:flutter/material.dart';

import '../DAO/base.dart';

///生成每日总时长的统计数据
List<double> getTimeSlotSumTime(List<DateTimeRange> ranges) {
  List<double> data = List.filled(24, 0); //次数、时长（分钟）、物理量

  ranges.forEach((range) {
    DateTime start = range.start;
    DateTime end = range.end;
    assert(start.compareTo(end) < 0);
    if (start.day == end.day && start.hour == end.hour) {
      //起点终点在同一小时内的
      data[start.hour] += end.difference(start).inSeconds;
    } else {
      //起点终点不在同一小时内
      DateTime left = DateTime(start.year, start.month, start.day, start.hour)
          .add(Duration(hours: 1)); //舍掉minutes seconds后+1h

      data[start.hour] += left.difference(start).inSeconds;

      DateTime right =
          DateTime(end.year, end.month, end.day, end.hour); //舍掉minutes seconds
      if (end.hour == left.hour) {
        data[left.hour] += end.difference(left).inSeconds; //整个跨度不足一个小时
      } else {
        //整个跨度大于一个小时
        data[right.hour] += end.difference(right).inSeconds;
        //补上中间的
        DateTime i = left;
        while (i.compareTo(right) < 0) {
          data[i.hour] += Duration(hours: 1).inSeconds;
          i = i.add(Duration(hours: 1));
        }
      }
    }
  });
  // data = data.map((e) => e / 60).toList();
  return data;
}

List<double> getTimeSlotSumVal(List<Record> records) {
  //直接按照结束时间加就好了
  List<double> res = List.filled(24, 0); //次数、时长（分钟）、物理量

  records.forEach((record) {
    DateTime end = record.endTime!;
    res[end.hour] += record.value!;
  });

  return res;
}

List<double> getTimeSlotSumNum(List<Record> records) {
  //结束时间+1就可以了
  List<double> data = List.filled(24, 0); //次数、时长（分钟）、物理量
  records.forEach((record) {
    DateTime end = record.endTime!;
    data[end.hour] += 1;
  });
  return data;
}
