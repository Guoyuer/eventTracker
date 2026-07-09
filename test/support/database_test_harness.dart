import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:event_tracker/DAO/base.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeDatabaseTestEnvironment() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

AppDatabase openTestDatabase() {
  return AppDatabase(SqfliteQueryExecutor(path: inMemoryDatabasePath));
}
