import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:flutter_event_tracker/common/util.dart';
import 'package:flutter_event_tracker/DAO/model/Record.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fluttertoast/fluttertoast.dart';

RaisedButton myRaisedButton(
    Widget child, Function onPressCallBack, [Function onLongPressCallBack]) {
  return RaisedButton(
      color: Colors.blue,
      highlightColor: Colors.blue[700],
      colorBrightness: Brightness.dark,
      splashColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      // padding: EdgeInsets.symmetric(horizontal: 50),
      child: child,
      onPressed: onPressCallBack,
      onLongPress: onLongPressCallBack);
}

Widget loadingScreen() {
  return Center(
    child: Container(
      width: 50,
      height: 50,
      child: CircularProgressIndicator(),
    ),
  );
}
