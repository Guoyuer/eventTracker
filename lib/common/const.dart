import 'package:flutter/material.dart';

// ignore: must_be_immutable

enum EventStatus {
  plain, // 不care时间
  active, //正在进行
  paused, //暂停中，这个暂时不做，会让逻辑复杂。
  notActive, //不在进行
}

class ReloadEventsNotification extends Notification {
  ReloadEventsNotification();
}
