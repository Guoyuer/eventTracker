import '../domain/activity_repository.dart';

class ActivityDetailController {
  ActivityDetailController(this._repository);

  final ActivityWriter _repository;

  Future<void> deleteActivity(int activityId) {
    return _repository.deleteActivity(activityId);
  }

  Future<void> saveDescription(int activityId, String description) {
    return _repository.updateActivityDescription(activityId, description);
  }
}
