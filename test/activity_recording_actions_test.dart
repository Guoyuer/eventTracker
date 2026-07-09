import 'package:event_tracker/application/activity_recording_actions.dart';
import 'package:event_tracker/application/activity_recording_controller.dart';
import 'package:event_tracker/domain/activity_models.dart';
import 'package:event_tracker/persistence/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'plain activity records immediately when no unit value is needed',
    () async {
      final repository = _FakeActivityRepository();
      final recorder = ActivityRecordingActions(repository);
      final recordedAt = DateTime(2026, 1, 1, 8);

      final outcome = await recorder.record(
        _plainActivity(unit: null),
        recordedAt,
        requestValue: (_) => throw StateError('value prompt should not open'),
      );

      expect(outcome, ActivityRecordingOutcome.changed);
      expect(repository.plainRecords, [
        _PlainRecord(activityId: 1, endTime: recordedAt),
      ]);
    },
  );

  test(
    'plain activity asks for a value when the activity has a unit',
    () async {
      final repository = _FakeActivityRepository();
      final recorder = ActivityRecordingActions(repository);
      final recordedAt = DateTime(2026, 1, 1, 8);

      final outcome = await recorder.record(
        _plainActivity(unit: 'pages'),
        recordedAt,
        requestValue: (unit) async {
          expect(unit, 'pages');
          return 12;
        },
      );

      expect(outcome, ActivityRecordingOutcome.changed);
      expect(repository.plainRecords, [
        _PlainRecord(activityId: 1, endTime: recordedAt, value: 12),
      ]);
    },
  );

  test('canceling the value prompt leaves repository unchanged', () async {
    final repository = _FakeActivityRepository();
    final recorder = ActivityRecordingActions(repository);

    final outcome = await recorder.record(
      _plainActivity(unit: 'pages'),
      DateTime(2026, 1, 1, 8),
      requestValue: (_) async => null,
    );

    expect(outcome, ActivityRecordingOutcome.unchanged);
    expect(repository.plainRecords, isEmpty);
    expect(repository.stoppedTimedRecords, isEmpty);
  });

  test('inactive timed activity starts a timed record', () async {
    final repository = _FakeActivityRepository();
    final recorder = ActivityRecordingActions(repository);
    final startedAt = DateTime(2026, 1, 1, 8);

    final outcome = await recorder.record(
      _timedActivity(status: EventStatus.notActive),
      startedAt,
      requestValue: (_) => throw StateError('value prompt should not open'),
    );

    expect(outcome, ActivityRecordingOutcome.changed);
    expect(repository.startedTimedRecords, [
      _TimedStart(activityId: 2, startTime: startedAt),
    ]);
  });

  test(
    'active timed activity under threshold cancels accidental record',
    () async {
      final repository = _FakeActivityRepository();
      final recorder = ActivityRecordingActions(repository);
      final startTime = DateTime(2026, 1, 1, 8);

      final outcome = await recorder.record(
        _timedActivity(status: EventStatus.active, startTime: startTime),
        startTime.add(const Duration(seconds: 4)),
        requestValue: (_) => throw StateError('value prompt should not open'),
      );

      expect(outcome, ActivityRecordingOutcome.canceledAccidentalTimedRecord);
      expect(repository.canceledTimedActivityIds, [2]);
      expect(repository.stoppedTimedRecords, isEmpty);
    },
  );

  test(
    'active timed activity over threshold stops with prompted value',
    () async {
      final repository = _FakeActivityRepository();
      final recorder = ActivityRecordingActions(repository);
      final startTime = DateTime(2026, 1, 1, 8);
      final stoppedAt = startTime.add(const Duration(minutes: 20));

      final outcome = await recorder.record(
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

      expect(outcome, ActivityRecordingOutcome.changed);
      expect(repository.stoppedTimedRecords, [
        _TimedStop(activityId: 2, stoppedAt: stoppedAt, value: 4),
      ]);
    },
  );

  test('recording controller refreshes changed activity lists', () async {
    final repository = _FakeActivityRepository();
    final harness = _ControllerHarness(repository);
    final recordedAt = DateTime(2026, 1, 1, 8);

    await harness.controller.record(
      _plainActivity(unit: null),
      recordedAt,
      requestValue: (_) => throw StateError('value prompt should not open'),
    );

    expect(harness.refreshCount, 1);
    expect(harness.notifications, isEmpty);
  });

  test(
    'recording controller reports canceled accidental timed records',
    () async {
      final repository = _FakeActivityRepository();
      final harness = _ControllerHarness(repository);
      final startTime = DateTime(2026, 1, 1, 8);

      await harness.controller.record(
        _timedActivity(status: EventStatus.active, startTime: startTime),
        startTime.add(const Duration(seconds: 4)),
        requestValue: (_) => throw StateError('value prompt should not open'),
      );

      expect(harness.refreshCount, 1);
      expect(harness.notifications, ['已取消本次计时']);
    },
  );

  test('recording controller leaves unchanged outcomes quiet', () async {
    final repository = _FakeActivityRepository();
    final harness = _ControllerHarness(repository);

    await harness.controller.record(
      _plainActivity(unit: 'pages'),
      DateTime(2026, 1, 1, 8),
      requestValue: (_) async => null,
    );

    expect(harness.refreshCount, 0);
    expect(harness.notifications, isEmpty);
  });
}

