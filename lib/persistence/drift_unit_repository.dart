import 'package:drift/drift.dart';

import '../domain/activity_failure.dart';
import '../domain/activity_models.dart';
import '../domain/input_validation.dart';
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
  Future<int> addUnit(String name) async {
    final normalizedName = normalizeRequiredName(name, field: 'unitName');
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.units,
      )..where((row) => row.name.equals(normalizedName))).getSingleOrNull();
      if (existing != null) {
        throw DuplicateUnitName(normalizedName);
      }

      return _db
          .into(_db.units)
          .insert(UnitsCompanion(name: Value(normalizedName)));
    });
  }

  @override
  Future<void> deleteUnit(String name) async {
    final normalizedName = normalizeRequiredName(name, field: 'unitName');
    await _db.transaction(() async {
      final unit = await (_db.select(
        _db.units,
      )..where((row) => row.name.equals(normalizedName))).getSingleOrNull();
      if (unit == null) {
        throw StateError('Unit $normalizedName does not exist');
      }
      final usage =
          await (_db.select(_db.events)
                ..where((activity) => activity.unitId.equals(unit.id)))
              .getSingleOrNull();
      if (usage != null) {
        throw UnitInUse(normalizedName);
      }
      await (_db.delete(
        _db.units,
      )..where((unit) => unit.name.equals(normalizedName))).go();
    });
  }
}
