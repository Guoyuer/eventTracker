import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:event_tracker/settingPage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'EventsDetails/eventDetails.dart';
import 'EventsList/eventsList.dart';
import 'Statistics/statistics.dart';
import 'UnitManager/unitsManagerPage.dart';
import 'eventEditor.dart';
import 'bootstrap/app_bootstrap.dart';
import 'bootstrap/error_boundary.dart';
import 'l10n/app_localizations.dart';
import 'state/activity_list_providers.dart';
import 'state/app_navigation_providers.dart';

void main() {
  runGuarded(
    () async {
      await bootstrapApp();
      runApp(ProviderScope(child: EventTracker()));
    },
    onError: (error, stackTrace) {
      FlutterError.presentError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    },
  );
}

class EventTracker extends StatelessWidget {
  const EventTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        "eventEditor": (context) => EventEditor(),
        "unitsManager": (context) => UnitsManager(),
        "EventDetails": (context) => EventDetailsWrapper(),
      },
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
  const FAB(this.parentContext, {super.key});

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
          var added = await Navigator.of(
            parentContext,
          ).pushNamed("eventEditor");
          if (added != null) {
            ref.invalidate(activityListProvider);
          }
        },
      ),
    );
  }
}

class MainPage extends ConsumerWidget {
  final List<Widget> pages = const [
    EventList(),
    StatisticPage(),
    SettingPage(),
  ];

  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final bottomLabels = [
      localizations.tabActivities,
      localizations.tabStatistics,
      localizations.tabSettings,
    ];
    final selectedIdx = ref.watch(selectedIndexProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.appTitleWithSection(bottomLabels[selectedIdx]),
        ),
      ),
      body: pages[selectedIdx],
      floatingActionButton: FAB(context),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_rounded),
            label: bottomLabels[0],
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline_rounded),
            label: bottomLabels[1],
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: bottomLabels[2],
          ),
        ],
        currentIndex: selectedIdx,
        fixedColor: Colors.blue,
        onTap: (index) {
          ref.read(selectedIndexProvider.notifier).set(index);
        },
      ),
    );
  }
}
