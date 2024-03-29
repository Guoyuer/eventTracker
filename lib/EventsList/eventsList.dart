import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart' hide DatePickerTheme;
// import 'package:flutter_datetime_picker/flutter_datetime_picker.dart' show DatePickerTheme;
// import 'package:drift_sqflite/drift_sqflite.dart' hide Column;
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stateProviders.dart';
import '../DAO/base.dart';
import '../common/commonWidget.dart';
import '../common/const.dart';

part 'util.dart';

class EventList extends ConsumerWidget {
  EventList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ScrollController _c = ScrollController();
    Future<List<BaseEventModel>> _events = DBHandle().db.getEventsProfile();
    _c.addListener(() {
      ref.read(eventListScrollDirProvider.notifier).update((state) => state = _c.position.userScrollDirection);
    });
    return FutureBuilder<List<BaseEventModel>>(
        future: _events,
        builder: (ctx, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              List<BaseEventModel> events = snapshot.data!;
              var list = ListView.builder(
                  // shrinkWrap: true,
                  controller: _c,
                  itemCount: events.length,
                  itemBuilder: (ctx, idx) {
                    return EventDataHolder(event: events[idx], child: EventTile());
                    // return EventTile(data[idx]['id'],data[idx]['name'], true, false);
                  });

              return list;
            default:
              return loadingScreen();
          }
        });
  }
}

class EventTileButton extends StatelessWidget {
  // final int eventId; //按钮要记住，因为操作据库的时候要用。

  @override
  Widget build(BuildContext context) {
    BaseEventModel event = EventDataHolder.of(context).event;
    EventStatus status = getEventStatus(event);
    switch (status) {
      case EventStatus.plain:
        return eventListButton(Icon(Icons.add_rounded), Text("新记录"), () {
          DateTime now = DateTime.now();
          addPlainRecord(context, now);
        }, () {
          showToast("长按 -- 手动指定时间");
          showTimePicker(
            context: context,
            // showTitleActions: true,
            // minTime: DateTime.now().add(Duration(days: -7)),
            // maxTime: DateTime.now().add(Duration(seconds: 1)),
            initialTime: TimeOfDay.now(),
            // theme: DatePickerTheme(
            //     headerColor: Colors.orange,
            //     backgroundColor: Colors.blue,
            //     itemStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            //     doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
            // onConfirm: (time) {
            //   addPlainRecord(context, time);
            // },
            // onCancel: () {
            //   showToast("用户取消");
            // },
            // currentTime: DateTime.now(),
            // locale: LocaleType.zh
          );
        });
      case EventStatus.notActive:
        return eventListButton(Icon(Icons.play_arrow_outlined), Text("开始"), () {
          DateTime now = DateTime.now();
          startTimingRecord(context, now);
        }, () {
          showToast("长按 -- 手动指定开始时间");
          showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            // showTitleActions: true,
            // minTime: DateTime.now().add(Duration(days: -7)),
            // maxTime: DateTime.now().add(Duration(seconds: 1)),
            // theme: DatePickerTheme(
            //     headerColor: Colors.orange,
            //     backgroundColor: Colors.blue,
            //     itemStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            //     doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
            // onConfirm: (time) {
            //   startTimingRecord(context, time);
            // },
            // onCancel: () {
            //   showToast("用户取消");
            // },
            // currentTime: DateTime.now(),
            // locale: LocaleType.zh
          );
        });
      case EventStatus.active:
        return eventListButton(Icon(Icons.stop_circle_outlined), Text("停止"), () {
          stopTimingRecord(context, DateTime.now());
        }, () async {
          showToast("长按 -- 手动指定停止时间");
          var db = DBHandle().db;
          DateTime startTime = await db.getEventStartTime(event.id);
          var fiveSeconds = Duration(seconds: 5);
          Duration thisDuration = DateTime.now().difference(startTime);
          if (thisDuration.compareTo(fiveSeconds) < 0) {
            showToast("开始不足5s");
          } else {
            showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              // showTitleActions: true,
              // minTime: startTime,
              // maxTime: DateTime.now().add(Duration(seconds: 5)),
              // theme: DatePickerTheme(
              //     headerColor: Colors.orange,
              //     backgroundColor: Colors.blue,
              //     itemStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              //     doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
              // onConfirm: (time) {
              //   stopTimingRecord(context, time);
              // },
              // onCancel: () {
              //   showToast("用户取消");
              // },
              // locale: LocaleType.zh
            );
          }
        });
      default:
        return eventListButton(Icon(Icons.help_outline_rounded), Text("???"), () {});
    }
  }
}

