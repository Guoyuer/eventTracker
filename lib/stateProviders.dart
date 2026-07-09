import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/activity_models.dart';
import 'persistence/persistence_providers.dart';
import 'persistence/statistics_repository.dart';

export 'persistence/persistence_providers.dart';

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

final activityDescriptionEditingProvider =
    StateProvider.family<bool, int>((ref, activityId) => false);

final activityEditorCareTimeProvider =
    StateProvider.autoDispose<bool>((ref) => true);

final activityEditorSelectedUnitProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final unitListProvider = FutureProvider<List<ActivityUnit>>((ref) {
  return ref.watch(unitRepositoryProvider).getUnits();
});

final statisticsProvider =
    FutureProvider.family<StatisticsData, DateTimeRange>((ref, range) {
  return ref.watch(statisticsRepositoryProvider).getStatisticsData(range);
});
