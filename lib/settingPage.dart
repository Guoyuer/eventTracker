import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: new ListView(
      children: [
        new RaisedButton(
            child: Text("单位管理"),
            onPressed: () {
              Navigator.pushNamed(context, 'unitsManager');
            })
      ],
    ));
  }
}
