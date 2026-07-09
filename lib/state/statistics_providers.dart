import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/date_range.dart';
import '../persistence/persistence_providers.dart';
import '../persistence/statistics_repository.dart';

final selectedStatisticsRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  return DateRange(
    start: DateTime(now.year, now.month, now.day).add(Duration(days: -7)),
    end: now,
  );
});

final statisticsProvider =
    FutureProvider.family<StatisticsData, DateRange>((ref, range) {
  return ref.watch(statisticsRepositoryProvider).getStatisticsData(range);
});
