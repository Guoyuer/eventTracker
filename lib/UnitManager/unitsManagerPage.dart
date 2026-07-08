import 'dart:core';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../DAO/base.dart';
import '../common/commonWidget.dart';
import '../persistence/unit_repository.dart';

// ignore: must_be_immutable
class UnitsManager extends StatefulWidget {
  const UnitsManager();

  @override
  _UnitsManagerState createState() => _UnitsManagerState();
}

class _UnitsManagerState extends State<UnitsManager> {
  late Future<List<Unit>> _units;
  final TextEditingController _unitNameController = TextEditingController();
  final UnitRepository _repository = unitRepository();

  @override
  void initState() {
    super.initState();
    _units = _repository.getUnits();
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    super.dispose();
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
              onDismissed: (direction) => _deleteUnit(units[idx]),
            );
          },
        ),
        Container(
            padding: EdgeInsets.symmetric(horizontal: 100),
            child: myRaisedButton(Text("添加新单位"), () {
              displayTextInputDialog(
                  context, "请输入单位", addUnitButton, _unitNameController);
            }))
      ],
    );
  }

  Future<void> _deleteUnit(Unit unit) async {
    try {
      await _repository.deleteUnit(unit.name);
      _refreshUnits();
    } catch (_) {
      showToast("删除失败");
      _refreshUnits();
    }
  }

  void _refreshUnits() {
    if (!mounted) {
      return;
    }
    setState(() {
      _units = _repository.getUnits();
    });
  }

  Future<bool> confirmDismissFunc(DismissDirection direction) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("是否删除该单位？"),
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

  TextButton addUnitButton() {
    return TextButton(
      child: Text('添加'),
      onPressed: _unitNameController.text.isEmpty ? null : _addUnit,
    );
  }

  Future<void> _addUnit() async {
    try {
      await _repository.addUnit(_unitNameController.text);
      _refreshUnits();
      _unitNameController.clear();
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } catch (_) {
      Fluttertoast.showToast(
          msg: "添加失败，可能是因为重复",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blueAccent,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }
}
