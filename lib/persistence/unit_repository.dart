import 'package:drift/drift.dart';

import '../domain/activity_models.dart';
import 'database/app_database.dart';

abstract class UnitRepository {
  Future<List<ActivityUnit>> getUnits();

  Future<int> addUnit(String name);

  Future<void> deleteUnit(String name);
}

class DriftUnitRepository implements UnitRepository {
  DriftUnitRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ActivityUnit>> getUnits() async {
    final units = await _db.getAllUnits();
    return [
      for (final unit in units) ActivityUnit(id: unit.id, name: unit.name),
    ];
  }

  @override
  Future<int> addUnit(String name) {
    return _db.addUnit(UnitsCompanion(name: Value(name)));
  }

  @override
  Future<void> deleteUnit(String name) {
    return _db.deleteUnitByName(name);
  }
}

UnitRepository unitRepository() {
  return DriftUnitRepository(DBHandle().db);
}
