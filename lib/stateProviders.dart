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

final selectedIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final eventListScrollDirProvider =
    StateProvider<ScrollDirection>((ref) => ScrollDirection.forward);

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
  return unitRepository().getUnits();
});

final statisticsProvider =
    FutureProvider.family<StatisticsData, DateTimeRange>((ref, range) {
  return statisticsRepository().getStatisticsData(range);
});
