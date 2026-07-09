import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removed prototype files and dependencies stay removed', () {
    expect(File('lib/addFakeData.dart').existsSync(), isFalse);
    expect(File('lib/StepCount/stepStatistics.dart').existsSync(), isFalse);
    expect(File('lib/stateProviders.dart').existsSync(), isFalse);

    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lockfile = File('pubspec.lock').readAsStringSync();

    for (final packageName in [
      'share',
      'moor_db_viewer',
      'db_viewer',
      'firebase_core',
      'random_color',
      'sprintf',
    ]) {
      expect(pubspec, isNot(contains('$packageName:')));
      expect(lockfile, isNot(contains('$packageName:')));
    }
  });

  test('sdk and dependencies stay on the modernized toolchain', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lockfile = File('pubspec.lock').readAsStringSync();

    expect(pubspec, contains('sdk: ^3.12.0'));
    expect(pubspec, contains('flutter_riverpod: ^3.3.2'));
    expect(pubspec, contains('fl_chart: ^1.2.0'));
    expect(pubspec, contains('drift: ^2.34.1'));
    expect(pubspec, contains('build_runner: ^2.15.1'));
    expect(pubspec, contains('drift_dev: ^2.34.0'));
    expect(pubspec, contains('sqlite3_flutter_libs: ^0.5.42'));
    expect(pubspec, isNot(contains('sqlite3_flutter_libs: ^0.6.0+eol')));
    expect(pubspec, contains('flutter_lints: ^6.0.0'));
    expect(lockfile, contains('flutter_riverpod'));
    expect(lockfile, contains('version: "3.3.2"'));
    expect(lockfile, contains('sqlite3_flutter_libs'));
    expect(lockfile, contains('version: "0.5.42"'));
    expect(lockfile, isNot(contains('version: "0.6.0+eol"')));

    for (final discontinuedPackage in [
      'js',
      'build_resolvers',
      'build_runner_core',
    ]) {
      expect(lockfile, isNot(contains('\n  $discontinuedPackage:\n')));
    }
  });

  test('legacy step schema stays retired from active Drift schema', () {
    final tables = File(
      'lib/persistence/database/tables.dart',
    ).readAsStringSync();
    final database = File(
      'lib/persistence/database/app_database.dart',
    ).readAsStringSync();
    final sql = File('lib/persistence/database/sql.drift').readAsStringSync();

    expect(tables, isNot(contains('class Steps')));
    expect(tables, isNot(contains('class StepOffset')));
    expect(database, isNot(contains('eventId.equals(-1)')));
    expect(sql, isNot(contains('step_time')));
  });

  test('analytics modules do not import generated Drift database types', () {
    for (final path in [
      'lib/analytics/activity_detail_analytics.dart',
      'lib/analytics/statistics_analytics.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, isNot(contains("../DAO/base.dart")));
      expect(
        source,
        isNot(contains("../persistence/database/app_database.dart")),
      );
      expect(source, isNot(contains("List<Record")));
      expect(source, isNot(contains("Map<int, Event")));
    }
  });

  test('domain models do not depend on UI constants', () {
    final models = File('lib/domain/activity_models.dart').readAsStringSync();
    final constants = File('lib/common/const.dart').readAsStringSync();

    expect(models, isNot(contains('common/const.dart')));
    expect(models, contains('enum EventStatus'));
    expect(constants, isNot(contains('enum EventStatus')));
  });

  test('ui state does not import the Drift database module directly', () {
    for (final path in [
      'lib/state/activity_detail_providers.dart',
      'lib/state/activity_editor_providers.dart',
      'lib/state/activity_list_providers.dart',
      'lib/state/app_navigation_providers.dart',
      'lib/state/statistics_providers.dart',
      'lib/state/unit_providers.dart',
      'lib/eventEditor.dart',
      'lib/UnitManager/unitsManagerPage.dart',
      'lib/EventsList/eventsList.dart',
      'lib/EventsDetails/eventDetails.dart',
      'lib/Statistics/statistics.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, isNot(contains('persistence/database/app_database.dart')));
    }
  });

  test('active app files import focused state modules instead of facade', () {
    for (final path in [
      'lib/main.dart',
      'lib/eventEditor.dart',
      'lib/UnitManager/unitsManagerPage.dart',
      'lib/EventsList/eventsList.dart',
      'lib/EventsDetails/eventDetails.dart',
      'lib/EventsDetails/activity_description_editor.dart',
      'lib/Statistics/statistics.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, isNot(contains('stateProviders.dart')));
    }

    expect(File('lib/stateProviders.dart').existsSync(), isFalse);
  });

  test(
    'riverpod state uses current notifier providers instead of legacy state providers',
    () {
      final mutableState = File(
        'lib/state/mutable_state.dart',
      ).readAsStringSync();
      expect(
        mutableState,
        contains('class MutableState<T> extends Notifier<T>'),
      );
      expect(mutableState, contains('void set(T value)'));
      expect(mutableState, contains('void update(T Function(T value) update)'));

      for (final path in [
        'lib/state/activity_detail_providers.dart',
        'lib/state/activity_editor_providers.dart',
        'lib/state/activity_list_providers.dart',
        'lib/state/app_navigation_providers.dart',
        'lib/state/statistics_providers.dart',
        'lib/eventEditor.dart',
        'lib/main.dart',
        'lib/EventsList/eventsList.dart',
        'lib/EventsDetails/activity_description_editor.dart',
        'lib/Statistics/statistics.dart',
      ]) {
        final source = File(path).readAsStringSync();

        expect(source, isNot(contains('package:flutter_riverpod/legacy.dart')));
        expect(source, isNot(contains('StateProvider')));
        expect(source, isNot(contains('.notifier).state')));
      }
    },
  );

  test('persistence providers own database adapter wiring', () {
    final providers = File(
      'lib/persistence/persistence_providers.dart',
    ).readAsStringSync();

    expect(providers, contains('appDatabaseProvider'));
    expect(providers, contains('Provider<AppDatabase>'));
    expect(providers, contains('DriftActivityRepository'));
    expect(providers, contains('DriftUnitRepository'));
    expect(providers, contains('DriftStatisticsRepository'));
  });

  test('repositories do not create the production database singleton', () {
    for (final path in [
      'lib/persistence/activity_repository.dart',
      'lib/persistence/unit_repository.dart',
      'lib/persistence/statistics_repository.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, isNot(contains('DBHandle')));
      expect(source, isNot(contains('AppDatabase()')));
      expect(source, isNot(contains('activityRepository()')));
      expect(source, isNot(contains('unitRepository()')));
      expect(source, isNot(contains('statisticsRepository()')));
    }
  });

  test('app database does not own platform bootstrap details', () {
    final database = File(
      'lib/persistence/database/app_database.dart',
    ).readAsStringSync();
    final bootstrap = File(
      'lib/persistence/database/database_bootstrap.dart',
    ).readAsStringSync();

    expect(database, isNot(contains('path_provider')));
    expect(database, isNot(contains('drift_sqflite')));
    expect(database, isNot(contains('defaultTargetPlatform')));
    expect(database, isNot(contains('getApplicationSupportDirectory')));
    expect(database, isNot(contains('usesExplicitDatabasePathOnPlatform')));
    expect(database, contains('database_bootstrap.dart'));
    expect(bootstrap, contains('defaultDatabaseExecutor'));
    expect(bootstrap, contains('usesExplicitDatabasePathOnPlatform'));
  });

  test('app database does not shape activity display models', () {
    final database = File(
      'lib/persistence/database/app_database.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/persistence/activity_repository.dart',
    ).readAsStringSync();

    expect(database, isNot(contains('activity_models.dart')));
    expect(database, isNot(contains('BaseEventModel')));
    expect(database, isNot(contains('TimingEventModel')));
    expect(database, isNot(contains('PlainEventModel')));
    expect(database, isNot(contains('EventStatus')));
    expect(database, isNot(contains('getEventsProfile')));
    expect(database, isNot(contains('_eventProcessor')));
    expect(repository, contains('BaseEventModel'));
    expect(repository, contains('TimingEventModel'));
    expect(repository, contains('PlainEventModel'));
  });

  test('app database does not own repository-specific query helpers', () {
    final database = File(
      'lib/persistence/database/app_database.dart',
    ).readAsStringSync();
    final unitRepository = File(
      'lib/persistence/unit_repository.dart',
    ).readAsStringSync();
    final statisticsRepository = File(
      'lib/persistence/statistics_repository.dart',
    ).readAsStringSync();
    final detailAnalytics = File(
      'lib/analytics/activity_detail_analytics.dart',
    ).readAsStringSync();
    final statisticsProviders = File(
      'lib/state/statistics_providers.dart',
    ).readAsStringSync();

    expect(database, isNot(contains('flutter/material.dart')));
    expect(database, isNot(contains('DateTimeRange')));
    expect(statisticsRepository, isNot(contains('flutter/material.dart')));
    expect(statisticsRepository, isNot(contains('DateTimeRange')));
    expect(detailAnalytics, isNot(contains('flutter/material.dart')));
    expect(detailAnalytics, isNot(contains('DateTimeRange')));
    expect(statisticsProviders, isNot(contains('flutter/material.dart')));
    expect(statisticsProviders, isNot(contains('DateTimeRange')));
    expect(statisticsRepository, contains('DateRange'));
    expect(detailAnalytics, contains('DateRange'));
    expect(database, isNot(contains('getAllUnits')));
    expect(database, isNot(contains('deleteUnitByName')));
    expect(database, isNot(contains('getRecordsInRange')));
    expect(database, isNot(contains('getEventsMap')));
    expect(database, isNot(contains('getRecordsByEventId')));
    expect(database, isNot(contains('getEventDesc')));
    expect(database, isNot(contains('getEventUnit')));
    expect(database, isNot(contains('getRawEvents')));
    expect(database, isNot(contains('addEventInDB')));
    expect(database, isNot(contains('updateEventDescription')));
    expect(database, isNot(contains('deleteEvent')));
    expect(unitRepository, contains('select(_db.units)'));
    expect(statisticsRepository, contains('select(_db.records)'));
    expect(statisticsRepository, contains('select(_db.events)'));
  });

  test('shared common widgets do not create persistence repositories', () {
    final source = File('lib/common/commonWidget.dart').readAsStringSync();

    expect(source, isNot(contains('activity_repository.dart')));
    expect(source, isNot(contains('activityRepository()')));
    expect(source, isNot(contains('FutureBuilder<String?>')));
  });

  test('shared text input dialog rebuilds from controller state', () {
    final source = File('lib/common/commonWidget.dart').readAsStringSync();

    expect(source, contains('ValueListenableBuilder<TextEditingValue>'));
    expect(source, isNot(contains('StatefulBuilder')));
    expect(source, isNot(contains('setState(')));
  });

  test('async loading empty and error states use the shared module', () {
    final asyncState = File('lib/common/async_state.dart').readAsStringSync();
    final commonWidgets = File(
      'lib/common/commonWidget.dart',
    ).readAsStringSync();

    expect(asyncState, contains('class AsyncStateView'));
    expect(asyncState, contains('enum AsyncStateLayout'));
    expect(asyncState, contains('CircularProgressIndicator'));
    expect(commonWidgets, isNot(contains('loadingScreen')));

    for (final path in [
      'lib/EventsList/eventsList.dart',
      'lib/EventsDetails/eventDetails.dart',
      'lib/EventsDetails/activity_description_editor.dart',
      'lib/Statistics/statistics.dart',
      'lib/UnitManager/unitsManagerPage.dart',
      'lib/eventEditor.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, contains('AsyncStateView'));
      expect(source, isNot(contains('.when(')));
      expect(source, isNot(contains('loadingScreen')));
    }
  });

  test(
    'ui widgets use repository providers instead of repository factories',
    () {
      for (final path in [
        'lib/EventsList/eventsList.dart',
        'lib/EventsList/events_list_helpers.dart',
        'lib/eventEditor.dart',
        'lib/UnitManager/unitsManagerPage.dart',
      ]) {
        final source = File(path).readAsStringSync();

        expect(source, isNot(contains('activityRepository()')));
        expect(source, isNot(contains('unitRepository()')));
        expect(source, isNot(contains('statisticsRepository()')));
      }
    },
  );

  test('activity list delegates recording actions to a testable module', () {
    final eventsList = File(
      'lib/EventsList/eventsList.dart',
    ).readAsStringSync();
    final listHelpers = File(
      'lib/EventsList/events_list_helpers.dart',
    ).readAsStringSync();
    final controller = File(
      'lib/application/activity_recording_controller.dart',
    ).readAsStringSync();
    final listController = File(
      'lib/application/activity_list_controller.dart',
    ).readAsStringSync();
    final actions = File(
      'lib/application/activity_recording_actions.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/persistence/activity_repository.dart',
    ).readAsStringSync();

    expect(eventsList, contains('ActivityListController'));
    expect(eventsList, isNot(contains('ActivityRecordingActions')));
    expect(eventsList, isNot(contains('recordActivity(context')));
    expect(eventsList, isNot(contains('switch (outcome)')));
    expect(listHelpers, isNot(contains('WidgetRef')));
    expect(listController, contains('ActivityRecordingController'));
    expect(listController, contains('ActivityRecordingActions'));
    expect(listController, contains('recordActivity'));
    expect(controller, contains('ActivityRecordingActions'));
    expect(controller, isNot(contains('BuildContext')));
    expect(controller, isNot(contains('WidgetRef')));
    expect(controller, isNot(contains('addPlainRecord(')));
    expect(controller, isNot(contains('startTimedRecord(')));
    expect(controller, isNot(contains('stopActiveTimedRecord(')));
    expect(controller, isNot(contains('cancelActiveTimedRecord(')));
    expect(actions, contains('ActivityRecordingOutcome'));
    expect(actions, contains('accidentalTimedRecordThreshold'));
    expect(repository, isNot(contains('getActivityUnit')));
  });

  test('activity detail deletion has a single activity-list refresh owner', () {
    final details = File(
      'lib/EventsDetails/eventDetails.dart',
    ).readAsStringSync();
    final eventsList = File(
      'lib/EventsList/eventsList.dart',
    ).readAsStringSync();
    final listController = File(
      'lib/application/activity_list_controller.dart',
    ).readAsStringSync();

    expect(details, isNot(contains('activityListProvider')));
    expect(details, isNot(contains('ref.invalidate(activityListProvider)')));
    expect(eventsList, contains('ref.invalidate(activityListProvider)'));
    expect(eventsList, contains('ActivityListController'));
    expect(eventsList, isNot(contains('deleted != null && deleted')));
    expect(eventsList, isNot(contains('class EventDataHolder')));
    expect(listController, contains('showActivityDetail'));
  });

  test('route mutation policy lives in application controllers', () {
    final editor = File('lib/eventEditor.dart').readAsStringSync();
    final unitManager = File(
      'lib/UnitManager/unitsManagerPage.dart',
    ).readAsStringSync();
    final details = File(
      'lib/EventsDetails/eventDetails.dart',
    ).readAsStringSync();

    expect(editor, contains('ActivityEditorController'));
    expect(
      editor,
      isNot(contains('.read(activityRepositoryProvider).createActivity')),
    );
    expect(unitManager, contains('UnitManagementController'));
    expect(
      unitManager,
      isNot(contains('.read(unitRepositoryProvider).addUnit')),
    );
    expect(
      unitManager,
      isNot(contains('.read(unitRepositoryProvider).deleteUnit')),
    );
    expect(details, contains('ActivityDetailController'));
    expect(details, contains('confirmDelete:'));
    expect(
      details,
      isNot(contains('.read(activityRepositoryProvider).deleteActivity')),
    );
    final descriptionEditor = File(
      'lib/EventsDetails/activity_description_editor.dart',
    ).readAsStringSync();
    expect(descriptionEditor, contains('ActivityDetailController'));
    expect(
      descriptionEditor,
      isNot(
        contains('.read(activityRepositoryProvider).updateActivityDescription'),
      ),
    );

    for (final path in [
      'lib/application/activity_list_controller.dart',
      'lib/application/activity_editor_controller.dart',
      'lib/application/activity_detail_controller.dart',
      'lib/application/unit_management_controller.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, isNot(contains('package:flutter/material.dart')));
      expect(source, isNot(contains('BuildContext')));
      expect(source, isNot(contains('WidgetRef')));
    }
  });

  test(
    'activity list does not expose incomplete manual time entry controls',
    () {
      final activityList = File(
        'lib/EventsList/eventsList.dart',
      ).readAsStringSync();

      expect(activityList, isNot(contains('showTimePicker')));
      expect(activityList, isNot(contains('手动指定')));
    },
  );

  test('activity tiles keep ticking state outside the whole tile widget', () {
    final activityList = File(
      'lib/EventsList/eventsList.dart',
    ).readAsStringSync();
    final providers = File(
      'lib/state/activity_list_providers.dart',
    ).readAsStringSync();

    expect(
      activityList,
      isNot(contains('class EventTile extends ConsumerStatefulWidget')),
    );
    expect(activityList, contains('class EventList extends ConsumerWidget'));
    expect(
      activityList,
      contains('class ActivityListView extends StatefulWidget'),
    );
    expect(activityList, isNot(contains('Timer.periodic')));
    expect(activityList, isNot(contains('class _LapsedTimeStrState')));
    expect(activityList, contains('class ActiveTimingHighlight'));
    expect(
      activityList,
      contains('class LapsedTimeStr extends ConsumerWidget'),
    );
    expect(providers, contains('elapsedDurationProvider'));
  });

  test('unused common widget helpers stay deleted', () {
    final common = File('lib/common/commonWidget.dart').readAsStringSync();

    expect(common, isNot(contains('DividerWithText')));
    expect(common, isNot(contains('onLongPressCallBack')));
  });

  test('statistics page keeps selected range in Riverpod state', () {
    final statistics = File(
      'lib/Statistics/statistics.dart',
    ).readAsStringSync();
    final providers = File(
      'lib/state/statistics_providers.dart',
    ).readAsStringSync();

    expect(statistics, isNot(contains('StatefulWidget')));
    expect(statistics, isNot(contains('setState(')));
    expect(statistics, isNot(contains('fl_chart')));
    expect(statistics, isNot(contains('statistics_analytics.dart')));
    expect(statistics, isNot(contains('PieChart')));
    expect(statistics, isNot(contains('BarChart')));
    expect(statistics, contains('selectedStatisticsRangeProvider'));
    expect(statistics, contains('StatisticsCharts'));
    expect(providers, contains('selectedStatisticsRangeProvider'));
    expect(providers, contains('statisticsProvider'));
  });

  test('activity detail route delegates chart rendering', () {
    final details = File(
      'lib/EventsDetails/eventDetails.dart',
    ).readAsStringSync();
    final charts = File(
      'lib/EventsDetails/activity_detail_charts.dart',
    ).readAsStringSync();

    expect(details, isNot(contains('fl_chart')));
    expect(details, isNot(contains('HeatMapCalendar')));
    expect(details, isNot(contains('activity_detail_analytics.dart')));
    expect(details, isNot(contains('ConsumerStatefulWidget')));
    expect(details, contains('ActivityDetailCharts'));
    expect(charts, contains('fl_chart'));
    expect(charts, contains('HeatMapCalendar'));
    expect(charts, contains('buildActivityDetailChartModel'));
  });

  test(
    'chart adapters delegate view model construction to analytics modules',
    () {
      final detailCharts = File(
        'lib/EventsDetails/activity_detail_charts.dart',
      ).readAsStringSync();
      final statisticsCharts = File(
        'lib/Statistics/statistics_charts.dart',
      ).readAsStringSync();
      final detailModel = File(
        'lib/analytics/activity_detail_chart_models.dart',
      ).readAsStringSync();
      final statisticsModel = File(
        'lib/analytics/statistics_chart_models.dart',
      ).readAsStringSync();

      expect(detailCharts, contains('buildActivityDetailChartModel'));
      expect(detailCharts, isNot(contains('recordsInMonth(')));
      expect(detailCharts, isNot(contains('recordsOnDay(')));
      expect(detailCharts, isNot(contains('combineAdjacentHourSlots(')));
      expect(detailCharts, isNot(contains('_recordLabel')));
      expect(detailCharts, contains('getTooltipColor'));
      expect(detailCharts, isNot(contains('tooltipBgColor')));
      expect(statisticsCharts, contains('buildStatisticsChartModel'));
      expect(statisticsCharts, isNot(contains('buildStatisticsSummary')));
      expect(
        statisticsCharts,
        isNot(contains('combineStatisticsAdjacentHourSlots')),
      );
      expect(statisticsCharts, isNot(contains('_maxStackHeight')));
      expect(statisticsCharts, contains('getTooltipColor'));
      expect(statisticsCharts, isNot(contains('tooltipBgColor')));
      expect(detailModel, isNot(contains('fl_chart')));
      expect(statisticsModel, isNot(contains('fl_chart')));
    },
  );

  test('activity editor uses the current RadioGroup selection interface', () {
    final editor = File('lib/eventEditor.dart').readAsStringSync();

    expect(editor, contains('RadioGroup<String>'));
    expect(editor, contains('RadioListTile<String>'));
    expect(editor, isNot(contains('onChanged: (String? val)')));
  });

  test(
    'heatmap calendar delegates geometry and level mapping to pure model',
    () {
      final calendar = File(
        'lib/heatmap_calendar/heatMap.dart',
      ).readAsStringSync();
      final blocks = File(
        'lib/heatmap_calendar/heatMapBuildingBlocks.dart',
      ).readAsStringSync();
      final model = File(
        'lib/heatmap_calendar/heatmap_calendar_model.dart',
      ).readAsStringSync();

      expect(calendar, contains('buildHeatMapCalendarModel'));
      expect(calendar, isNot(contains('class HeatMapCalendarState')));
      expect(calendar, isNot(contains('date2level')));
      expect(calendar, isNot(contains('nilTime')));
      expect(blocks, contains('HeatMapDayCell'));
      expect(blocks, isNot(contains('split2weeks')));
      expect(blocks, isNot(contains('DateTimeRange')));
      expect(model, isNot(contains("package:flutter")));
      expect(model, contains('class HeatMapCalendarModel'));
    },
  );

  test('activity description editing state stays in Riverpod', () {
    final editor = File(
      'lib/EventsDetails/activity_description_editor.dart',
    ).readAsStringSync();
    final providers = File(
      'lib/state/activity_detail_providers.dart',
    ).readAsStringSync();

    expect(editor, isNot(contains('ConsumerStatefulWidget')));
    expect(editor, isNot(contains('TextEditingController')));
    expect(editor, isNot(contains('setState(')));
    expect(editor, contains('activityDescriptionEditingProvider'));
    expect(providers, contains('activityDescriptionEditingProvider'));
  });

  test('activity editor draft choices stay in Riverpod', () {
    final editor = File('lib/eventEditor.dart').readAsStringSync();
    final providers = File(
      'lib/state/activity_editor_providers.dart',
    ).readAsStringSync();

    expect(editor, isNot(contains('ConsumerStatefulWidget')));
    expect(editor, isNot(contains('setState(')));
    expect(editor, contains('activityEditorCareTimeProvider'));
    expect(editor, contains('activityEditorSelectedUnitProvider'));
    expect(providers, contains('activityEditorCareTimeProvider'));
    expect(providers, contains('activityEditorSelectedUnitProvider'));
  });

  test('unit manager does not own text input state', () {
    final unitManager = File(
      'lib/UnitManager/unitsManagerPage.dart',
    ).readAsStringSync();
    final commonWidgets = File(
      'lib/common/commonWidget.dart',
    ).readAsStringSync();

    expect(unitManager, isNot(contains('ConsumerStatefulWidget')));
    expect(unitManager, isNot(contains('TextEditingController')));
    expect(unitManager, isNot(contains('setState(')));
    expect(commonWidgets, contains('TextEditingController'));
    expect(commonWidgets, contains('controller.dispose()'));
  });

  test(
    'database module does not expose record lifecycle convenience methods',
    () {
      final database = File(
        'lib/persistence/database/app_database.dart',
      ).readAsStringSync();

      expect(database, isNot(contains('class DBHandle')));
      expect(database, isNot(contains('factory DBHandle')));
      expect(database, isNot(contains('static final AppDatabase _db')));
      expect(database, isNot(contains('getRecordById')));
      expect(database, isNot(contains('getEventById')));

      for (final oldMethodName in [
        'addPlainRecordInDB',
        'startTimingRecordInDB',
        'stopTimingRecordInDB',
        'stopActiveTimingRecordInDB',
        'deleteActiveTimingRecordInDB',
        'deleteActiveTimingRecordForEventInDB',
        'getEventStartTime',
        'getEventSumTime',
        'getEventRecordsInRange',
        'getStartTime',
      ]) {
        expect(database, isNot(contains(oldMethodName)));
      }
    },
  );

  test('record lifecycle rebuilds aggregate snapshots from records', () {
    final lifecycle = File(
      'lib/persistence/record_lifecycle_store.dart',
    ).readAsStringSync();
    final aggregate = File(
      'lib/domain/activity_aggregate_totals.dart',
    ).readAsStringSync();

    expect(lifecycle, contains('_rebuildAggregateSnapshot'));
    expect(
      lifecycle,
      contains('ActivityAggregateSnapshot.fromCompletedRecords'),
    );
    expect(lifecycle, isNot(contains('activity.sumTime')));
    expect(lifecycle, isNot(contains('activity.sumVal')));
    expect(aggregate, contains('class ActivityAggregateRecord'));
    expect(aggregate, contains('class ActivityAggregateSnapshot'));
    expect(aggregate, contains('fromCompletedRecords'));
  });
}
