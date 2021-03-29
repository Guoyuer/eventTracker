import 'package:flutter/material.dart';
import 'common/customWidget.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(50),
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 100,
              child: myRaisedButton(Text("单位管理"),
                  () => Navigator.pushNamed(context, 'unitsManager')),
            ),
          ),
        ));
  }
}
