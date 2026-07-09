import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';
import 'mutable_state.dart';

final activityRecordsProvider =
    FutureProvider.family<List<ActivityRecord>, int>((ref, activityId) {
      return ref.watch(activityReaderProvider).getActivityRecords(activityId);
    });

final activityDescriptionProvider = FutureProvider.family<String?, int>((
  ref,
  activityId,
) {
  return ref.watch(activityReaderProvider).getActivityDescription(activityId);
});

final activityDescriptionEditingProvider = NotifierProvider.autoDispose
    .family<MutableState<bool>, bool, int>((_) => MutableState(false));
