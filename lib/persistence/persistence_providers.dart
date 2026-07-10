import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity_repository.dart';
import '../domain/statistics_repository.dart';
import '../domain/unit_repository.dart';
import 'database/app_database.dart';
import 'database/database_bootstrap.dart';
import 'drift_activity_repository.dart';
import 'drift_statistics_repository.dart';
import 'drift_unit_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(null, defaultUsesWriteAheadLog());
  ref.onDispose(() {
    unawaited(database.close());
  });
  return database;
});

final _activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return DriftActivityRepository(ref.watch(appDatabaseProvider));
});

final activityReaderProvider = Provider<ActivityReader>((ref) {
  return ref.watch(_activityRepositoryProvider);
});

final activityWriterProvider = Provider<ActivityWriter>((ref) {
  return ref.watch(_activityRepositoryProvider);
});

final recordLifecycleProvider = Provider<RecordLifecycle>((ref) {
  return ref.watch(_activityRepositoryProvider);
});

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return DriftUnitRepository(ref.watch(appDatabaseProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return DriftStatisticsRepository(ref.watch(appDatabaseProvider));
});
