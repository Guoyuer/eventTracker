import 'package:date_util/date_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_tracker/common/const.dart';
import 'package:intl/intl.dart';

import 'heatMap.dart';
import 'util.dart';

//最上层组件，只需给日期区间即可
class HeatMapDisplay extends StatelessWidget {
  HeatMapDisplay();

  @override
  Widget build(BuildContext context) {
    HeatMapDataHolder dataHolder = HeatMapDataHolder.of(context);
    DateTimeRange dateRange = dataHolder.dateRange;
    List<DateTimeRange> yearRanges = split2year(dateRange);
    List<Widget> years = [];
    yearRanges.forEach((element) {
      years
          .add(YearTile(DateTimeRange(start: element.start, end: element.end)));
    });
    return Row(mainAxisSize: MainAxisSize.min, children: years);
  }
}

//父组件只需要给它日期区间，需保证在同年内
class YearTile extends StatelessWidget {
  final DateTimeRange dateRange;

  YearTile(this.dateRange) {
    assert(dateRange.start.year == dateRange.end.year);
  }

  @override
  Widget build(BuildContext context) {
    List<DateTimeRange> monthRanges = split2month(dateRange);
    List<Widget> months = [];
    monthRanges.forEach((element) {
      months.add(
          MonthTile(DateTimeRange(start: element.start, end: element.end)));
    });
    return Container(
      // width: 500,
      child: Row(
        children: months,
      ),
    );
  }
}

//父组件只需要给它日期区间，需保证在同月内。
class MonthTile extends StatelessWidget {
  //已经可以自行决定长宽了。小修正：如果end是月的最后一天且恰是周六，那便再补一列空白的。为了视觉效果。论文提一下

  final DateTimeRange dateRange; // 2021-4-1 ~ 2021-4-13
  MonthTile(this.dateRange) {
    assert(dateRange.start.month == dateRange.end.month);
  }

  @override
  Widget build(BuildContext context) {
    List<DateTimeRange> weekdayRanges = split2weeks(dateRange);
    var setting = HeatMapDataHolder.of(context).setting;
    int month = dateRange.start.month;
    DateTime end = dateRange.end;
    List<Widget> weeks = [];
    weekdayRanges.forEach((element) {
      weeks
          .add(WeekTile(DateTimeRange(start: element.start, end: element.end)));
    });
    var dateUtil = DateUtil();
    int daysInMonth = dateUtil.daysInMonth(end.month, end.year); //end的最后一天
    DateTime lastDay =
        DateTime(end.year, end.month).add(Duration(days: daysInMonth - 1));

    if (end.weekday == DateTime.saturday && end.compareTo(lastDay) == 0) {
      weeks.add(WeekTile(DateTimeRange(start: nilTime, end: nilTime)));
    }
    return InkWell(
        onLongPress: () {
          MonthTouchedN(month: lastDay).dispatch(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                //同个Month的Tile
                width: weeks.length *
                        (setting.dayTileSize + setting.dayTileMargin) +
                    (weeks.length - 1) * setting.monthTileMargin,
                child: Row(
                  children: weeks,
                )),
            Text("$month 月"),
          ],
        ));
  }
}

//父组件只需要给它日期区间，需保证在同周内。
class WeekTile extends StatelessWidget {
  final DateTimeRange dateRange;

  WeekTile(this.dateRange);

  @override
  Widget build(BuildContext context) {
    // Map<int, Color> colorMap = HeatMapDataHolder.of(context).setting.colorMap;
    var setting = HeatMapDataHolder.of(context).setting;
    // double tileSize = HeatMapDataHolder.of(context).setting.dayTileSize;

    List<Widget> days = []; //要给DayTile的颜色
    int start = dateRange.start.weekday % 7;
    int end = dateRange.end.weekday % 7;
    int skipped = 0;
    for (int i = 0; i < 7; i++) {
      if (start <= i && i <= end) {
        days.add(
            DayTile(date: dateRange.start.add(Duration(days: i - skipped))));
      } else {
        skipped++;
        days.add(DayTile(date: nilTime));
      }
    }
    return Container(
        height: setting.dayTileSize * 7 + setting.dayTileMargin * 7,
        child: Column(
          children: days,
        ));
  }
}

Widget weekdayStrTile(BuildContext context, double size) {
  HeatMapSetting setting = HeatMapDataHolder.of(context).setting;
  List<String> weekdays = ["日", "一", "二", "三", "四", "五", "六"];
  List<Widget> weekdayStrTiles = [];
  weekdays.forEach((str) {
    weekdayStrTiles.add(textTile(context, str, setting.dayTileSize));
  });
  return Align(
      alignment: Alignment.topCenter,
      child: Container(
          height: setting.dayTileSize * 7 + setting.dayTileMargin * 7,
          child: Column(
            children: weekdayStrTiles,
          )));
}

Widget textTile(BuildContext context, String text, double size) {
  HeatMapSetting setting = HeatMapDataHolder.of(context).setting;
  return Container(
    child: Text(text),
    width: size,
    height: size,
    margin: EdgeInsets.all(setting.dayTileMargin / 2),
  );
}

Widget emptyDayTile(BuildContext context, double size) {
  HeatMapSetting setting = HeatMapDataHolder.of(context).setting;
  return Container(
    width: size,
    height: size,
    margin: EdgeInsets.all(setting.dayTileMargin / 2),
  );
}

//父组件只需要给它日期
class DayTile extends StatelessWidget {
  final DateTime date;

  DayTile({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    HeatMapSetting setting = HeatMapDataHolder.of(context).setting;
    var date2level = HeatMapDataHolder.of(context).date2level;
    var data = HeatMapDataHolder.of(context).data;
    String? unit = HeatMapDataHolder.of(context).unit;
    if (unit == null) unit = "";
    int level = date2level[date]!;
    if (date == nilTime) {
      //占位格子
      return Container(
        alignment: Alignment.center,
        height: setting.dayTileSize,
        width: setting.dayTileSize,
        margin: EdgeInsets.all(setting.dayTileMargin / 2),
        decoration:
            dayDecoration(setting.dayTileSize, setting.colorMap[level]!),
      );
    } else {
      String valStr;
      if (data.containsKey(date)) {
        valStr = data[date]!.toInt().toString();
      } else {
        valStr = "0";
      }
      return InkWell(
        onTap: () {
          // showToast("日期: $timeStr 值: $valStr $unit");
          DayTouchedN(day: date).dispatch(context);
        },
        child: Container(
          alignment: Alignment.center,
          height: setting.dayTileSize,
          width: setting.dayTileSize,
          margin: EdgeInsets.all(setting.dayTileMargin / 2),
          decoration:
              dayDecoration(setting.dayTileSize, setting.colorMap[level]!),
        ),
      );
    }
  }
}

BoxDecoration dayDecoration(double size, Color color) {
  double radius = size / 3;
  return BoxDecoration(
      color: color,
      // border: Border.all(color: Color.fromARGB(255, 223, 225, 228), width: 1),
      borderRadius: BorderRadius.all(Radius.elliptical(radius, radius)));
}
