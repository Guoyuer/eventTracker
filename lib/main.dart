import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:event_tracker/settingPage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'EventsDetails/eventDetails.dart';
import 'EventsList/eventsList.dart';
import 'Statistics/statistics.dart';
import 'UnitManager/unitsManagerPage.dart';
import 'eventEditor.dart';
import 'bootstrap/app_bootstrap.dart';
import 'state/activity_list_providers.dart';
import 'state/app_navigation_providers.dart';

void main() async {
  await bootstrapApp();
  runApp(ProviderScope(child: EventTracker()));
}

class EventTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [GlobalMaterialLocalizations.delegate],
      supportedLocales: [const Locale('en'), const Locale('zh')],
      routes: {
        "eventEditor": (context) => EventEditor(),
        "unitsManager": (context) => UnitsManager(),
        "EventDetails": (context) => EventDetailsWrapper(),
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
              var added =
                  await Navigator.of(parentContext).pushNamed("eventEditor");
              if (added != null) {
                ref.invalidate(activityListProvider);
              }
            }));
  }
}

class MainPage extends ConsumerWidget {
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
      ),
      body: pages[selectedIdx],
      floatingActionButton: FAB(context),
      bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.event_note_rounded), label: bottomLabels[0]),
            BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_outline_rounded),
                label: bottomLabels[1]),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: bottomLabels[2]),
          ],
          currentIndex: selectedIdx,
          fixedColor: Colors.blue,
          onTap: (index) {
            ref
                .read(selectedIndexProvider.notifier)
                .update((state) => state = index);
          }),
    );
  }
}
