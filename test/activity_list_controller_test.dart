import 'package:event_tracker/application/activity_list_controller.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/domain/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain activity records and refreshes without a value prompt', () async {
    final harness = _ActivityListHarness();
    final recordedAt = DateTime(2026, 1, 1, 8);

    await harness.controller.recordActivity(
      _plainActivity(),
      recordedAt,
      requestValue: (_) => throw StateError('value prompt should not open'),
    );

    expect(harness.records.plainRecords, [
      (activityId: 1, endTime: recordedAt, value: null),
    ]);
    expect(harness.refreshCount, 1);
    expect(harness.notifications, isEmpty);
  });

  test('plain activity records a prompted unit value', () async {
    final harness = _ActivityListHarness();
    final recordedAt = DateTime(2026, 1, 1, 8);

    await harness.controller.recordActivity(
      _plainActivity(unit: 'pages'),
      recordedAt,
      requestValue: (unit) async {
        expect(unit, 'pages');
        return 12;
      },
    );

    expect(harness.records.plainRecords, [
      (activityId: 1, endTime: recordedAt, value: 12),
    ]);
    expect(harness.refreshCount, 1);
  });

  test('canceling the value prompt leaves activity list unchanged', () async {
    final harness = _ActivityListHarness();

    await harness.controller.recordActivity(
      _plainActivity(unit: 'pages'),
      DateTime(2026, 1, 1, 8),
      requestValue: (_) async => null,
    );

    expect(harness.records.plainRecords, isEmpty);
    expect(harness.refreshCount, 0);
    expect(harness.notifications, isEmpty);
  });

  test('inactive timed activity starts and refreshes', () async {
    final harness = _ActivityListHarness();
    final startedAt = DateTime(2026, 1, 1, 8);

    await harness.controller.recordActivity(
      _timedActivity(status: EventStatus.notActive),
      startedAt,
      requestValue: (_) => throw StateError('value prompt should not open'),
    );

    expect(harness.records.startedRecords, [
      (activityId: 2, startTime: startedAt),
    ]);
    expect(harness.refreshCount, 1);
  });

  test('short active timer cancels and reports the accidental start', () async {
    final harness = _ActivityListHarness();
    final startTime = DateTime(2026, 1, 1, 8);

    await harness.controller.recordActivity(
      _timedActivity(status: EventStatus.active, startTime: startTime),
      startTime.add(const Duration(seconds: 4)),
      requestValue: (_) => throw StateError('value prompt should not open'),
    );

    expect(harness.records.canceledActivityIds, [2]);
    expect(harness.records.stoppedRecords, isEmpty);
    expect(harness.refreshCount, 1);
    expect(harness.notifications, ['已取消本次计时']);
  });

  test('timer at the threshold completes instead of canceling', () async {
    final harness = _ActivityListHarness();
    final startTime = DateTime(2026, 1, 1, 8);
    final stoppedAt = startTime.add(const Duration(seconds: 5));

    await harness.controller.recordActivity(
      _timedActivity(status: EventStatus.active, startTime: startTime),
      stoppedAt,
      requestValue: (_) => throw StateError('value prompt should not open'),
    );

    expect(harness.records.canceledActivityIds, isEmpty);
    expect(harness.records.stoppedRecords, [
      (activityId: 2, stoppedAt: stoppedAt, value: null),
    ]);
    expect(harness.refreshCount, 1);
  });

  test('active timed activity stops with a prompted value', () async {
    final harness = _ActivityListHarness();
    final startTime = DateTime(2026, 1, 1, 8);
    final stoppedAt = startTime.add(const Duration(minutes: 20));

    await harness.controller.recordActivity(
      _timedActivity(
        status: EventStatus.active,
        startTime: startTime,
        unit: 'km',
      ),
      stoppedAt,
      requestValue: (unit) async {
        expect(unit, 'km');
        return 4;
      },
    );

    expect(harness.records.stoppedRecords, [
      (activityId: 2, stoppedAt: stoppedAt, value: 4),
    ]);
    expect(harness.refreshCount, 1);
    expect(harness.notifications, isEmpty);
  });
}

class _ActivityListHarness {
  _ActivityListHarness() {
    controller = ActivityListController(
      recordLifecycle: records,
      refresh: () => refreshCount++,
      notify: notifications.add,
    );
  }

  final records = _FakeRecordLifecycle();
  late final ActivityListController controller;
  var refreshCount = 0;
  final notifications = <String>[];
}

PlainEventModel _plainActivity({String? unit}) {
  return PlainEventModel(1, 'Read', unit, 0, 0, null, null);
}

TimingEventModel _timedActivity({
  required EventStatus status,
  DateTime? startTime,
  String? unit,
}) {
  return TimingEventModel(
    2,
    'Run',
    unit,
    status,
    Duration.zero,
    startTime,
    0,
    null,
    null,
  );
}

class _FakeRecordLifecycle implements RecordLifecycle {
  final plainRecords = <({int activityId, DateTime endTime, double? value})>[];
  final startedRecords = <({int activityId, DateTime startTime})>[];
  final stoppedRecords =
      <({int activityId, DateTime stoppedAt, double? value})>[];
  final canceledActivityIds = <int>[];

  @override
  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  }) async {
    plainRecords.add((activityId: activityId, endTime: endTime, value: value));
  }

  @override
  Future<int> startTimedRecord(int activityId, DateTime startTime) async {
    startedRecords.add((activityId: activityId, startTime: startTime));
    return startedRecords.length;
  }

  @override
  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  }) async {
    stoppedRecords.add((
      activityId: activityId,
      stoppedAt: stoppedAt,
      value: value,
    ));
  }

  @override
  Future<void> cancelActiveTimedRecord(int activityId) async {
    canceledActivityIds.add(activityId);
  }
}
