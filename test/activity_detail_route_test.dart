import 'package:event_tracker/EventsDetails/activity_detail_page.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/domain/activity_repository.dart';
import 'package:event_tracker/persistence/persistence_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

void main() {
  testWidgets('detail route reloads its Activity Snapshot by id', (
    tester,
  ) async {
    final reader = _FakeActivityReader(
      const PlainActivity(
        id: 7,
        name: 'Read',
        description: 'Books',
        occurrenceCount: 0,
        totalValue: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityReaderProvider.overrideWithValue(reader),
          activityWriterProvider.overrideWithValue(_FakeActivityWriter()),
        ],
        child: localizedTestApp(
          routes: {'EventDetails': (_) => const EventDetailsWrapper()},
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed('EventDetails', arguments: 7),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(reader.requestedActivityIds, [7]);
    expect(find.text('Read - Activity details'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('No records yet'), findsOneWidget);
  });
}

class _FakeActivityReader implements ActivityReader {
  _FakeActivityReader(this.activity);

  final Activity activity;
  final requestedActivityIds = <int>[];

  @override
  Future<List<Activity>> getActivities() async => [activity];

  @override
  Future<Activity> getActivity(int activityId) async {
    requestedActivityIds.add(activityId);
    return activity;
  }

  @override
  Future<String?> getActivityDescription(int activityId) async {
    return activity.description;
  }

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) async => [];
}

class _FakeActivityWriter implements ActivityWriter {
  @override
  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  }) async => 1;

  @override
  Future<void> deleteActivity(int activityId) async {}

  @override
  Future<void> updateActivityDescription(
    int activityId,
    String description,
  ) async {}
}
