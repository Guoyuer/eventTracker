class HeatMapCalendarModel {
  HeatMapCalendarModel({
    required this.start,
    required this.end,
    required this.valuesByDate,
    required this.years,
  });

  final DateTime start;
  final DateTime end;
  final Map<DateTime, double> valuesByDate;
  final List<HeatMapYearBlock> years;
}

class HeatMapYearBlock {
  HeatMapYearBlock({
    required this.start,
    required this.end,
    required this.months,
  });

  final DateTime start;
  final DateTime end;
  final List<HeatMapMonthBlock> months;
}

class HeatMapMonthBlock {
  HeatMapMonthBlock({
    required this.start,
    required this.end,
    required this.calendarMonthEnd,
    required this.weeks,
  });

  final DateTime start;
  final DateTime end;
  final DateTime calendarMonthEnd;
  final List<HeatMapWeekColumn> weeks;

  int get month => start.month;
  int get widthInWeeks => weeks.length;
}

class HeatMapWeekColumn {
  HeatMapWeekColumn(this.days) : assert(days.length == DateTime.daysPerWeek);

  final List<HeatMapDayCell> days;
}

class HeatMapDayCell {
  const HeatMapDayCell({
    required this.date,
    required this.level,
    required this.value,
  });

  const HeatMapDayCell.placeholder()
      : date = null,
        level = -1,
        value = null;

  final DateTime? date;
  final int level;
  final double? value;

  bool get isPlaceholder => date == null;
}

HeatMapCalendarModel buildHeatMapCalendarModel({
  required DateTime start,
  required DateTime end,
  required Map<DateTime, double> input,
  required int maxLevel,
}) {
  final normalizedStart = dateOnly(start);
  final normalizedEnd = dateOnly(end);
  if (normalizedEnd.isBefore(normalizedStart)) {
    throw ArgumentError.value(end, 'end', 'must be on or after start');
  }

  final valuesByDate = normalizeHeatMapInput(input);
  final maxValue = _maxInputValue(valuesByDate);
  final levelByDate = _buildLevelMap(
    start: normalizedStart,
    end: normalizedEnd,
    valuesByDate: valuesByDate,
    maxValue: maxValue,
    maxLevel: maxLevel,
  );

  return HeatMapCalendarModel(
    start: normalizedStart,
    end: normalizedEnd,
    valuesByDate: valuesByDate,
    years: _buildYears(
      start: normalizedStart,
      end: normalizedEnd,
      levelByDate: levelByDate,
      valuesByDate: valuesByDate,
    ),
  );
}

Map<DateTime, double> normalizeHeatMapInput(Map<DateTime, double> input) {
  return {
    for (final entry in input.entries) dateOnly(entry.key): entry.value,
  };
}

DateTime dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

List<HeatMapYearBlock> _buildYears({
  required DateTime start,
  required DateTime end,
  required Map<DateTime, int> levelByDate,
  required Map<DateTime, double> valuesByDate,
}) {
  final years = <HeatMapYearBlock>[];
  var cursor = start;

  while (!cursor.isAfter(end)) {
    final yearEnd = _minDate(DateTime(cursor.year, 12, 31), end);
    years.add(
      HeatMapYearBlock(
        start: cursor,
        end: yearEnd,
        months: _buildMonths(
          start: cursor,
          end: yearEnd,
          levelByDate: levelByDate,
          valuesByDate: valuesByDate,
        ),
      ),
    );
    cursor = yearEnd.add(const Duration(days: 1));
  }

  return years;
}

