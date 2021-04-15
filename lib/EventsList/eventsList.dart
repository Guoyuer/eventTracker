import 'dart:async';

import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:moor_flutter/moor_flutter.dart';
import '../common/const.dart';
import '../common/util.dart';
import 'package:fluttertoast/fluttertoast.dart';

// import 'package:flutter_event_tracker/common/customWidget.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../common/customWidget.dart';
import '../DAO/base.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:duration/duration.dart';

part 'util.dart';

class EventList extends StatefulWidget {
  EventList({Key key}) : super(key: key);

  @override
  _EventListState createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  // EventsDbProvider db = EventsDbProvider();
  Future<List<BaseEventDisplayModel>> _events;
  String a;

  @override
  void initState() {
    super.initState();
    _events = DBHandle().db.getEventsProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BaseEventDisplayModel>>(
        future: _events,
        builder: (ctx, snapshot) {
          List<BaseEventDisplayModel> events = snapshot.data;
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (ctx, idx) {
                    return EventDataHolder(
                        event: events[idx], child: EventTile());
                    // return EventTile(data[idx]['id'],data[idx]['name'], true, false);
                  });
              break;
            default:
              return loadingScreen();
          }
        });
  }
}

class EventTileButton extends StatelessWidget {
  // final int eventId; //按钮要记住，因为操作数据库的时候要用。

  @override
  Widget build(BuildContext context) {
    BaseEventDisplayModel event = EventDataHolder.of(context).event;
    EventStatus status = getEventStatus(event);
    switch (status) {
      case EventStatus.plain:
        return eventListButton(Text("新记录"), () {
          addPlainRecord(context);
        });
        break;
      case EventStatus.notActive:
        //TODO 长按停止可以手动输入开始时间
        return eventListButton(Text("开始"), () {
          startTimingRecord(context);
        });
      case EventStatus.active:
        //TODO 长按停止可以手动输入停止时间（校验是否早于开始时间？）
        return eventListButton(Text("停止"), () {
          stopTimingRecord(context);
        });
      default:
        return eventListButton(Text("???"), () {});
    }
  }
}


class EventDataHolder extends InheritedWidget {
  final BaseEventDisplayModel event;

  EventDataHolder({this.event, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(EventDataHolder oldWidget) {
    return event.id != oldWidget.event.id;
  }

  static EventDataHolder of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EventDataHolder>();
  }
}

class EventTile extends StatefulWidget {
  @override
  _EventTileState createState() => new _EventTileState();
}

class _EventTileState extends State<EventTile>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController _controller;
  int time; //渐变时长
  initState() {
    super.initState();
    time = 1;
    _controller = new AnimationController(
        duration: Duration(seconds: time),
        reverseDuration: Duration(seconds: time),
        vsync: this)
      ..repeat(reverse: true);

    animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  Widget build(BuildContext context) {
    BaseEventDisplayModel event = EventDataHolder.of(context).event;
    Widget subTitle;
    if (event is TimingEventDisplayModel) {
      String text;
      //TimingEvent
      var data = event;
      if (!data.isActive) {
        //关闭动画
        _controller.reset();
        //inactive，显示累计时间和值(if有单位)
        String sumTimeStr =
            prettyDuration(data.sumTime, locale: ChineseDurationLocale());
        text = "共进行 $sumTimeStr";

        String unit = data.unit;
        if (data.unit != null && data.sumVal != 0) {
          int val = data.sumVal.toInt();
          text += " | 累计：$val $unit";
        }

        subTitle = Text(text);
      } else {
        subTitle = LapsedTimeStr(startTime: data.startTime);
      }
    } else {
      _controller.reset();
      //PlainEvent
      var data = (event as PlainEventDisplayModel);
      int time = data.time;
      String text = "已进行 $time 次";
      String unit = data.unit;
      if (data.unit != null && data.sumVal != 0) {
        int val = data.sumVal.toInt();
        text += " | 累计：$val $unit";
      }
      subTitle = Text(text);
    }
    return Card(
        // color: animation.value,
        elevation: 8,
        child: Stack(
          children: [
            Positioned.fill(
                child: FadeTransition(
                    opacity: animation,
                    child: Container(color: const Color(0xaabeddf5)))),
            ListTile(
                title: Text(event.name),
                subtitle: subTitle,
                onTap: () {
                  Navigator.of(context)
                      .pushNamed("EventDetails", arguments: event);
                }),
            Positioned.fill(
                child: Container(
                    alignment: Alignment.centerRight,
                    child: EventTileButton())),
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

  LapsedTimeStr({Key key, this.startTime}) : super(key: key);

  @override
  _LapsedTimeStrState createState() => _LapsedTimeStrState();
}

class _LapsedTimeStrState extends State<LapsedTimeStr> {
  String str;
  Timer timer;

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
    return Text(str);
  }

  void _updateStr() {
    Duration timePassed = DateTime.now().difference(widget.startTime);
    setState(() {
      str =
          "已进行 " + prettyDuration(timePassed, locale: ChineseDurationLocale());
    });
  }
}
