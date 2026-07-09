import '../persistence/activity_repository.dart';

typedef ActivityDeleteConfirmation = Future<bool> Function();
typedef ActivityDetailExit = void Function(bool deleted);
typedef ActivityDescriptionRefresh = void Function();
typedef ActivityDescriptionEditingExit = void Function();

class ActivityDetailController {
  ActivityDetailController({required ActivityRepository repository})
    : this._(repository);

  ActivityDetailController._(this._repository);

  final ActivityRepository _repository;

  Future<bool> deleteActivity(
    int activityId, {
    required ActivityDeleteConfirmation confirmDelete,
  }) async {
    final confirmed = await confirmDelete();
    if (!confirmed) {
      return false;
    }

    await _repository.deleteActivity(activityId);
    return true;
  }

  Future<void> deleteActivityAndExit(
    int activityId, {
    required ActivityDeleteConfirmation confirmDelete,
    required ActivityDetailExit exitDetail,
  }) async {
    final deleted = await deleteActivity(
      activityId,
      confirmDelete: confirmDelete,
    );
    if (deleted) {
      exitDetail(true);
    }
  }

  Future<void> saveDescription(
    int activityId,
    String description, {
    required ActivityDescriptionRefresh refresh,
    required ActivityDescriptionEditingExit exitEditing,
  }) async {
    await _repository.updateActivityDescription(activityId, description);
    refresh();
    exitEditing();
  }
}
