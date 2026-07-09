import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

ElevatedButton myRaisedButton(Widget child, void Function() onPressCallBack,
    [void Function()? onLongPressCallBack]) {
  return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(horizontal: 50),
      ),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            padding: EdgeInsets.symmetric(horizontal: 50),
          ),
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
  BuildContext context,
  String title,
  Future<bool> Function(String value) onSubmit,
) async {
  final controller = TextEditingController();
  try {
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(controller: controller),
            actions: <Widget>[
              TextButton(
                child: Text('取消'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, __) {
                  return TextButton(
                    child: Text('添加'),
                    onPressed: value.text.isEmpty
                        ? null
                        : () async {
                            final shouldClose = await onSubmit(value.text);
                            if (shouldClose && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                  );
                },
              ),
            ],
          );
        });
  } finally {
    controller.dispose();
  }
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
