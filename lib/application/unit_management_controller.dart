import '../domain/activity_failure.dart';
import '../domain/unit_repository.dart';
import 'activity_messages.dart';

typedef UnitListRefresh = void Function();
typedef UnitNotification = void Function(String message);
typedef UnitDeleteConfirmation = Future<bool> Function();

class UnitManagementController {
  UnitManagementController({
    required UnitRepository repository,
    required ActivityMessages messages,
    required UnitListRefresh refresh,
    required UnitNotification notify,
  }) : this._(repository, messages, refresh, notify);

  UnitManagementController._(
    this._repository,
    this._messages,
    this._refresh,
    this._notify,
  );

  final UnitRepository _repository;
  final ActivityMessages _messages;
  final UnitListRefresh _refresh;
  final UnitNotification _notify;

  Future<bool> addUnit(String name) async {
    try {
      await _repository.addUnit(name);
      _refresh();
      return true;
    } on DuplicateUnitName catch (failure) {
      _notify(_messages.duplicateUnitName(failure.name));
      return false;
    }
  }

  Future<bool> deleteUnit(
    String name, {
    required UnitDeleteConfirmation confirmDelete,
  }) async {
    final confirmed = await confirmDelete();
    if (!confirmed) {
      return false;
    }

    try {
      await _repository.deleteUnit(name);
      _refresh();
      return true;
    } on UnitInUse catch (failure) {
      _notify(_messages.unitInUse(failure.name));
      _refresh();
      return false;
    }
  }
}
