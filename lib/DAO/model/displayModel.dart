part of '../base.dart';

class BaseEventModel {
  int id; // 事件id
  String name; // 事件名称
  String? unit; // 事件单位（optional） 若有单位，则val有值，需要显示总量
  String? description;
  int? lastRecordId;

  BaseEventModel(this.id, this.name, [this.unit, this.description, this.lastRecordId]);
}

class PlainEventModel extends BaseEventModel {
  int time; // 事件次数
  double? sumVal; // 总量

  // EventStatus get status => EventStatus.plain;

  PlainEventModel(int id, String name, String? unit, this.time, [this.sumVal, String? description, int? lastRecordId])
      : super(id, name, unit, description, lastRecordId);
}

class TimingEventModel extends BaseEventModel {
  EventStatus status;
  DateTime? startTime; //本次开始时间，用于计算
  Duration sumDuration; // 总持续时间
  double? sumVal; // 总量

  //Active时就没必要获取总时间了
  TimingEventModel(int id, String name, String? unit, this.status, this.sumDuration,
      [this.startTime, this.sumVal, String? description, int? lastRecordId])
      : super(id, name, unit, description, lastRecordId);
}
