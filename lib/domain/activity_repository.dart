import 'activity_models.dart';

abstract interface class ActivityReader {
  Future<List<Activity>> getActivities();

  Future<Activity> getActivity(int activityId);

  Future<List<ActivityRecord>> getActivityRecords(int activityId);

  Future<String?> getActivityDescription(int activityId);
}

abstract interface class ActivityWriter {
  Future<int> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  });

  Future<void> updateActivityDescription(int activityId, String description);

  Future<void> deleteActivity(int activityId);
}

abstract interface class RecordLifecycle {
  Future<void> addPlainRecord(
    int activityId,
    DateTime endTime, {
    double? value,
  });

  Future<int> startTimedRecord(int activityId, DateTime startTime);

  Future<void> stopActiveTimedRecord(
    int activityId,
    DateTime stoppedAt, {
    double? value,
  });

  Future<void> cancelActiveTimedRecord(int activityId);
}

abstract interface class ActivityRepository
    implements ActivityReader, ActivityWriter, RecordLifecycle {
  Future<void> repairAggregateTotals();
}
