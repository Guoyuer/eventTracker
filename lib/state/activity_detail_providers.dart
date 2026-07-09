import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';

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
