import '../domain/activity_models.dart';
import '../persistence/activity_repository.dart';

typedef ActivityValuePrompt = Future<double?> Function(String unit);

enum ActivityRecordingOutcome {
  changed,
  unchanged,
  canceledAccidentalTimedRecord,
}

class ActivityRecordingActions {
  ActivityRecordingActions(
    this._repository, {
    this.accidentalTimedRecordThreshold = const Duration(seconds: 5),
  });

  final ActivityRepository _repository;
  final Duration accidentalTimedRecordThreshold;

  Future<ActivityRecordingOutcome> record(
    BaseEventModel activity,
    DateTime recordedAt, {
    required ActivityValuePrompt requestValue,
  }) {
    if (activity is PlainEventModel) {
      return _addPlainRecord(activity, recordedAt, requestValue: requestValue);
    }

    if (activity is TimingEventModel) {
      if (activity.status == EventStatus.active) {
        return _stopTimedRecord(
          activity,
          recordedAt,
          requestValue: requestValue,
        );
      }

      return _startTimedRecord(activity, recordedAt);
    }

    return Future.value(ActivityRecordingOutcome.unchanged);
  }

  Future<ActivityRecordingOutcome> _addPlainRecord(
    PlainEventModel activity,
    DateTime recordedAt, {
    required ActivityValuePrompt requestValue,
  }) async {
    final value = await _valueForActivity(activity.unit, requestValue);
    if (value == null && activity.unit != null) {
      return ActivityRecordingOutcome.unchanged;
    }

    await _repository.addPlainRecord(activity.id, recordedAt, value: value);
    return ActivityRecordingOutcome.changed;
  }

  Future<ActivityRecordingOutcome> _startTimedRecord(
    TimingEventModel activity,
    DateTime startedAt,
  ) async {
    await _repository.startTimedRecord(activity.id, startedAt);
    return ActivityRecordingOutcome.changed;
  }

  Future<ActivityRecordingOutcome> _stopTimedRecord(
    TimingEventModel activity,
    DateTime stoppedAt, {
    required ActivityValuePrompt requestValue,
  }) async {
    final duration = stoppedAt.difference(activity.startTime!);
    if (duration < accidentalTimedRecordThreshold) {
      await _repository.cancelActiveTimedRecord(activity.id);
      return ActivityRecordingOutcome.canceledAccidentalTimedRecord;
    }

    final value = await _valueForActivity(activity.unit, requestValue);
    if (value == null && activity.unit != null) {
      return ActivityRecordingOutcome.unchanged;
    }

    await _repository.stopActiveTimedRecord(
      activity.id,
      stoppedAt,
      value: value,
    );
    return ActivityRecordingOutcome.changed;
  }

  Future<double?> _valueForActivity(
    String? unit,
    ActivityValuePrompt requestValue,
  ) {
    if (unit == null) {
      return Future.value(null);
    }

    return requestValue(unit);
  }
}
