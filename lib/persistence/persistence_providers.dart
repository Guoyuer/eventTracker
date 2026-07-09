import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_repository.dart';
import 'database/app_database.dart';
import 'statistics_repository.dart';
import 'unit_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() {
    unawaited(database.close());
  });
  return database;
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return DriftActivityRepository(ref.watch(appDatabaseProvider));
});

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return DriftUnitRepository(ref.watch(appDatabaseProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return DriftStatisticsRepository(ref.watch(appDatabaseProvider));
});
