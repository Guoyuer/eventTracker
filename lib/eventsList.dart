import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/DAO/model/Event.dart';
import 'package:flutter_event_tracker/DAO/model/Record.dart';
import 'common/const.dart';
import 'common/util.dart';
import 'DAO/RecordsProvider.dart';
import 'package:fluttertoast/fluttertoast.dart';

// import 'package:flutter_event_tracker/common/customWidget.dart';
import 'DAO/EventsProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/DAO/model/Unit.dart';
import 'package:sqflite/sqflite.dart';
import 'DAO/UnitsProvider.dart';
import 'common/customWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EventList extends StatefulWidget {
  EventList({Key key}) : super(key: key);

  @override
  _EventListState createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  EventsDbProvider db = EventsDbProvider();
  Future<List<EventModelDisplay>> _events;
  String a;

  @override
  void initState() {
    super.initState();
    _events = db.getEventsProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventModelDisplay>>(
        future: _events,
        builder: (ctx, snapshot) {
          List<EventModelDisplay> events = snapshot.data;
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

void startRecord(BuildContext context) {
  int eventId = EventDataHolder.of(context).event.id;
  var record = RecordModel(eventId, startTime: DateTime.now());
  RecordsUtils.writeRecord(record)
      .then((_) => ReloadEventsNotification().dispatch(context));
}

void stopRecord(BuildContext context) {
  int eventId = EventDataHolder.of(context).event.id;
  RecordsUtils.stopRecord(eventId, context)
      .then((_) => ReloadEventsNotification().dispatch(context));
}

class EventTileButton extends StatelessWidget {
  // final int eventId; //按钮要记住，因为操作数据库的时候要用。

  @override
  Widget build(BuildContext context) {
    // int eventId = EventDataHolder.of(context).event.id;
    bool isActive = EventDataHolder.of(context).event.isActive;
    bool careTime = EventDataHolder.of(context).event.careTime;
    EventStatus status = getStatus(careTime, isActive);
    switch (status) {
      case EventStatus.none:
        return myRaisedButton(Text("+记录"), () {});
        break;
      case EventStatus.notActive:
        return myRaisedButton(Text("开始"), () {
          startRecord(context);
        });
      case EventStatus.active:
        return myRaisedButton(Text("停止"), () {
          stopRecord(context);
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
    bool isActive = EventDataHolder.of(context).event.isActive;
    bool careTime = EventDataHolder.of(context).event.careTime;
    EventStatus status = getStatus(careTime, isActive);

    switch (status) {
      case EventStatus.active:
        color = animation.value;
        break;
      default:
        color = null;
    }
    return Container(
        // color: animation.value,
        color: color,
        child: Row(
          children: [
            Flexible(
                child: ListTile(
                    title: Text(EventDataHolder.of(context).event.name),
                    onTap: () {
                      Navigator.of(context).pushNamed("EventDetails",
                          arguments: EventDataHolder.of(context).event.id);
                    })),
            EventTileButton()
          ],
        ));
  }
}

class EventDataHolder extends InheritedWidget {
  final EventModelDisplay event;

  EventDataHolder({this.event, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(EventDataHolder oldWidget) {
    return event.isActive != oldWidget.event.isActive;
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
    time = 1;
    controller = new AnimationController(
        duration: Duration(seconds: time),
        reverseDuration: Duration(seconds: time),
        vsync: this);

    animation =
        ColorTween(begin: Colors.white, end: Colors.orange).animate(controller);
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
