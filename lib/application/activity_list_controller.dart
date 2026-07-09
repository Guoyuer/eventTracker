import '../domain/activity_models.dart';
import '../persistence/activity_repository.dart';
import 'activity_recording_actions.dart';
import 'activity_recording_controller.dart';

typedef ActivityListRefresh = void Function();
typedef ActivityDetailRoute = Future<bool?> Function(BaseEventModel activity);

class ActivityListController {
  ActivityListController({
    required ActivityRepository repository,
    required this.refresh,
    required ActivityNotification notify,
  }) : _recording = ActivityRecordingController(
         actions: ActivityRecordingActions(repository),
         refresh: refresh,
         notify: notify,
       );

  final ActivityListRefresh refresh;
  final ActivityRecordingController _recording;

  Future<void> recordActivity(
    BaseEventModel activity,
    DateTime recordedAt, {
    required ActivityValuePrompt requestValue,
  }) {
    return _recording.record(activity, recordedAt, requestValue: requestValue);
  }

  Future<void> showActivityDetail(
    BaseEventModel activity, {
    required ActivityDetailRoute showDetail,
  }) async {
    final deleted = await showDetail(activity);
    if (deleted == true) {
      refresh();
    }
  }
}
