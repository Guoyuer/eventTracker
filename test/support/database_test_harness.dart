import 'dart:io';

import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:event_tracker/persistence/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeDatabaseTestEnvironment() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

AppDatabase openTestDatabase() {
  return AppDatabase(executor: SqfliteQueryExecutor(path: inMemoryDatabasePath));
}

/// Opens a file-backed [AppDatabase] in a fresh temp directory that is deleted
/// on test teardown. Unlike the in-memory harness, a real file is required to
/// observe journaling PRAGMas applied in `beforeOpen`.
AppDatabase openFileBackedTestDatabase({
  required String prefix,
  required bool useWriteAheadLog,
}) {
  final directory = Directory.systemTemp.createTempSync(prefix);
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  return AppDatabase(
    executor: SqfliteQueryExecutor(path: p.join(directory.path, 'db.sqlite')),
    useWriteAheadLog: useWriteAheadLog,
  );
}
