import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../DAO/base.dart';

///生成每日总时长的统计数据
List<int> getTimeSlotSumTime(List<DateTimeRange> ranges) {
  List<int> data = List.filled(24, 0); //次数、时长（分钟）、物理量

  ranges.forEach((range) {
    DateTime start = range.start;
    DateTime end = range.end;
    assert(start.compareTo(end) < 0);
    if (start.day == end.day && start.hour == end.hour) {
      //起点终点在同一小时内的
      data[start.hour] += end.difference(start).inMinutes;
    } else {
      //起点终点不在同一小时内
      DateTime left = DateTime(start.year, start.month, start.day, start.hour)
          .add(Duration(hours: 1)); //舍掉minutes seconds后+1h

      data[start.hour] += left.difference(start).inMinutes;

      DateTime right =
          DateTime(end.year, end.month, end.day, end.hour); //舍掉minutes seconds
      if (end.hour == left.hour) {
        data[left.hour] += end.difference(left).inMinutes; //整个跨度不足一个小时
      } else {
        //整个跨度大于一个小时
        data[right.hour] += end.difference(right).inMinutes;
        //补上中间的
        DateTime i = left;
        while (i.compareTo(right) < 0) {
          data[i.hour] += Duration(hours: 1).inMinutes;
          i = i.add(Duration(hours: 1));
        }
      }
    }
  });
  return data;
}

List<int> getTimeSlotSumVal(List<Record> records) {
  //直接按照结束时间加就好了
  List<double> data = List.filled(24, 0); //次数、时长（分钟）、物理量

  records.forEach((record) {
    DateTime end = record.endTime!;
    data[end.hour] += record.value!;
  });

  List<int> res = [];
  data.forEach((element) {
    res.add(element.toInt());
  });
  return res;
}

List<int> getTimeSlotSumNum(List<Record> records) {
  //结束时间+1就可以了
  List<int> data = List.filled(24, 0); //次数、时长（分钟）、物理量
  records.forEach((record) {
    DateTime end = record.endTime!;
    data[end.hour] += 1;
  });
  return data;
}
