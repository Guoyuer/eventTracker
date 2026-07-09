import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'DAO/base.dart';
import 'persistence/activity_repository.dart';

final selectedIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final eventListScrollDirProvider =
    StateProvider<ScrollDirection>((ref) => ScrollDirection.forward);

final activityListProvider = FutureProvider<List<BaseEventModel>>((ref) {
  return activityRepository().getActivities();
});
