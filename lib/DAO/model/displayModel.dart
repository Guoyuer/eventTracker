part of '../base.dart';

class BaseEventDisplayModel {
  int id; // 事件id
  String name; // 事件名称
  String unit; // 事件单位（optional） 若有单位，则val有值，需要显示总量
  String description;
  int lastRecordId;

  BaseEventDisplayModel(this.id, this.name,
      [this.unit, this.description, this.lastRecordId]);
}

class PlainEventDisplayModel extends BaseEventDisplayModel {
  int time; // 事件次数
  double sumVal; // 总量

  EventStatus get status => EventStatus.plain;

  PlainEventDisplayModel(int id, String name, String unit, this.time,
      [this.sumVal, String description, int lastRecordId])
      : super(id, name, unit, description, lastRecordId);
}

class TimingEventDisplayModel extends BaseEventDisplayModel {
  bool isActive;
  DateTime startTime; //本次开始时间，用于计算
  Duration sumTime; // 总持续时间
  double sumVal; // 总量
  EventStatus get status {
    if (isActive)
      return EventStatus.active;
    else
      return EventStatus.notActive;
  }

  //Active时就没必要获取总时间了
  TimingEventDisplayModel(
      int id, String name, String unit, this.isActive, this.sumTime,
      [this.startTime, this.sumVal, String description, int lastRecordId])
      : super(id, name, unit, description, lastRecordId);
}
