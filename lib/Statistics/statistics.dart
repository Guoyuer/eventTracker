import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_tracker/common/async_state.dart';
import 'package:event_tracker/common/commonWidget.dart';
import 'package:intl/intl.dart';

import 'statistics_charts.dart';
import '../domain/date_range.dart';
import '../domain/statistics_repository.dart' show StatisticsData;
import '../state/statistics_providers.dart';
import '../l10n/app_localizations.dart';

class StatisticPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(selectedStatisticsRangeProvider);
    final timeLStr = DateFormat('yyyy.MM.dd').format(range.firstDay);
    final timeRStr = DateFormat('yyyy.MM.dd').format(range.lastDay);
    final localizations = AppLocalizations.of(context)!;
    return ListView(
      children: [
        Card(
          elevation: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(left: 10),
                height: 40,
                child: Center(
                  child: Text(
                    localizations.statisticsRange(timeLStr, timeRStr),
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 10),
                child: primaryActionButton(
                  child: Text(localizations.changeRange),
                  onPressed: () async {
                    final now = DateTime.now();
                    final lastSelectableDay = DateTime(
                      now.year,
                      now.month,
                      now.day,
                    );
                    final selectedRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(
                        lastSelectableDay.year,
                        lastSelectableDay.month,
                        lastSelectableDay.day - 100,
                      ),
                      lastDate: lastSelectableDay,
                      initialDateRange: DateTimeRange(
                        start: range.firstDay,
                        end: range.lastDay,
                      ),
                    );
                    if (selectedRange != null) {
                      ref
                          .read(selectedStatisticsRangeProvider.notifier)
                          .set(
                            CalendarDateRange(
                              firstDay: selectedRange.start,
                              lastDay: selectedRange.end,
                            ),
                          );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Charts(range),
      ],
    );
  }
}

class Charts extends ConsumerWidget {
  Charts(this.range);

  final CalendarDateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(statisticsProvider(range));
    return AsyncStateView<StatisticsData>(
      value: statistics,
      data: _buildCharts,
      errorMessage: AppLocalizations.of(context)!.loadStatisticsFailed,
      layout: AsyncStateLayout.card,
      onRetry: () => ref.invalidate(statisticsProvider(range)),
      retryLabel: AppLocalizations.of(context)!.retry,
    );
  }

  Widget _buildCharts(StatisticsData statisticsData) {
    return StatisticsCharts(statisticsData);
  }
}
