import 'package:flutter/cupertino.dart';

class RecordModel {
  int id; //是events表里lastRecord指针指向的
  int eventId; //与events表的关联，统计某事件时需要使用
  String startTime; //日期+时间，精确到秒。直接human-readable
  String endTime; // 对于不关心时间的事件，startTime置0，时间写在endTime。
  // 对于careTime的如果startTime非空且endTime为空，则还没有结束。对于不careTime的，endTime肯定不为空，否则不会写入。
  double value; //附加单位的值
  int duration; // 持续的秒数
  // 如果统计次数，则直接count不为空的endTime。如果统计duration，则遍历duration进行相加。

  RecordModel(int eventId,
      {int id, DateTime startTime, DateTime endTime, double value}) {
    this.id = id;
    this.eventId = eventId;
    this.startTime = startTime?.toString();
    if (startTime != null) {
      this.duration = endTime?.difference(startTime)?.inSeconds;
    }
    this.endTime = endTime?.toString();
    this.value = value;
  }
}