class _ControllerHarness {
  _ControllerHarness(_FakeActivityRepository repository) {
    controller = ActivityRecordingController(
      actions: ActivityRecordingActions(repository),
      refresh: () => refreshCount++,
      notify: notifications.add,
    );
  }

  late final ActivityRecordingController controller;
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

class _FakeActivityRepository implements ActivityRepository {
  final List<_PlainRecord> plainRecords = [];
  final List<_TimedStart> startedTimedRecords = [];
  final List<_TimedStop> stoppedTimedRecords = [];
  final List<int> canceledTimedActivityIds = [];

  @override
  Future<List<BaseEventModel>> getActivities() {
    throw UnimplementedError();
  }

  @override
  Future<List<ActivityRecord>> getActivityRecords(int activityId) {
    throw UnimplementedError();
  }

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
  Future<String?> getActivityDescription(int activityId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateActivityDescription(int activityId, String description) {
    throw UnimplementedError();
  }

  @override
  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  }) async {
    plainRecords.add(
      _PlainRecord(activityId: activityId, endTime: endTime, value: value),
    );
  }

  @override
  Future<int> startTimedRecord(int activityId, DateTime startTime) async {
    startedTimedRecords.add(
      _TimedStart(activityId: activityId, startTime: startTime),
    );
    return 1;
  }

  @override
  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  }) async {
    stoppedTimedRecords.add(
      _TimedStop(activityId: activityId, stoppedAt: stoppedAt, value: value),
    );
  }

  @override
  Future<void> cancelActiveTimedRecord(int activityId) async {
    canceledTimedActivityIds.add(activityId);
  }

  @override
  Future<void> deleteActivity(int activityId) {
    throw UnimplementedError();
  }

  @override
  Future<void> repairAggregateTotals() {
    throw UnimplementedError();
  }
}

class _PlainRecord {
  const _PlainRecord({
    required this.activityId,
    required this.endTime,
    this.value,
  });

  final int activityId;
  final DateTime endTime;
  final double? value;

  @override
  bool operator ==(Object other) {
    return other is _PlainRecord &&
        other.activityId == activityId &&
        other.endTime == endTime &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(activityId, endTime, value);
}

class _TimedStart {
  const _TimedStart({required this.activityId, required this.startTime});

  final int activityId;
  final DateTime startTime;

  @override
  bool operator ==(Object other) {
    return other is _TimedStart &&
        other.activityId == activityId &&
        other.startTime == startTime;
  }

  @override
  int get hashCode => Object.hash(activityId, startTime);
}

class _TimedStop {
  const _TimedStop({
    required this.activityId,
    required this.stoppedAt,
    this.value,
  });

  final int activityId;
  final DateTime stoppedAt;
  final double? value;

  @override
  bool operator ==(Object other) {
    return other is _TimedStop &&
        other.activityId == activityId &&
        other.stoppedAt == stoppedAt &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(activityId, stoppedAt, value);
}
