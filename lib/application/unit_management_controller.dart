import '../persistence/unit_repository.dart';

typedef UnitListRefresh = void Function();
typedef UnitNotification = void Function(String message);
typedef UnitDeleteConfirmation = Future<bool> Function();

class UnitManagementController {
  UnitManagementController({
    required UnitRepository repository,
    required UnitListRefresh refresh,
    required UnitNotification notify,
  }) : this._(repository, refresh, notify);

  UnitManagementController._(this._repository, this._refresh, this._notify);

  final UnitRepository _repository;
  final UnitListRefresh _refresh;
  final UnitNotification _notify;

  Future<bool> addUnit(String name) async {
    try {
      await _repository.addUnit(name);
      _refresh();
      return true;
    } catch (_) {
      _notify('添加失败，可能是因为重复');
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
    } catch (_) {
      _notify('删除失败');
      _refresh();
      return false;
    }
  }
}
