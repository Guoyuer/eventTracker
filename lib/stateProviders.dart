import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/activity_models.dart';
import 'persistence/activity_repository.dart';
import 'persistence/statistics_repository.dart';
import 'persistence/unit_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return activityRepository();
});

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return unitRepository();
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return statisticsRepository();
});

final selectedStatisticsRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, now.day).add(Duration(days: -7)),
    end: now,
  );
});

final selectedIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final eventListScrollDirProvider =
    StateProvider<ScrollDirection>((ref) => ScrollDirection.forward);

final elapsedDurationProvider =
    StreamProvider.family<Duration, DateTime>((ref, startTime) async* {
  yield DateTime.now().difference(startTime);
  await for (final _ in Stream.periodic(Duration(seconds: 1))) {
    yield DateTime.now().difference(startTime);
  }
});

final activityListProvider = FutureProvider<List<BaseEventModel>>((ref) {
  return ref.watch(activityRepositoryProvider).getActivities();
});

final activityRecordsProvider =
    FutureProvider.family<List<ActivityRecord>, int>((ref, activityId) {
  return ref.watch(activityRepositoryProvider).getActivityRecords(activityId);
});

final activityDescriptionProvider =
    FutureProvider.family<String?, int>((ref, activityId) {
  return ref
      .watch(activityRepositoryProvider)
      .getActivityDescription(activityId);
});

final unitListProvider = FutureProvider<List<ActivityUnit>>((ref) {
  return ref.watch(unitRepositoryProvider).getUnits();
});

final statisticsProvider =
    FutureProvider.family<StatisticsData, DateTimeRange>((ref, range) {
  return ref.watch(statisticsRepositoryProvider).getStatisticsData(range);
});
