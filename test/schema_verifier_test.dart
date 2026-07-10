import 'package:drift_dev/api/migrations_native.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('a freshly created database matches the v6 schema snapshot', () async {
    final connection = await verifier.startAt(6);
    final db = AppDatabase(connection);

    await verifier.migrateAndValidate(db, 6);

    await db.close();
  });
}
