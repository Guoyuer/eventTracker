import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/date_range.dart';
import '../domain/statistics_repository.dart';
import '../persistence/persistence_providers.dart';
import 'mutable_state.dart';

final selectedStatisticsRangeProvider =
    NotifierProvider<MutableState<CalendarDateRange>, CalendarDateRange>(() {
      return MutableState(
        CalendarDateRange.recentDays(endingOn: DateTime.now(), dayCount: 7),
      );
    });

final statisticsProvider =
    FutureProvider.family<StatisticsData, CalendarDateRange>((ref, range) {
      return ref.watch(statisticsRepositoryProvider).getStatisticsData(range);
    });
