import 'package:event_tracker/activities/activity_description_editor.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/domain/activity_repository.dart';
import 'package:event_tracker/persistence/persistence_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

void main() {
  testWidgets(
    'description editor loads and updates through repository provider',
    (tester) async {
      final repository = _FakeActivityAccess(description: 'Initial');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityReaderProvider.overrideWithValue(repository),
            activityWriterProvider.overrideWithValue(repository),
          ],
          child: localizedTestApp(
            home: Scaffold(body: ActivityDescriptionEditor(activityId: 7)),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Initial'), findsOneWidget);

      await tester.tap(find.text('Initial'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'Updated');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();

      expect(repository.updatedDescriptions, {7: 'Updated'});
      expect(find.text('Updated'), findsOneWidget);
    },
  );
}

class _FakeActivityAccess implements ActivityReader, ActivityWriter {
  _FakeActivityAccess({String? description}) : this._(description);

  _FakeActivityAccess._(this._description);

  String? _description;
  final Map<int, String> updatedDescriptions = {};

  @override
  Future<List<Activity>> getActivities() async => [];

  @override
  Future<Activity> getActivity(int activityId) async {
    return PlainActivity(
      id: activityId,
      name: 'Test',
      description: _description,
      occurrenceCount: 0,
      totalValue: 0,
    );
  }

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) async => [];

  @override
  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  }) async => 0;

  @override
  Future<String?> getActivityDescription(int activityId) async {
    return _description;
  }

  @override
  Future<void> updateActivityDescription(
    int activityId,
    String description,
  ) async {
    _description = description;
    updatedDescriptions[activityId] = description;
  }

  @override
  Future<void> deleteActivity(int activityId) async {}
}
