import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removed prototype files and dependencies stay removed', () {
    expect(File('lib/addFakeData.dart').existsSync(), isFalse);
    expect(File('lib/StepCount/stepStatistics.dart').existsSync(), isFalse);

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

  test('legacy step schema stays retired from active Drift schema', () {
    final tables =
        File('lib/persistence/database/tables.dart').readAsStringSync();
    final database =
        File('lib/persistence/database/app_database.dart').readAsStringSync();
    final sql = File('lib/persistence/database/sql.moor').readAsStringSync();

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
          source, isNot(contains("../persistence/database/app_database.dart")));
      expect(source, isNot(contains("List<Record")));
      expect(source, isNot(contains("Map<int, Event")));
    }
  });

  test('ui state does not import the Drift database module directly', () {
    for (final path in [
      'lib/stateProviders.dart',
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

  test('ui widgets use repository providers instead of repository factories',
      () {
    for (final path in [
      'lib/EventsList/eventsList.dart',
      'lib/EventsList/util.dart',
      'lib/eventEditor.dart',
      'lib/UnitManager/unitsManagerPage.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(source, isNot(contains('activityRepository()')));
      expect(source, isNot(contains('unitRepository()')));
      expect(source, isNot(contains('statisticsRepository()')));
    }
  });

  test('activity list does not expose incomplete manual time entry controls',
      () {
    final activityList =
        File('lib/EventsList/eventsList.dart').readAsStringSync();

    expect(activityList, isNot(contains('showTimePicker')));
    expect(activityList, isNot(contains('手动指定')));
  });

  test('activity tiles keep ticking state outside the whole tile widget', () {
    final activityList =
        File('lib/EventsList/eventsList.dart').readAsStringSync();
    final providers = File('lib/stateProviders.dart').readAsStringSync();

    expect(activityList,
        isNot(contains('class EventTile extends ConsumerStatefulWidget')));
    expect(activityList, isNot(contains('Timer.periodic')));
    expect(activityList, isNot(contains('class _LapsedTimeStrState')));
    expect(activityList, contains('class ActiveTimingHighlight'));
    expect(
        activityList, contains('class LapsedTimeStr extends ConsumerWidget'));
    expect(providers, contains('elapsedDurationProvider'));
  });

  test('statistics page keeps selected range in Riverpod state', () {
    final statistics =
        File('lib/Statistics/statistics.dart').readAsStringSync();
    final providers = File('lib/stateProviders.dart').readAsStringSync();

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
    final details =
        File('lib/EventsDetails/eventDetails.dart').readAsStringSync();
    final charts = File('lib/EventsDetails/activity_detail_charts.dart')
        .readAsStringSync();

    expect(details, isNot(contains('fl_chart')));
    expect(details, isNot(contains('HeatMapCalendar')));
    expect(details, isNot(contains('activity_detail_analytics.dart')));
    expect(details, isNot(contains('ConsumerStatefulWidget')));
    expect(details, contains('ActivityDetailCharts'));
    expect(charts, contains('fl_chart'));
    expect(charts, contains('HeatMapCalendar'));
    expect(charts, contains('buildActivityHeatmapSeries'));
  });

  test('activity description editing state stays in Riverpod', () {
    final editor = File('lib/EventsDetails/activity_description_editor.dart')
        .readAsStringSync();
    final providers = File('lib/stateProviders.dart').readAsStringSync();

    expect(editor, isNot(contains('ConsumerStatefulWidget')));
    expect(editor, isNot(contains('TextEditingController')));
    expect(editor, isNot(contains('setState(')));
    expect(editor, contains('activityDescriptionEditingProvider'));
    expect(providers, contains('activityDescriptionEditingProvider'));
  });

  test('activity editor draft choices stay in Riverpod', () {
    final editor = File('lib/eventEditor.dart').readAsStringSync();
    final providers = File('lib/stateProviders.dart').readAsStringSync();

    expect(editor, isNot(contains('ConsumerStatefulWidget')));
    expect(editor, isNot(contains('setState(')));
    expect(editor, contains('activityEditorCareTimeProvider'));
    expect(editor, contains('activityEditorSelectedUnitProvider'));
    expect(providers, contains('activityEditorCareTimeProvider'));
    expect(providers, contains('activityEditorSelectedUnitProvider'));
  });

  test('database module does not expose record lifecycle convenience methods',
      () {
    final database =
        File('lib/persistence/database/app_database.dart').readAsStringSync();

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
  });
}
