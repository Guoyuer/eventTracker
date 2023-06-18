import 'package:flutter/material.dart';
import 'package:event_tracker/DAO/base.dart';
import 'package:fluttertoast/fluttertoast.dart';

ElevatedButton myRaisedButton(Widget child, void Function() onPressCallBack, [void Function()? onLongPressCallBack]) {
  return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 50),
      ),
      // highlightColor: Colors.blue[700],
      // colorBrightness: Brightness.dark,
      child: child,
      onPressed: onPressCallBack,
      onLongPress: onLongPressCallBack);
}

Widget eventListButton(Icon icon, Widget label, void Function() onPressCallBack,
    [void Function()? onLongPressCallBack]) {
  return Container(
      margin: EdgeInsets.only(right: 7),
      child: ElevatedButton.icon(
          icon: icon,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            padding: EdgeInsets.symmetric(horizontal: 50),
          ),
          // highlightColor: Colors.blue[700],
          // colorBrightness: Brightness.dark,
          // splashColor: Colors.grey,
          label: label,
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

Future<void> displayTextInputDialog(
    BuildContext context, String title, Function okButton, TextEditingController c) async {
  return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              onChanged: (value) {
                setState(() {});
              },
              controller: c,
            ),
            // decoration: InputDecoration(hintText: "如：米"),

            actions: <Widget>[
              TextButton(
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

class DescEditable extends StatefulWidget {
  // final String initText;
  final int eventId;

  DescEditable(this.eventId);

  @override
  _EditableTextState createState() => _EditableTextState();
}

class _EditableTextState extends State<DescEditable> {
  bool _isEditingText = false;
  late TextEditingController _c;
  AppDatabase db = DBHandle().db;
  late Future<String?> _desc;
  late String desc;

  @override
  void initState() {
    super.initState();
    _desc = db.getEventDesc(widget.eventId);
    _c = TextEditingController();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditingText) {
      _c.text = desc;
      return Center(
        child: TextField(
          textAlign: TextAlign.center,
          onSubmitted: (newValue) {
            setState(() {
              // initialText = newValue;
              desc = newValue;
              db.updateEventDescription(widget.eventId, newValue);
              _isEditingText = false;
            });
          },
          autofocus: true,
          controller: _c,
        ),
      );
    } else {
      _desc = db.getEventDesc(widget.eventId);
      return InkWell(
          onTap: () {
            setState(() {
              _isEditingText = true;
            });
          },
          child: FutureBuilder<String?>(
              future: _desc,
              builder: (ctx, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.done:
                    String? tmp = snapshot.data;
                    if (tmp == null || tmp.isEmpty) {
                      desc = "无描述";
                    } else {
                      desc = tmp;
                    }
                    var style;
                    if (desc == "无描述") {
                      style = TextStyle(
                        color: Colors.black38,
                        fontSize: 18.0,
                      );
                    } else {
                      style = TextStyle(
                        fontSize: 18.0,
                      );
                    }
                    return Text(desc, style: style);
                  default:
                    return Text("加载中");
                }
              }));
    }
  }
}
