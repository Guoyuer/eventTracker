import 'package:flutter/material.dart';
import '../DAO/EventsProvider.dart';
import '../DAO/model/Event.dart';

/// 处理从eventEditor返回的数据，写入数据库
void writeEvent(Map<String, dynamic> res) {
  EventsDbProvider dbEvent = EventsDbProvider();
  EventModel event = EventModel(
      res['eventName'], res['eventDesc'], res['careTime'], res['unit']);
  dbEvent.insert(event).then((value) {
    print("插入成功");
  });
  print(res);
}
