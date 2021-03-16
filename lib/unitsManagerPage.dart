import 'package:flutter/material.dart';
import 'DAO/UnitsProvider.dart';
import 'common/const.dart';

// ignore: must_be_immutable
class UnitsManager extends StatefulWidget {
  UnitsManager();

  @override
  _UnitsManagerState createState() => _UnitsManagerState();
}

class _UnitsManagerState extends State<UnitsManager> {
  List<Widget> listChildren = List<Widget>();
  TextEditingController _textFieldController = TextEditingController();
  String codeDialog;
  String valueText;

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('请输入单位'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "Text Field in Dialog"),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                child: Text('取消'),
                onPressed: () {
                  setState(() {
                    listNeedUpdate = false;
                    Navigator.pop(context);
                  });
                },
              ),
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: Text('OK'),
                onPressed: () {
                  setState(() {
                    codeDialog = valueText;
                    Navigator.pop(context);
                    listNeedUpdate = true;
                  });
                },
              ),
            ],
          );
        });
  }

  bool listNeedUpdate = true;

  @override
  Widget build(BuildContext context) {
    if (listNeedUpdate) {
      setState(() {
        listChildren.clear();
        listChildren.addAll(Global.units.map((e) {
          //加入全部单位
          return CheckboxListTile(
              title: Text(e),
              value: true,
              onChanged: (bool v) {
                print(v);
              });
        }));
        listChildren.add(RaisedButton(
            child: Text("添加新单位"),
            onPressed: () {
              _displayTextInputDialog(context);
            }));
      });
    }

    return Scaffold(
      body: ListView(
        children: listChildren,
      ),
      appBar: AppBar(
        title: Text("单位管理"),
      ),
    );
  }
}
