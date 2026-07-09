import 'package:drift/drift.dart';

import '../domain/activity_models.dart';
import '../domain/unit_repository.dart';
import 'database/app_database.dart';

class DriftUnitRepository implements UnitRepository {
  DriftUnitRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ActivityUnit>> getUnits() async {
    final units = await _db.select(_db.units).get();
    return [
      for (final unit in units) ActivityUnit(id: unit.id, name: unit.name),
    ];
  }

  @override
  Future<int> addUnit(String name) {
    return _db.into(_db.units).insert(UnitsCompanion(name: Value(name)));
  }

  @override
  Future<void> deleteUnit(String name) {
    return (_db.delete(
      _db.units,
    )..where((unit) => unit.name.equals(name))).go();
  }
}
