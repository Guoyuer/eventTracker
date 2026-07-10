import 'package:flutter/material.dart';

ElevatedButton primaryActionButton({
  required Widget child,
  required VoidCallback onPressed,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      padding: EdgeInsets.symmetric(horizontal: 50),
    ),
    onPressed: onPressed,
    child: child,
  );
}

Widget activityActionButton({
  required Icon icon,
  required Widget label,
  required VoidCallback onPressed,
}) {
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
      onPressed: onPressed,
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
                  onPressed: value.text.isEmpty
                      ? null
                      : () async {
                          final shouldClose = await onSubmit(value.text);
                          if (shouldClose && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: Text(submitLabel),
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

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
