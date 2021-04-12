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
        return myRaisedButton(Text("+记录"), () {
          addPlainRecord(context);
        });
        break;
      case EventStatus.notActive:
        //TODO 长按停止可以手动输入开始时间
        return myRaisedButton(Text("开始"), () {
          startTimingRecord(context);
        });
      case EventStatus.active:
        //TODO 长按停止可以手动输入停止时间（校验是否早于开始时间？）
        return myRaisedButton(Text("停止"), () {
          stopTimingRecord(context);
        });
      default:
        return myRaisedButton(Text("???"), () {});
    }
  }
}

// status: 0(careTime = false) 1(careTime && !isActive) 2(careTime && isActive);
class EventTileBuildingBlock extends AnimatedWidget {
  EventTileBuildingBlock({
    Animation<Color> animation,
  }) : super(listenable: animation);

  Widget build(BuildContext context) {
    final Animation<Color> animation = listenable;
    Color color;
    BaseEventDisplayModel event = EventDataHolder.of(context).event;
    if ((event is TimingEventDisplayModel) && event.isActive) {
      color = animation.value;
    } else {
      color = null;
    }

    return Card(
        // color: animation.value,
        color: color,
        elevation: 8,
        child: Row(
          children: [
            Flexible(
                child: ListTile(
                    title: Text(event.name),
                    subtitle: Text(getSubtitleText(event)),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed("EventDetails", arguments: event.id);
                    })),
            EventTileButton()
          ],
        ));
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
  Animation<Color> animation;
  AnimationController controller;
  int time; //渐变时长
  initState() {
    super.initState();
    time = 5;
    controller = new AnimationController(
        duration: Duration(seconds: time),
        reverseDuration: Duration(seconds: time),
        vsync: this);

    animation =
        ColorTween(begin: Color(0x6200EE), end: Colors.cyan).animate(controller);
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        controller.forward();
      }
    });
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return EventTileBuildingBlock(animation: animation);
  }

  dispose() {
    //路由销毁时需要释放动画资源
    controller.dispose();
    super.dispose();
  }
}
