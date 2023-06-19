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
import 'eventEditor.dart';
import 'common/const.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'stateProviders.dart';

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

class FAB extends ConsumerWidget {
  final BuildContext parentContext;
  FAB(this.parentContext);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectIdx = ref.watch(selectedIndexProvider);
    final scrollDirection = ref.watch(eventListScrollDirProvider);

    bool visible = selectIdx == 0 && scrollDirection == ScrollDirection.forward;
    return Visibility(
        visible: visible,
        child: FloatingActionButton(
            child: Icon(Icons.note_add_rounded),
            onPressed: () async {
              var added = await Navigator.of(parentContext).pushNamed("eventEditor");
              if (added != null) {
                ReloadEventsN().dispatch(parentContext);
              }
            }));
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
      floatingActionButton: FAB(context),
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
