import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_event_tracker/StepCount/stepStatistics.dart';
import 'package:flutter_event_tracker/settingPage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share/share.dart';

import 'DAO/base.dart';
import 'EventsDetails/eventDetails.dart';
import 'EventsList/eventsList.dart';
import 'Statistics/statistics.dart';
import 'StepCount/pedometer.dart';
import 'UnitManager/unitsManagerPage.dart';
import 'common/const.dart';
import 'eventEditor.dart';

void main() {
  runApp(EventTracker());
}

class EventTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [GlobalMaterialLocalizations.delegate],
      supportedLocales: [const Locale('en'), const Locale('zh')],
      routes: {
        "eventEditor": (context) => EventEditor(),
        "unitsManager": (context) => UnitsManager(),
        "EventDetails": (context) => EventDetailsWrapper(),
        "StepStatistics": (context) => StepStatPage()
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
  // final UniqueKey _key = UniqueKey();

  @override
  _MainPagesState createState() => _MainPagesState();
}

class _MainPagesState extends State<MainPages> {
  int _selectedIndex = 0;
  List<String> bottomLabels = ["项目", "计步", "统计", "选项"];
  bool floatingButtonVisible = true;
  List<Widget> _children = [
    EventList(),
    PedometerPage(),
    StatisticPage(),
    SettingPage(),
  ];
  dynamic eventData; //添加event用，接收返回值

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("活动记录本 - " + bottomLabels[_selectedIndex]),
        actions: actionButtons(context),
      ),
      body: NotificationListener<ReloadEventsNotification>(
        // child: IndexedStack(children: _children, index: _selectedIndex),
        child: _children[_selectedIndex],
        onNotification: (notification) {
          setState(() {
            _children.removeAt(0);
            _children.insert(0, EventList(key: GlobalKey()));
          });
          return true;
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        // 底部导航
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_rounded), label: bottomLabels[0]),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk_rounded),
              label: bottomLabels[1]),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              label: bottomLabels[2]),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: bottomLabels[3]),
        ],
        currentIndex: _selectedIndex,
        fixedColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: floatingButton(context),
    );
  }

  List<Widget> actionButtons(BuildContext context) {
    switch (_selectedIndex) {
      case 3:
        return [
          IconButton(
              icon: Icon(Icons.share_rounded),
              onPressed: () {
                Share.share('该应用由四川大学吴玉章学院17级本科生郭遇尔开发');
              })
        ];
      default:
        return [];
    }
  }

  dynamic floatingButton(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return FloatingActionButton(
            //悬浮按钮
            child: Icon(Icons.note_add_rounded),
            onPressed: () {
              eventData = Navigator.of(context).pushNamed("eventEditor");
              eventData.then((event) {
                if (event != null) {
                  DBHandle().db.addEventInDB(event);
                  setState(() {
                    _children.removeAt(0);
                    _children.insert(0, EventList(key: GlobalKey()));
                  });
                }
              });
            });
      case 1:
        return FloatingActionButton(
            //悬浮按钮
            child: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).pushNamed("StepStatistics");
            });
      default:
        return null;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      // if (index == 0 || index == 1) {
      //   floatingButtonVisible = true;
      // } else {
      //   floatingButtonVisible = false;
      // }
      _selectedIndex = index;
    });
  }
}
