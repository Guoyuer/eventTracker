import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor defaultDatabaseExecutor() {
  return LazyDatabase(() async {
    if (usesExplicitDatabasePathOnPlatform(
      defaultTargetPlatform,
      isWeb: kIsWeb,
    )) {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      return SqfliteQueryExecutor(
        path: p.join(directory.path, 'db.sqlite'),
        logStatements: false,
      );
    }

    return SqfliteQueryExecutor.inDatabaseFolder(
      path: 'db.sqlite',
      logStatements: false,
    );
  });
}

@visibleForTesting
bool usesExplicitDatabasePathOnPlatform(
  TargetPlatform platform, {
  required bool isWeb,
}) {
  return !isWeb &&
      (platform == TargetPlatform.windows ||
          platform == TargetPlatform.linux ||
          platform == TargetPlatform.macOS);
}

/// Whether durable WAL journaling should be requested for the current platform.
///
/// WAL plus `synchronous = NORMAL` is applied on desktop, where drift reaches
/// SQLite through the FFI executor and connection-level PRAGMas run outside a
/// transaction. On mobile, drift_sqflite runs beforeOpen inside a transaction
/// where `PRAGMA journal_mode = WAL` throws, and sqflite manages journaling
/// itself, so WAL is left off there.
bool defaultUsesWriteAheadLog() =>
    usesExplicitDatabasePathOnPlatform(defaultTargetPlatform, isWeb: kIsWeb);
