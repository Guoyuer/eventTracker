import 'package:event_tracker/activities/activity_editor_page.dart';
import 'package:event_tracker/domain/activity_failure.dart';
import 'package:event_tracker/domain/activity_repository.dart';
import 'package:event_tracker/persistence/persistence_providers.dart';
import 'package:event_tracker/state/unit_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

void main() {
  testWidgets('duplicate activity name keeps the editor route open', (
    tester,
  ) async {
    final writer = _DuplicateActivityWriter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityWriterProvider.overrideWithValue(writer),
          unitListProvider.overrideWith((_) async => []),
        ],
        child: localizedTestApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ActivityEditorPage()),
                );
              },
              child: const Text('open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Read');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(writer.createAttempts, 1);
    expect(find.byType(ActivityEditorPage), findsOneWidget);
  });
}

class _DuplicateActivityWriter implements ActivityWriter {
  var createAttempts = 0;

  @override
  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  }) async {
    createAttempts++;
    throw const DuplicateActivityName('Read');
  }

  @override
  Future<void> deleteActivity(int activityId) async {}

  @override
  Future<void> updateActivityDescription(
    int activityId,
    String description,
  ) async {}
}
