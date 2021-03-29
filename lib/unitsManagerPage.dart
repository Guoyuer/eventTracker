import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/DAO/model/Unit.dart';
import 'package:sqflite/sqflite.dart';
import 'DAO/UnitsProvider.dart';
import 'common/customWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ignore: must_be_immutable
class UnitsManager extends StatefulWidget {
  UnitsManager();

  @override
  _UnitsManagerState createState() => _UnitsManagerState();
}

class _UnitsManagerState extends State<UnitsManager> {
  UnitDbProvider db = UnitDbProvider();
  Future<List<String>> _units;
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _units = db.getAllUnits();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
        future: _units,
        builder: (ctx, snapshot) {
          Widget _body;
          List<String> units = snapshot.data;
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _body = _buildListView(units);
              break;
            default:
              _body = loadingScreen();
              break;
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
      child: Icon(
        Icons.delete,
        color: Colors.white,
      ),
    );
  }

  Widget _buildListView(List<String> units) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      // shrinkWrap: true,
      itemBuilder: (ctx, idx) {
        if (idx == units.length) {
          return Container(
              padding: EdgeInsets.symmetric(horizontal: 80),
              child: myRaisedButton(Text("添加新单位"), () {
                _displayTextInputDialog(context);
              }));
        } else {
          return Dismissible(
            background: stackBehindDismiss(),
            key: ObjectKey(units[idx]),
            child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
                title: Text(units[idx])),
            confirmDismiss: confirmDismissFunc,
            onDismissed: (direction) {
              db.delete(UnitModel(units[idx]));
              setState(() {
                units.removeAt(idx);
              });
            },
          );
        }
      },
      itemCount: units.length + 1,
    );
  }

  Future<bool> confirmDismissFunc(DismissDirection direction) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("是否删除？"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("取消")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("删除"))
            ],
          );
        });
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text('请输入单位'),
              content: TextField(
                onChanged: (value) {
                  setState(() {
                    // print(OKButton().enabled);
                  });
                },
                controller: controller,
              ),
              // decoration: InputDecoration(hintText: "如：米"),

              actions: <Widget>[
                FlatButton(
                  color: Colors.red,
                  textColor: Colors.white,
                  child: Text('取消'),
                  onPressed: () {
                    setState(() {
                      // listNeedUpdate = false;
                      Navigator.pop(context); //false表示不需要刷新
                    });
                  },
                ),
                addUnitButton(),
              ],
            );
          });
        });
  }

  FlatButton addUnitButton() {
    return FlatButton(
      color: Colors.green,
      textColor: Colors.white,
      child: Text('添加'),
      onPressed: controller.text.isEmpty
          ? null
          : () {
              db.insert(UnitModel(controller.text)).then((value) {
                setState(() {
                  _units = db.getAllUnits();
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
