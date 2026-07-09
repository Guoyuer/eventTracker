import 'package:event_tracker/EventsDetails/activity_description_editor.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/persistence/activity_repository.dart';
import 'package:event_tracker/stateProviders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'description editor loads and updates through repository provider',
      (tester) async {
    final repository = _FakeActivityRepository(description: 'Initial');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivityDescriptionEditor(activityId: 7),
          ),
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
  });
}

class _FakeActivityRepository implements ActivityRepository {
  _FakeActivityRepository({String? description}) : _description = description;

  String? _description;
  final Map<int, String> updatedDescriptions = {};

  @override
  Future<List<BaseEventModel>> getActivities() async => [];

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) async => [];

  @override
  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  }) {
    throw UnimplementedError();
  }

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
  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> startTimedRecord(int activityId, DateTime startTime) {
    throw UnimplementedError();
  }

  @override
  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelActiveTimedRecord(int activityId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteActivity(int activityId) {
    throw UnimplementedError();
  }
}
