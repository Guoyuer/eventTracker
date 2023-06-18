import 'package:flutter/material.dart';
import 'package:event_tracker/DAO/base.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'addFakeData.dart';

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
            // highlightColor: Colors.blue[700],
            // colorBrightness: Brightness.dark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          ),
          // splashColor: Colors.grey,
          icon: Icon(Icons.edit_rounded)),
      SizedBox(height: 50),
      ElevatedButton.icon(
          label: Text("查看数据库"),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => DBViewRoute()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          ),
          // highlightColor: Colors.blue[700],
          // colorBrightness: Brightness.dark,
          // splashColor: Colors.grey,
          icon: Icon(Icons.list_alt_rounded)),
      ElevatedButton.icon(
          label: Text("删除所有数据"),
          onPressed: () {
            DBHandle().db.deleteEverything();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          ),
          // highlightColor: Colors.blue[700],
          // colorBrightness: Brightness.dark,
          // splashColor: Colors.grey,
          icon: Icon(Icons.delete_rounded)),
      ElevatedButton.icon(
          label: Text("生成虚构数据"),
          onPressed: () {
            addData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          ),
          // highlightColor: Colors.blue[700],
          // colorBrightness: Brightness.dark,
          // splashColor: Colors.grey,
          icon: Icon(Icons.add_rounded))
    ])));
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
