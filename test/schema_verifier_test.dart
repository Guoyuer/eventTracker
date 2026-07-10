import 'package:drift_dev/api/migrations_native.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // Every version with a generated snapshot must migrate structurally to the
  // current schema. Driving this off GeneratedHelper.versions means a new
  // schema version is covered as soon as its snapshot is generated
  // (`tool/schema.ps1`), with no hand-added case here. The latest version
  // migrating to itself doubles as the fresh-create check.
  final versions = GeneratedHelper.versions;
  final latest = versions.last;

  for (final from in versions) {
    final label = from == latest
        ? 'a freshly created database matches the v$latest schema snapshot'
        : 'v$from schema upgrades structurally to v$latest';
    test(label, () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase(connection);

      await verifier.migrateAndValidate(db, latest);

      await db.close();
    });
  }
}
