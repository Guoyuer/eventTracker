import '../domain/activity_models.dart';
import 'activity_recording_actions.dart';

typedef ActivityListRefresh = void Function();
typedef ActivityNotification = void Function(String message);

class ActivityRecordingController {
  ActivityRecordingController({
    required ActivityRecordingActions actions,
    required ActivityListRefresh refresh,
    required ActivityNotification notify,
  })  : _actions = actions,
        _refresh = refresh,
        _notify = notify;

  final ActivityRecordingActions _actions;
  final ActivityListRefresh _refresh;
  final ActivityNotification _notify;

  Future<void> record(
    BaseEventModel activity,
    DateTime recordedAt, {
    required ActivityValuePrompt requestValue,
  }) async {
    final outcome = await _actions.record(
      activity,
      recordedAt,
      requestValue: requestValue,
    );

    switch (outcome) {
      case ActivityRecordingOutcome.changed:
        _refresh();
        break;
      case ActivityRecordingOutcome.canceledAccidentalTimedRecord:
        _refresh();
        _notify('已取消本次计时');
        break;
      case ActivityRecordingOutcome.unchanged:
        break;
    }
  }
}
