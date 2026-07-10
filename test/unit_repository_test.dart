import 'package:drift/drift.dart';
import 'package:event_tracker/domain/activity_failure.dart';
import 'package:event_tracker/domain/unit_repository.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:event_tracker/persistence/drift_unit_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/database_test_harness.dart';

void main() {
  late AppDatabase db;
  late UnitRepository repository;

  setUpAll(() {
    initializeDatabaseTestEnvironment();
  });

  setUp(() {
    db = openTestDatabase();
    repository = DriftUnitRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'repository adds and lists units without exposing database companions',
    () async {
      await repository.addUnit('pages');
      await repository.addUnit('minutes');

      final units = await repository.getUnits();

      expect(units.map((unit) => unit.name), ['pages', 'minutes']);
    },
  );

  test('repository deletes a unit by name', () async {
    await repository.addUnit('pages');
    await repository.addUnit('minutes');

    await repository.deleteUnit('pages');

    final units = await repository.getUnits();
    expect(units.map((unit) => unit.name), ['minutes']);
  });

  test('repository reports a typed failure for duplicate unit names', () async {
    await repository.addUnit('pages');

    expect(
      repository.addUnit(' PAGES '),
      throwsA(
        isA<DuplicateUnitName>().having(
          (failure) => failure.name,
          'name',
          'PAGES',
        ),
      ),
    );
  });

  test('repository normalizes names and rejects blank units', () async {
    await repository.addUnit('  pages  ');

    expect((await repository.getUnits()).single.name, 'pages');
    expect(repository.addUnit('   '), throwsArgumentError);
  });

  test('repository refuses to delete a Unit used by an Activity', () async {
    await repository.addUnit('pages');
    final unit = (await repository.getUnits()).single;
    await db
        .into(db.events)
        .insert(
          EventsCompanion(
            name: const Value('Read'),
            careTime: const Value(false),
            unitId: Value(unit.id),
          ),
        );

    expect(
      repository.deleteUnit('pages'),
      throwsA(
        isA<UnitInUse>().having((failure) => failure.name, 'name', 'pages'),
      ),
    );
    expect((await repository.getUnits()).single.name, 'pages');
  });
}
