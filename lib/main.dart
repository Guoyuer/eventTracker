import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:event_tracker/settings/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activities/activity_detail_page.dart';
import 'activities/activity_list_page.dart';
import 'activities/activity_routes.dart';
import 'activities/activity_editor_page.dart';
import 'statistics/statistics.dart';
import 'units/units_manager_page.dart';
import 'bootstrap/app_bootstrap.dart';
import 'bootstrap/error_boundary.dart';
import 'common/app_chart_theme.dart';
import 'l10n/app_localizations.dart';
import 'state/activity_list_providers.dart';
import 'state/app_navigation_providers.dart';

void main() {
  runGuarded(
    () async {
      await bootstrapApp();
      runApp(const ProviderScope(child: ActivityTrackerApp()));
    },
    onError: (error, stackTrace) {
      FlutterError.presentError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    },
  );
}

class ActivityTrackerApp extends StatelessWidget {
  const ActivityTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        ActivityRoutes.editor: (context) => ActivityEditorPage(),
        'unitsManager': (context) => UnitsManager(),
        ActivityRoutes.detail: (context) => const ActivityDetailRoute(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        extensions: const [AppChartTheme.standard],
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
    final scrollDirection = ref.watch(activityListScrollDirectionProvider);

    bool visible = selectIdx == 0 && scrollDirection == ScrollDirection.forward;
    return Visibility(
      visible: visible,
      child: FloatingActionButton(
        child: Icon(Icons.note_add_rounded),
        onPressed: () async {
          var added = await Navigator.of(
            parentContext,
          ).pushNamed(ActivityRoutes.editor);
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
    ActivityListPage(),
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
