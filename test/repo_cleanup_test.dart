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
