import 'package:drift/drift.dart';

import 'database/app_database.dart';

abstract class UnitRepository {
  Future<List<Unit>> getUnits();

  Future<int> addUnit(String name);

  Future<void> deleteUnit(String name);
}

class DriftUnitRepository implements UnitRepository {
  DriftUnitRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Unit>> getUnits() {
    return _db.getAllUnits();
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
