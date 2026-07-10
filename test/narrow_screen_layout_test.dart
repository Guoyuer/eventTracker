import 'package:event_tracker/activities/activity_list_page.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/domain/activity_repository.dart';
import 'package:event_tracker/domain/date_range.dart';
import 'package:event_tracker/domain/statistics_repository.dart';
import 'package:event_tracker/persistence/persistence_providers.dart';
import 'package:event_tracker/statistics/statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

/// These tests pump primary routes on phone-narrow surfaces. A RenderFlex
/// overflow (the yellow/black debug stripe) is reported as a test failure
/// during layout, so a page that overflows here fails the test. This guards
/// the statistics date-range header, which previously overflowed on Android.

void _useNarrowScreen(WidgetTester tester, {double width = 320, double height = 640}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('statistics page fits a narrow screen without overflow', (
    tester,
  ) async {
    _useNarrowScreen(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statisticsRepositoryProvider.overrideWithValue(
            _EmptyStatisticsRepository(),
          ),
        ],
        child: localizedTestApp(
          home: const Scaffold(body: StatisticPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The date-range text and its action button both render; the row that
    // previously overflowed must lay out cleanly on a narrow screen.
    expect(find.text('Change range'), findsOneWidget);
    expect(find.text('No records yet'), findsOneWidget);
  });

  testWidgets('activity list empty state fits a narrow screen', (tester) async {
    _useNarrowScreen(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityReaderProvider.overrideWithValue(_EmptyActivityReader()),
        ],
        child: localizedTestApp(
          home: const Scaffold(body: ActivityListPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No activities yet'), findsOneWidget);
  });
}

class _EmptyStatisticsRepository implements StatisticsRepository {
  @override
  Future<StatisticsData> getStatisticsData(CalendarDateRange range) async {
    return StatisticsData(records: const [], activitiesById: const {});
  }
}

class _EmptyActivityReader implements ActivityReader {
  @override
  Future<List<Activity>> getActivities() async => const [];

  @override
  Future<Activity> getActivity(int activityId) =>
      throw UnimplementedError();

  @override
  Future<String?> getActivityDescription(int activityId) =>
      throw UnimplementedError();

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) =>
      throw UnimplementedError();
}
