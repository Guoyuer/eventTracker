import '../domain/activity_models.dart';
import '../domain/activity_repository.dart';

typedef ActivityListRefresh = void Function();
typedef ActivityNotification = void Function(String message);
typedef ActivityDetailRoute = Future<bool?> Function(BaseEventModel activity);
typedef ActivityValuePrompt = Future<double?> Function(String unit);

class ActivityListController {
  factory ActivityListController({
    required RecordLifecycle recordLifecycle,
    required ActivityListRefresh refresh,
    required ActivityNotification notify,
    Duration accidentalTimedRecordThreshold = const Duration(seconds: 5),
  }) {
    return ActivityListController._(
      recordLifecycle,
      refresh,
      notify,
      accidentalTimedRecordThreshold,
    );
  }

  ActivityListController._(
    this._recordLifecycle,
    this._refresh,
    this._notify,
    this.accidentalTimedRecordThreshold,
  );

  final RecordLifecycle _recordLifecycle;
  final ActivityListRefresh _refresh;
  final ActivityNotification _notify;
  final Duration accidentalTimedRecordThreshold;

  Future<void> recordActivity(
    BaseEventModel activity,
    DateTime recordedAt, {
    required ActivityValuePrompt requestValue,
  }) async {
    if (activity is PlainEventModel) {
      await _addPlainRecord(activity, recordedAt, requestValue);
      return;
    }

    if (activity is! TimingEventModel) {
      return;
    }

    if (activity.status == EventStatus.active) {
      await _stopTimedRecord(activity, recordedAt, requestValue);
      return;
    }

    await _recordLifecycle.startTimedRecord(activity.id, recordedAt);
    _refresh();
  }

  Future<void> showActivityDetail(
    BaseEventModel activity, {
    required ActivityDetailRoute showDetail,
  }) async {
    final deleted = await showDetail(activity);
    if (deleted == true) {
      _refresh();
    }
  }

  Future<void> _addPlainRecord(
    PlainEventModel activity,
    DateTime recordedAt,
    ActivityValuePrompt requestValue,
  ) async {
    final value = await _requestValue(activity.unit, requestValue);
    if (activity.unit != null && value == null) {
      return;
    }

    await _recordLifecycle.addPlainRecord(
      activity.id,
      recordedAt,
      value: value,
    );
    _refresh();
  }

  Future<void> _stopTimedRecord(
    TimingEventModel activity,
    DateTime stoppedAt,
    ActivityValuePrompt requestValue,
  ) async {
    final duration = stoppedAt.difference(activity.startTime!);
    if (duration < accidentalTimedRecordThreshold) {
      await _recordLifecycle.cancelActiveTimedRecord(activity.id);
      _refresh();
      _notify('已取消本次计时');
      return;
    }

    final value = await _requestValue(activity.unit, requestValue);
    if (activity.unit != null && value == null) {
      return;
    }

    await _recordLifecycle.stopActiveTimedRecord(
      activity.id,
      stoppedAt,
      value: value,
    );
    _refresh();
  }

  Future<double?> _requestValue(
    String? unit,
    ActivityValuePrompt requestValue,
  ) {
    return unit == null ? Future.value() : requestValue(unit);
  }
}
