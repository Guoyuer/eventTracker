import '../domain/activity_failure.dart';
import '../domain/activity_repository.dart';
import 'activity_messages.dart';

typedef ActivityEditorNotification = void Function(String message);
typedef ActivityEditorExit = void Function(bool created);

class ActivityEditorController {
  ActivityEditorController({
    required ActivityWriter repository,
    required ActivityMessages messages,
    required ActivityEditorNotification notify,
  }) : this._(repository, messages, notify);

  ActivityEditorController._(this._repository, this._messages, this._notify);

  final ActivityWriter _repository;
  final ActivityMessages _messages;
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
    } on DuplicateActivityName catch (failure) {
      _notify(_messages.duplicateActivityName(failure.name));
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
