import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

ElevatedButton myRaisedButton(Widget child, void Function() onPressCallBack) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      padding: EdgeInsets.symmetric(horizontal: 50),
    ),
    child: child,
    onPressed: onPressCallBack,
  );
}

Widget eventListButton(
  Icon icon,
  Widget label,
  void Function() onPressCallBack,
) {
  return Container(
    margin: EdgeInsets.only(right: 7),
    child: ElevatedButton.icon(
      icon: icon,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 50),
      ),
      label: label,
      onPressed: onPressCallBack,
    ),
  );
}

Future<void> displayTextInputDialog(
  BuildContext context, {
  required String title,
  required String cancelLabel,
  required String submitLabel,
  required Future<bool> Function(String value) onSubmit,
}) async {
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
              child: Text(cancelLabel),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return TextButton(
                  child: Text(submitLabel),
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
      },
    );
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
    fontSize: 16.0,
  );
}
