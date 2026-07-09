import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/date_range.dart';
import '../persistence/persistence_providers.dart';
import '../persistence/statistics_repository.dart';
import 'mutable_state.dart';

final selectedStatisticsRangeProvider =
    NotifierProvider<MutableState<DateRange>, DateRange>(() {
      final now = DateTime.now();
      return MutableState(
        DateRange(
          start: DateTime(now.year, now.month, now.day).add(Duration(days: -7)),
          end: now,
        ),
      );
    });

final statisticsProvider = FutureProvider.family<StatisticsData, DateRange>((
  ref,
  range,
) {
  return ref.watch(statisticsRepositoryProvider).getStatisticsData(range);
});
