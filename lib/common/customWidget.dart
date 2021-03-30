import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/DAO/model/Unit.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fluttertoast/fluttertoast.dart';

RaisedButton myRaisedButton(Widget child, Function onPressCallBack) {
  return RaisedButton(
      color: Colors.blue,
      highlightColor: Colors.blue[700],
      colorBrightness: Brightness.dark,
      splashColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      // padding: EdgeInsets.symmetric(horizontal: 50),
      child: child,
      onPressed: onPressCallBack);
}

Widget loadingScreen() {
  return Center(
    child: Container(
      width: 50,
      height: 50,
      child: CircularProgressIndicator(),
    ),
  );
}

class EventTileButton extends StatelessWidget {
  final bool careTime;
  final bool isActive;

  EventTileButton(this.careTime, this.isActive);

  @override
  Widget build(BuildContext context) {
    if (!careTime)
      return myRaisedButton(Text("+记录"), () {});
    else if (isActive) {
      return myRaisedButton(Text("停止"), () {});
    } else {
      return myRaisedButton(Text("开始"), () {});
    }
  }
}

class BasicEventTile extends AnimatedWidget {
  final String eventName;

  BasicEventTile({Animation<Color> animation, String name})
      : eventName = name,
        super(listenable: animation);

  Widget build(BuildContext context) {
    final Animation<Color> animation = listenable;
    return Container(
        color: animation.value,
        child: Row(
          children: [
            Flexible(child: ListTile(title: Text(eventName))),
            EventTileButton(true, true)
          ],
        ));
  }
}

class AnimationEventTile extends StatefulWidget {
  final String eventName;

  AnimationEventTile(this.eventName);

  @override
  _AnimationEventTileState createState() => new _AnimationEventTileState();
}

class _AnimationEventTileState extends State<AnimationEventTile>
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
    return BasicEventTile(animation: animation, name: widget.eventName);
  }

  dispose() {
    //路由销毁时需要释放动画资源
    controller.dispose();
    super.dispose();
  }
}
