import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Center(
            child: Column(children: [
      ElevatedButton.icon(
          label: Text("单位管理"),
          onPressed: () {
            Navigator.pushNamed(context, 'unitsManager');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
          ),
          icon: Icon(Icons.edit_rounded)),
    ])));
  }
}
