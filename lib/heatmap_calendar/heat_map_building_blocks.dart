import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'heat_map.dart';
import 'heatmap_calendar_model.dart';

//最上层组件，只需给日期区间即可
class HeatMapDisplay extends StatelessWidget {
  const HeatMapDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    HeatMapDataHolder dataHolder = HeatMapDataHolder.of(context);
    List<Widget> years = dataHolder.model.years
        .map((year) => YearTile(year))
        .toList();
    return Row(mainAxisSize: MainAxisSize.min, children: years);
  }
}

//父组件只需要给它日期区间，需保证在同年内
class YearTile extends StatelessWidget {
  final HeatMapYearBlock year;

  YearTile(this.year, {super.key}) {
    assert(year.start.year == year.end.year);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> months = year.months.map((month) => MonthTile(month)).toList();
    return Row(children: months);
  }
}

//父组件只需要给它日期区间，需保证在同月内。
class MonthTile extends StatelessWidget {
  //已经可以自行决定长宽了。小修正：如果end是月的最后一天且恰是周六，那便再补一列空白的。为了视觉效果。论文提一下

  final HeatMapMonthBlock monthBlock; // 2021-4-1 ~ 2021-4-13
  MonthTile(this.monthBlock, {super.key}) {
    assert(monthBlock.start.month == monthBlock.end.month);
  }

  @override
  Widget build(BuildContext context) {
    var setting = HeatMapDataHolder.of(context).setting;
    int month = monthBlock.month;
    List<Widget> weeks = monthBlock.weeks
        .map((week) => WeekTile(week))
        .toList();
    final dataHolder = HeatMapDataHolder.of(context);
    return InkWell(
      onLongPress: () {
        dataHolder.onMonthTouched?.call(monthBlock.calendarMonthEnd);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            //同个Month的Tile
            width:
                monthBlock.widthInWeeks *
                    (setting.dayTileSize + setting.dayTileMargin) +
                (monthBlock.widthInWeeks - 1) * setting.monthTileMargin,
            child: Row(children: weeks),
          ),
          Text(
            DateFormat.MMM(
              Localizations.localeOf(context).languageCode,
            ).format(DateTime(2026, month)),
          ),
        ],
      ),
    );
  }
}

//父组件只需要给它日期区间，需保证在同周内。
class WeekTile extends StatelessWidget {
  final HeatMapWeekColumn week;

  const WeekTile(this.week, {super.key});

  @override
  Widget build(BuildContext context) {
    var setting = HeatMapDataHolder.of(context).setting;
    List<Widget> days = week.days.map((day) => DayTile(cell: day)).toList();
    return SizedBox(
      height: setting.dayTileSize * 7 + setting.dayTileMargin * 7,
      child: Column(children: days),
    );
  }
}

//父组件只需要给它日期
class DayTile extends StatelessWidget {
  final HeatMapDayCell cell;

  const DayTile({super.key, required this.cell});

  @override
  Widget build(BuildContext context) {
    HeatMapSetting setting = HeatMapDataHolder.of(context).setting;
    var dataHolder = HeatMapDataHolder.of(context);
    int level = cell.level;
    if (cell.isPlaceholder) {
      //占位格子
      return Container(
        alignment: Alignment.center,
        height: setting.dayTileSize,
        width: setting.dayTileSize,
        margin: EdgeInsets.all(setting.dayTileMargin / 2),
        decoration: dayDecoration(
          setting.dayTileSize,
          setting.colorMap[level]!,
        ),
      );
    } else {
      return InkWell(
        onTap: () {
          dataHolder.onDayTouched?.call(cell.date!);
        },
        child: Container(
          alignment: Alignment.center,
          height: setting.dayTileSize,
          width: setting.dayTileSize,
          margin: EdgeInsets.all(setting.dayTileMargin / 2),
          decoration: dayDecoration(
            setting.dayTileSize,
            setting.colorMap[level]!,
          ),
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
    borderRadius: BorderRadius.all(Radius.elliptical(radius, radius)),
  );
}
