import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:drift_sqflite/drift_sqflite.dart' hide Column;
import 'package:drift/drift.dart' hide Column;

import '../DAO/base.dart';
import '../common/commonWidget.dart';

// ignore: must_be_immutable
class UnitsManager extends StatefulWidget {
  UnitsManager();

  @override
  _UnitsManagerState createState() => _UnitsManagerState();
}

class _UnitsManagerState extends State<UnitsManager> {
  late Future<List<Unit>> _units;
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _units = DBHandle().db.getAllUnits();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Unit>>(
        future: _units,
        builder: (ctx, snapshot) {
          Widget _body;
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              List<Unit> units = snapshot.data!;
              _body = _buildListView(units);
              break;
            default:
              _body = loadingScreen();
          }

          return Scaffold(
            appBar: AppBar(
              title: Text("单位管理"),
            ),
            body: _body,
          );
        });
  }

  Widget stackBehindDismiss() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.0),
      color: Colors.red,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.delete,
            color: Colors.white,
          ),
          Icon(
            Icons.delete,
            color: Colors.white,
          )
        ],
      ),
    );
  }

  Widget _buildListView(List<Unit> units) {
    return Column(
      children: [
        ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: units.length,
          itemBuilder: (ctx, idx) {
            return Dismissible(
              background: stackBehindDismiss(),
              key: ObjectKey(units[idx]),
              child: Center(
                  child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      title: Center(child: Text(units[idx].name)))),
              confirmDismiss: confirmDismissFunc,
              onDismissed: (direction) {
                DBHandle().db.deleteUnit(UnitsCompanion(name: Value(units[idx].name)));
                setState(() {
                  units.removeAt(idx);
                });
              },
            );
          },
        ),
        Container(
            padding: EdgeInsets.symmetric(horizontal: 100),
            child: myRaisedButton(Text("添加新单位"), () {
              displayTextInputDialog(context, "请输入单位", addUnitButton, controller);
            }))
      ],
    );
  }

  Future<bool> confirmDismissFunc(DismissDirection direction) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("是否删除该单位？"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("取消")),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("删除"))
            ],
          );
        });
  }

  TextButton addUnitButton() {
    return TextButton(
      // color: Colors.green,
      // textColor: Colors.white,
      child: Text('添加'),
      onPressed: controller.text.isEmpty
          ? null
          : () {
              DBHandle().db.addUnit(UnitsCompanion(name: Value(controller.text))).then((value) {
                setState(() {
                  _units = DBHandle().db.getAllUnits();
                });
                controller.clear();
                Navigator.pop(context); // 这句肯定要在最后
              }).catchError((msg) {
                Fluttertoast.showToast(
                    msg: "添加失败，可能是因为重复",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.blueAccent,
                    textColor: Colors.white,
                    fontSize: 16.0);
              });
            },
    );
  }
}
