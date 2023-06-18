import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:event_tracker/StepCount/stepStatistics.dart';
import 'package:event_tracker/settingPage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share/share.dart';
import 'EventsDetails/eventDetails.dart';
import 'EventsList/eventsList.dart';
import 'Statistics/statistics.dart';
// import 'StepCount/pedometer.dart';
import 'UnitManager/unitsManagerPage.dart';
import 'common/const.dart';
import 'eventEditor.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ProviderScope(child: EventTracker()));
}

class EventTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
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
      home: MainPage(),
    );
  }
}

final FABVisiblilityProvider = StateProvider<bool>((ref) {
  return true;
});

final selectedIndexProvider = StateProvider<int>((ref) {
  return 0;
});

class FAB extends ConsumerWidget {
  final BuildContext parentContext;
  FAB(this.parentContext);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectIdx = ref.watch(selectedIndexProvider);
    switch (selectIdx) {
      case 0:
        return FloatingActionButton(
            child: Icon(Icons.note_add_rounded),
            onPressed: () async {
              var added = await Navigator.of(parentContext).pushNamed("eventEditor");
              if (added != null) {
                ReloadEventsN().dispatch(parentContext);
              }
            });
      case 1:
        return FloatingActionButton(
            child: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(parentContext).pushNamed("StepStatistics");
            });
    }
    return FloatingActionButton(
      child: Icon(Icons.bar_chart),
      onPressed: null,
    );
  }
}

class MainPage extends ConsumerWidget {
  // const MainPage({Key? key}) : super(key: key);
  // @override
  // MainPageState createState() => MainPageState();
  final List<String> bottomLabels = ["项目", "统计", "选项"];

  final List<Widget> pages = [
    EventList(),
    StatisticPage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = ref.watch(selectedIndexProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text("活动记录本 - " + bottomLabels[selectedIdx]),
        // actions: actionButtons(context),
      ),
      body: NotificationListener<Notification>(
          child: pages[selectedIdx],
          onNotification: (notification) {
            if (notification is ReloadEventsN) {
              debugPrint("refresh!!!");
              Navigator.pop(context, true);
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => MainPage()));
            }
            return true;
          }),
      floatingActionButton: selectedIdx <= 1 ? FAB(context) : null,
      bottomNavigationBar: BottomNavigationBar(
          // 底部导航
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: bottomLabels[0]),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline_rounded), label: bottomLabels[1]),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: bottomLabels[2]),
          ],
          currentIndex: selectedIdx,
          fixedColor: Colors.blue,
          onTap: (index) {
            ref.read(selectedIndexProvider.notifier).update((state) => state = index);
          }),
    );
  }
}

// }
// // class _MainPagesState extends ConsumerState<MainPages> {
//   List<String> bottomLabels = ["项目", "计步", "统计", "选项"];
//   bool floatingButtonVisible = true;
//   List<Widget> _children = [
//     EventList(),
//     // PedometerPage(),
//     StatisticPage(),
//     SettingPage(),
//   ];
//   late String directory;

//   @override
//   void initState() {
//     super.initState();
//   }

//   bool bnVisible = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("活动记录本 - " + bottomLabels[_selectedIndex]),
//         actions: actionButtons(context),
//       ),
//       body: NotificationListener<Notification>(
//         child: _children[_selectedIndex],
//         onNotification: (notification) {
//           if (notification is ReloadEventsN) {
//             setState(() {
//               _children.removeAt(0);
//               _children.insert(0, EventList(key: GlobalKey()));
//             });
//             return true;
//           }
//           if (notification is ScrollDirectionN) {
//             setState(() {
//               if (notification.direction == ScrollDirection.reverse) {
//                 bnVisible = false;
//               } else {
//                 bnVisible = true;
//               }
//             });
//             return true;
//           }
//           return true;
//         },
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         // 底部导航
//         type: BottomNavigationBarType.fixed,
//         items: <BottomNavigationBarItem>[
//           BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: bottomLabels[0]),
//           BottomNavigationBarItem(icon: Icon(Icons.directions_walk_rounded), label: bottomLabels[1]),
//           BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline_rounded), label: bottomLabels[2]),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: bottomLabels[3]),
//         ],
//         currentIndex: _selectedIndex,
//         fixedColor: Colors.blue,
//         onTap: _onItemTapped,
//       ),
//       floatingActionButton: bnVisible ? floatingButton(context) : null,
//     );
//   }

//   List<Widget> actionButtons(BuildContext context) {
//     switch (_selectedIndex) {
//       case 3:
//         return [
//           IconButton(
//               icon: Icon(Icons.share_rounded),
//               onPressed: () {
//                 Share.share('四川大学计算机系毕业设计项目。GitHub Repo：https://github.com/Guoyuer/flutter_event_tracker');
//               })
//         ];
//       default:
//         return [];
//     }
//   }



// void _onItemTapped(int index) {
//   selectedIndexProvider.addListener
//   setState(() {
//     _selectedIndex = index;
//     if (_selectedIndex == 1) bnVisible = true;
//   });
// }
