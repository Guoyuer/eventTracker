import 'package:flutter/material.dart';
import '../DAO/EventsProvider.dart';
import '../DAO/model/Event.dart';
import 'const.dart';
/// 处理从eventEditor返回的数据，写入数据库
void writeEvent(Map<String, dynamic> res) {
  if (res == null || res.isEmpty) return; //直接返回相当于pop时没带数据，就不写
  EventsDbProvider dbEvent = EventsDbProvider();
  EventModel event = EventModel(
      res['eventName'], res['eventDesc'], res['careTime'], res['unit']);
  dbEvent.insert(event).then((value) {
    print("插入成功");
  });
  print(res);
}

EventStatus getStatus(bool careTime, bool isActive) {
  if(!careTime) return EventStatus.none;
  else if(isActive) return EventStatus.active;
  else return EventStatus.notActive;
}