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

/// These tests pump primary routes on a phone-narrow surface. A RenderFlex
/// overflow (the yellow/black debug stripe) is reported as a test failure
/// during layout, so a page that overflows here fails the test. This guards
/// the statistics date-range header, which previously overflowed on Android.
/// 320dp is tighter than the ~411dp width where the overflow originally showed.

Future<void> _pumpNarrow(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  // The header combines a fixed-format date range with a localized action
  // label, so the overflow risk is locale-dependent; cover both catalogs.
  for (final locale in const [Locale('en'), Locale('zh')]) {
    testWidgets(
      'statistics header fits a narrow ${locale.languageCode} screen',
      (tester) async {
        await _pumpNarrow(
          tester,
          ProviderScope(
            overrides: [
              statisticsRepositoryProvider.overrideWithValue(
                _EmptyStatisticsRepository(),
              ),
            ],
            child: localizedTestApp(
              locale: locale,
              home: const Scaffold(body: StatisticPage()),
            ),
          ),
        );

        // The full date range stays on screen (scaled down, not clipped),
        // so the year is still present regardless of locale.
        expect(find.textContaining('2026'), findsOneWidget);
      },
    );
  }

  testWidgets('activity list empty state fits a narrow screen', (tester) async {
    await _pumpNarrow(
      tester,
      ProviderScope(
        overrides: [
          activityReaderProvider.overrideWithValue(_EmptyActivityReader()),
        ],
        child: localizedTestApp(
          home: const Scaffold(body: ActivityListPage()),
        ),
      ),
    );

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
  Future<Activity> getActivity(int activityId) => throw UnimplementedError();

  @override
  Future<String?> getActivityDescription(int activityId) =>
      throw UnimplementedError();

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) =>
      throw UnimplementedError();
}
