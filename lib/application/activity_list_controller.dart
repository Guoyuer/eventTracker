import '../domain/activity_models.dart';
import '../domain/activity_repository.dart';

typedef ActivityListRefresh = void Function();
typedef ActivityNotification = void Function(String message);
typedef ActivityDetailRoute = Future<bool?> Function(int activityId);
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
    Activity activity,
    DateTime recordedAt, {
    required ActivityValuePrompt requestValue,
  }) async {
    switch (activity) {
      case PlainActivity():
        await _addPlainRecord(activity, recordedAt, requestValue);
      case ActiveTimedActivity():
        await _stopTimedRecord(activity, recordedAt, requestValue);
      case InactiveTimedActivity():
        await _recordLifecycle.startTimedRecord(activity.id, recordedAt);
        _refresh();
    }
  }

  Future<void> showActivityDetail(
    int activityId, {
    required ActivityDetailRoute showDetail,
  }) async {
    final deleted = await showDetail(activityId);
    if (deleted == true) {
      _refresh();
    }
  }

  Future<void> _addPlainRecord(
    PlainActivity activity,
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
    ActiveTimedActivity activity,
    DateTime stoppedAt,
    ActivityValuePrompt requestValue,
  ) async {
    final duration = stoppedAt.difference(activity.startedAt);
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
