import 'activity_models.dart';

abstract interface class UnitRepository {
  Future<List<ActivityUnit>> getUnits();

  Future<int> addUnit(String name);

  Future<void> deleteUnit(String name);
}
