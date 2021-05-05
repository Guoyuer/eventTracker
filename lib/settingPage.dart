import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/DAO/base.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'common/customWidget.dart';
import 'addFakeData.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(children: [
      // myRaisedButton(Text("查看数据库"), () {
      //   Navigator.push(context,
      //       MaterialPageRoute(builder: (BuildContext ctx) => DBViewRoute()));
      // }),
      RaisedButton.icon(
          label: Text("查看数据库"),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext ctx) => DBViewRoute()));
          },
          color: Colors.blue,
          highlightColor: Colors.blue[700],
          colorBrightness: Brightness.dark,
          splashColor: Colors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          icon: Icon(Icons.list_alt_rounded)),
      myRaisedButton(
          Text("单位管理"), () => Navigator.pushNamed(context, 'unitsManager')),
      RaisedButton.icon(
          label: Text("删除所有数据"),
          onPressed: () {
            DBHandle().db.deleteEverything();
          },
          color: Colors.blue,
          highlightColor: Colors.blue[700],
          colorBrightness: Brightness.dark,
          splashColor: Colors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          icon: Icon(Icons.delete_rounded)),
      RaisedButton.icon(
          label: Text("生成虚构数据"),
          onPressed: () {
            addData();
          },
          color: Colors.blue,
          highlightColor: Colors.blue[700],
          colorBrightness: Brightness.dark,
          splashColor: Colors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          icon: Icon(Icons.add_rounded))
    ]));
    var db = DBHandle().db;
    return Container(padding: EdgeInsets.all(0), child: MoorDbViewer(db));
  }
}

class DBViewRoute extends StatelessWidget {
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
