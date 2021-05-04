import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/common/util.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';

RaisedButton myRaisedButton(Widget child, void Function() onPressCallBack,
    [void Function()? onLongPressCallBack]) {
  return RaisedButton(
      color: Colors.blue,
      highlightColor: Colors.blue[700],
      colorBrightness: Brightness.dark,
      splashColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      // padding: EdgeInsets.symmetric(horizontal: 50),
      child: child,
      onPressed: onPressCallBack,
      onLongPress: onLongPressCallBack);
}

Widget eventListButton(Widget child, void Function() onPressCallBack,
    [void Function()? onLongPressCallBack]) {
  return Container(
      margin: EdgeInsets.only(right: 7),
      child: RaisedButton(
          color: Colors.blue,
          highlightColor: Colors.blue[700],
          colorBrightness: Brightness.dark,
          splashColor: Colors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          // padding: EdgeInsets.symmetric(horizontal: 50),
          child: child,
          onPressed: onPressCallBack,
          onLongPress: onLongPressCallBack));
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

Future<void> displayTextInputDialog(BuildContext context, String title,
    Function okButton, TextEditingController c) async {
  return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  // print(OKButton().enabled);
                });
              },
              controller: c,
            ),
            // decoration: InputDecoration(hintText: "如：米"),

            actions: <Widget>[
              FlatButton(
                // color: Colors.red,
                // textColor: Colors.white,
                child: Text('取消'),
                onPressed: () {
                  setState(() {
                    // listNeedUpdate = false;
                    Navigator.pop(context); //false表示不需要刷新
                  });
                },
              ),
              okButton(),
            ],
          );
        });
      });
}

void showToast(String text) {
  Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.blueAccent,
      textColor: Colors.white,
      fontSize: 16.0);
}

class EventTile1 extends StatefulWidget {
  @override
  EventTile1State createState() => new EventTile1State();
}

class EventTile1State extends State<EventTile1> {
  @override
  Widget build(BuildContext context) {
    return Card(
        // color: animation.value,
        elevation: 8,
        child: AnimatedOpacity(
            opacity: 1,
            duration: Duration(seconds: 2),
            child: Container(
                color: Colors.cyan,
                child: Row(
                  children: [
                    Flexible(
                        child: ListTile(
                            title: Text("title"), subtitle: Text("subtitle"))),
                    TextButton(onPressed: () {}, child: Text("button"))
                  ],
                ))));
  }
}

class DividerWithText extends StatelessWidget {
  final String txt;

  DividerWithText(this.txt);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      child: Row(children: [
        Expanded(
            child: Divider(
          thickness: 5,
        )),
        Text(
          txt,
          style: TextStyle(fontSize: 20),
        ),
        Expanded(
            child: Divider(
          thickness: 5,
        ))
      ]),
    );
  }
}
