import 'package:flutter/material.dart';

import 'heat_map_building_blocks.dart';
import 'heatmap_calendar_model.dart';
import '../common/app_chart_theme.dart';

class HeatMapSetting {
  final Map<int, Color> colorMap; //int indicates level
  final double dayTileSize;
  final double dayTileMargin;
  final double monthTileMargin;

  const HeatMapSetting({
    required this.colorMap,
    this.dayTileSize = 15,
    this.dayTileMargin = 5,
    this.monthTileMargin = 2,
  });
}

class HeatMapDataHolder extends InheritedWidget {
  final HeatMapSetting setting;
  final HeatMapCalendarModel model;
  final ValueChanged<DateTime>? onMonthTouched;
  final ValueChanged<DateTime>? onDayTouched;

  const HeatMapDataHolder({
    super.key,
    required this.setting,
    required this.model,
    this.onMonthTouched,
    this.onDayTouched,
    required super.child,
  });

  @override
  bool updateShouldNotify(HeatMapDataHolder oldWidget) {
    return setting != oldWidget.setting || model != oldWidget.model;
  }

  static HeatMapDataHolder of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HeatMapDataHolder>()!;
  }
}

class HeatMapCalendar extends StatelessWidget {
  final HeatMapSetting? setting;
  final Map<DateTime, double> input;
  final DateTimeRange dateRange;
  final ValueChanged<DateTime>? onMonthTouched;
  final ValueChanged<DateTime>? onDayTouched;

  const HeatMapCalendar({
    super.key,
    this.setting,
    required this.input,
    required this.dateRange,
    this.onMonthTouched,
    this.onDayTouched,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSetting =
        setting ??
        HeatMapSetting(colorMap: AppChartTheme.of(context).heatmapColors);
    final model = buildHeatMapCalendarModel(
      start: dateRange.start,
      end: dateRange.end,
      input: input,
      maxLevel: _maxColorLevel(resolvedSetting.colorMap),
    );
    return HeatMapDataHolder(
      setting: resolvedSetting,
      model: model,
      onMonthTouched: onMonthTouched,
      onDayTouched: onDayTouched,
      child: HeatMapDisplay(),
    );
  }

  static int _maxColorLevel(Map<int, Color> colorMap) {
    return colorMap.keys
        .where((level) => level >= 0)
        .fold(0, (max, level) => max > level ? max : level);
  }
}
