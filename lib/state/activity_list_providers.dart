import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity_models.dart';
import '../persistence/persistence_providers.dart';

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
