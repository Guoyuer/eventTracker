import '../domain/activity_repository.dart';

typedef ActivityEditorNotification = void Function(String message);
typedef ActivityEditorExit = void Function(bool created);

class ActivityEditorController {
  ActivityEditorController({
    required ActivityWriter repository,
    required ActivityEditorNotification notify,
  }) : this._(repository, notify);

  ActivityEditorController._(this._repository, this._notify);

  final ActivityWriter _repository;
  final ActivityEditorNotification _notify;

  Future<bool> createActivity({
    required String name,
    required bool careTime,
    String? unit,
    String? description,
  }) async {
    try {
      await _repository.createActivity(
        name: name,
        unit: unit,
        description: description,
        careTime: careTime,
      );
      return true;
    } catch (_) {
      _notify('添加失败，可能是因为项目名重复！');
      return false;
    }
  }

  Future<void> createActivityAndExit({
    required String name,
    required bool careTime,
    required ActivityEditorExit exitEditor,
    String? unit,
    String? description,
  }) async {
    final created = await createActivity(
      name: name,
      unit: unit,
      description: description,
      careTime: careTime,
    );
    if (created) {
      exitEditor(true);
    }
  }
}