List<HeatMapMonthBlock> _buildMonths({
  required DateTime start,
  required DateTime end,
  required Map<DateTime, int> levelByDate,
  required Map<DateTime, double> valuesByDate,
}) {
  final months = <HeatMapMonthBlock>[];
  var cursor = start;

  while (!cursor.isAfter(end)) {
    final calendarMonthEnd = _lastDayOfMonth(cursor);
    final monthEnd = _minDate(calendarMonthEnd, end);
    final weeks = _buildWeeks(
      start: cursor,
      end: monthEnd,
      levelByDate: levelByDate,
      valuesByDate: valuesByDate,
    );
    if (monthEnd == calendarMonthEnd && monthEnd.weekday == DateTime.saturday) {
      weeks.add(HeatMapWeekColumn(List.filled(
        DateTime.daysPerWeek,
        const HeatMapDayCell.placeholder(),
      )));
    }

    months.add(
      HeatMapMonthBlock(
        start: cursor,
        end: monthEnd,
        calendarMonthEnd: calendarMonthEnd,
        weeks: weeks,
      ),
    );
    cursor = monthEnd.add(const Duration(days: 1));
  }

  return months;
}

List<HeatMapWeekColumn> _buildWeeks({
  required DateTime start,
  required DateTime end,
  required Map<DateTime, int> levelByDate,
  required Map<DateTime, double> valuesByDate,
}) {
  final weeks = <HeatMapWeekColumn>[];
  var cursor = start;

  while (!cursor.isAfter(end)) {
    final daysUntilSaturday =
        (DateTime.saturday - cursor.weekday) % DateTime.daysPerWeek;
    final weekEnd = _minDate(
      cursor.add(Duration(days: daysUntilSaturday)),
      end,
    );
    weeks.add(_buildWeek(
      start: cursor,
      end: weekEnd,
      levelByDate: levelByDate,
      valuesByDate: valuesByDate,
    ));
    cursor = weekEnd.add(const Duration(days: 1));
  }

  return weeks;
}

HeatMapWeekColumn _buildWeek({
  required DateTime start,
  required DateTime end,
  required Map<DateTime, int> levelByDate,
  required Map<DateTime, double> valuesByDate,
}) {
  final days = <HeatMapDayCell>[];
  final firstWeekdayIndex = _sundayBasedWeekday(start);
  final lastWeekdayIndex = _sundayBasedWeekday(end);
  var currentDate = start;

  for (var i = 0; i < DateTime.daysPerWeek; i++) {
    if (firstWeekdayIndex <= i && i <= lastWeekdayIndex) {
      days.add(
        HeatMapDayCell(
          date: currentDate,
          level: levelByDate[currentDate] ?? 0,
          value: valuesByDate[currentDate],
        ),
      );
      currentDate = currentDate.add(const Duration(days: 1));
    } else {
      days.add(const HeatMapDayCell.placeholder());
    }
  }

  return HeatMapWeekColumn(days);
}

Map<DateTime, int> _buildLevelMap({
  required DateTime start,
  required DateTime end,
  required Map<DateTime, double> valuesByDate,
  required double maxValue,
  required int maxLevel,
}) {
  final levelByDate = <DateTime, int>{};
  final thresholds = _thresholds(maxValue: maxValue, maxLevel: maxLevel);
  var cursor = start;

  while (!cursor.isAfter(end)) {
    var level = 0;
    final value = valuesByDate[cursor];
    if (value != null) {
      for (var i = 0; i < thresholds.length; i++) {
        if (value > thresholds[i]) level = i;
      }
    }
    levelByDate[cursor] = level;
    cursor = cursor.add(const Duration(days: 1));
  }

  return levelByDate;
}

List<double> _thresholds({
  required double maxValue,
  required int maxLevel,
}) {
  if (maxLevel <= 0) {
    return [0];
  }

  final activeLevelCount = maxLevel + 1;
  return [
    0,
    for (var i = 0; i < activeLevelCount - 1; i++)
      i * maxValue / activeLevelCount,
  ];
}

double _maxInputValue(Map<DateTime, double> input) {
  if (input.isEmpty) {
    return 0;
  }

  return input.values.reduce((maxValue, value) {
    return value > maxValue ? value : maxValue;
  });
}

int _sundayBasedWeekday(DateTime date) {
  return date.weekday % DateTime.daysPerWeek;
}

DateTime _lastDayOfMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0);
}

DateTime _minDate(DateTime left, DateTime right) {
  return left.isBefore(right) ? left : right;
}
