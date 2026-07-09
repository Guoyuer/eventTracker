import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:event_tracker/common/async_state.dart';
import 'package:event_tracker/common/commonWidget.dart';
import 'package:event_tracker/common/util.dart';
import 'package:intl/intl.dart';

import 'statistics_charts.dart';
import '../domain/date_range.dart';
import '../persistence/statistics_repository.dart' show StatisticsData;
import '../state/statistics_providers.dart';

class StatisticPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(selectedStatisticsRangeProvider);
    final timeLStr = DateFormat('yyyy.MM.dd').format(range.start);
    final timeRStr = DateFormat('yyyy.MM.dd').format(range.end);
    return ListView(children: [
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
                    timeLStr + ' 至 ' + timeRStr,
                    style: TextStyle(fontSize: 20),
                  ))),
              Container(
                  margin: EdgeInsets.only(right: 10),
                  child: myRaisedButton(Text("更改区间"), () async {
                    DateTimeRange? tmp = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now().add(Duration(days: -100)),
                        lastDate: DateTime.now());
                    if (tmp != null) {
                      ref.read(selectedStatisticsRangeProvider.notifier).state =
                          DateRange(
                              start: getDate(tmp.start),
                              end: getDate(tmp.end).add(Duration(days: 1)));
                    }
                  }))
            ],
          )),
      Charts(range)
    ]);
  }
}

class Charts extends ConsumerWidget {
  Charts(this.range);

  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(statisticsProvider(range));
    return AsyncStateView<StatisticsData>(
      value: statistics,
      data: _buildCharts,
      errorMessage: '加载统计失败',
      layout: AsyncStateLayout.card,
      onRetry: () => ref.invalidate(statisticsProvider(range)),
    );
  }

  Widget _buildCharts(StatisticsData statisticsData) {
    return StatisticsCharts(statisticsData);
  }
}
