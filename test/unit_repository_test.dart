import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:event_tracker/DAO/base.dart';
import 'package:event_tracker/persistence/unit_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase db;
  late UnitRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    db = AppDatabase(SqfliteQueryExecutor(path: inMemoryDatabasePath));
    repository = DriftUnitRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('repository adds and lists units without exposing database companions',
      () async {
    await repository.addUnit('pages');
    await repository.addUnit('minutes');

    final units = await repository.getUnits();

    expect(units.map((unit) => unit.name), ['pages', 'minutes']);
  });

  test('repository deletes a unit by name', () async {
    await repository.addUnit('pages');
    await repository.addUnit('minutes');

    await repository.deleteUnit('pages');

    final units = await repository.getUnits();
    expect(units.map((unit) => unit.name), ['minutes']);
  });

  test('repository keeps database uniqueness for unit names', () async {
    await repository.addUnit('pages');

    expect(repository.addUnit('pages'), throwsA(anything));
  });
}