class EventDataHolder extends InheritedWidget {
  final BaseEventModel event;

  EventDataHolder({required this.event, required Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(EventDataHolder oldWidget) {
    return event.id != oldWidget.event.id;
  }

  static EventDataHolder of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EventDataHolder>()!;
  }
}

class EventTile extends StatefulWidget {
  @override
  _EventTileState createState() => new _EventTileState();
}

class _EventTileState extends State<EventTile> with SingleTickerProviderStateMixin {
  late final Animation<double> animation;
  late final AnimationController _controller;
  late final int second; //渐变时长
  initState() {
    super.initState();
    second = 1;
    _controller = new AnimationController(
        duration: Duration(seconds: second), reverseDuration: Duration(seconds: second), vsync: this)
      ..repeat(reverse: true);

    animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  Widget build(BuildContext context) {
    BaseEventModel event = EventDataHolder.of(context).event;
    Widget eventInfo;
    if (event is TimingEventModel) {
      String sumValStr;
      //TimingEvent
      var data = event;
      if (data.status == EventStatus.notActive) {
        //关闭动画
        _controller.reset();
        //inactive，显示累计时间和值(if有单位)
        String sumTimeStr = "尚未开始";
        if (data.sumDuration.inMicroseconds != 0) {
          sumTimeStr = formatDuration(data.sumDuration);
          sumTimeStr = "共进行$sumTimeStr";
        }

        String? unit = data.unit;
        if (data.unit != null && data.sumVal != 0) {
          int val = data.sumVal!.toInt();
          sumValStr = "累计：$val $unit";
          eventInfo = Column(children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text(sumTimeStr, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(sumValStr, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          ]);
        } else {
          eventInfo = Align(
              alignment: Alignment.centerLeft,
              child: Text(
                sumTimeStr,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ));
        }
      } else {
        eventInfo = LapsedTimeStr(startTime: data.startTime!);
      }
    } else {
      _controller.reset();
      //PlainEvent
      var data = (event as PlainEventModel);
      int time = data.time;

      String sumTimeStr;
      if (time == 0) {
        sumTimeStr = "尚未开始";
      } else {
        sumTimeStr = "已进行 $time 次";
      }
      String? unit = data.unit;
      if (data.unit != null && data.sumVal != 0) {
        int val = data.sumVal!.toInt();
        String sumValStr = "累计：$val $unit";
        eventInfo = Column(children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text(sumTimeStr, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(sumValStr, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
        ]);
      } else {
        eventInfo = Align(
            alignment: Alignment.centerLeft,
            child: Text(sumTimeStr, style: TextStyle(color: Colors.grey[600], fontSize: 14)));
      }
    }
    return Card(
        // color: animation.value,
        elevation: 8,
        child: Stack(
          children: [
            Positioned.fill(
                child: FadeTransition(opacity: animation, child: Container(color: const Color(0xaabeddf5)))),
            InkWell(
              onTap: () async {
                bool? deleted = await Navigator.of(context).pushNamed("EventDetails", arguments: event) as bool?;
                if (deleted != null && deleted) ReloadEventsN().dispatch(context);
              },
              child: Container(
                  margin: EdgeInsets.only(left: 10, top: 10),
                  height: 68,
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          event.name,
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                      Expanded(
                          child: Container(
                        margin: EdgeInsets.only(left: 5),
                        child: eventInfo,
                      ))
                    ],
                  )),
            ),
            Positioned.fill(child: Container(alignment: Alignment.centerRight, child: EventTileButton())),
          ],
        ));
  }

  dispose() {
    //路由销毁时需要释放动画资源
    _controller.dispose();
    super.dispose();
  }
}

///显示流逝事件的。别的事件状态就显示静态的Text()就好了。
class LapsedTimeStr extends StatefulWidget {
  final DateTime startTime;

  LapsedTimeStr({Key? key, required this.startTime}) : super(key: key);

  @override
  _LapsedTimeStrState createState() => _LapsedTimeStrState();
}

class _LapsedTimeStrState extends State<LapsedTimeStr> {
  late String str;
  late final Timer timer;

  @override
  void initState() {
    _updateStr();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      _updateStr();
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          str,
          style: TextStyle(color: Colors.grey),
        ));
  }

  void _updateStr() {
    Duration timePassed = DateTime.now().difference(widget.startTime);
    setState(() {
      str = "已进行" + formatDuration(timePassed);
    });
  }
}
