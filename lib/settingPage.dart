import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/DAO/base.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'common/customWidget.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var db = DBHandle().db;
    return Container(padding: EdgeInsets.all(0), child: MoorDbViewer(db));
  }
}
// SizedBox(
//   width: 100,
//   child: myRaisedButton(Text("单位管理"),
//       () => Navigator.pushNamed(context, 'unitsManager')),
// ),
