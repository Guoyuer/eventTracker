import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/settingPage.dart';
import 'DAO/AbstractProvider.dart';
import 'heatMapPage.dart';
import 'eventsPage.dart';
import 'eventEditor.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'common/const.dart';
import 'unitsManagerPage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Global.init().then((e) => runApp(EventTracker()));
}

class EventTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "eventEditor": (context) => new EventEditor(),
        "unitsManager": (context) => new UnitsManager(),
      },
      title: 'Event Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPages(),
    );
  }
}

class MainPages extends StatefulWidget {
  @override
  _MainPagesState createState() => _MainPagesState();
}

class _MainPagesState extends State<MainPages> {
  int _selectedIndex = 0;
  final List<Widget> _children = [EventsList(), HeatMap(), SettingPage()];
  bool floatingButtonVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Event Tracker"),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.share), onPressed: () {}),
        ],
      ),
      // drawer: new MyDrawer(), //抽屉
      body: _children[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        // 底部导航
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_rounded), label: '事项'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '选项'),
        ],
        currentIndex: _selectedIndex,
        fixedColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: new Visibility(
          visible: floatingButtonVisible,
          child: FloatingActionButton(
            //悬浮按钮
              child: Icon(Icons.note_add_rounded),
              onPressed: () {
                Navigator.pushNamed(context, "eventEditor");
              })),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        floatingButtonVisible = true;
      } else {
        floatingButtonVisible = false;
      }
      _selectedIndex = index;
    });
  }
}
