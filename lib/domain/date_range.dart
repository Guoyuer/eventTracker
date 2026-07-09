class DateInterval {
  DateInterval({required this.start, required this.endExclusive}) {
    if (endExclusive.isBefore(start)) {
      throw ArgumentError.value(
        endExclusive,
        'endExclusive',
        'must be on or after start',
      );
    }
  }

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime value) {
    return !value.isBefore(start) && value.isBefore(endExclusive);
  }

  @override
  bool operator ==(Object other) {
    return other is DateInterval &&
        other.start == start &&
        other.endExclusive == endExclusive;
  }

  @override
  int get hashCode => Object.hash(start, endExclusive);
}

class CalendarDateRange {
  CalendarDateRange({required DateTime firstDay, required DateTime lastDay})
    : this._(_dateOnly(firstDay), _dateOnly(lastDay));

  CalendarDateRange._(this.firstDay, this.lastDay) {
    if (lastDay.isBefore(firstDay)) {
      throw ArgumentError.value(
        lastDay,
        'lastDay',
        'must not precede firstDay',
      );
    }
  }

  factory CalendarDateRange.recentDays({
    required DateTime endingOn,
    required int dayCount,
  }) {
    if (dayCount < 1) {
      throw ArgumentError.value(dayCount, 'dayCount', 'must be positive');
    }
    final lastDay = _dateOnly(endingOn);
    return CalendarDateRange._(
      _shiftCalendarDays(lastDay, -(dayCount - 1)),
      lastDay,
    );
  }

  final DateTime firstDay;
  final DateTime lastDay;

  DateInterval get interval {
    return DateInterval(
      start: firstDay,
      endExclusive: _shiftCalendarDays(lastDay, 1),
    );
  }

  bool contains(DateTime value) => interval.contains(value);

  @override
  bool operator ==(Object other) {
    return other is CalendarDateRange &&
        other.firstDay == firstDay &&
        other.lastDay == lastDay;
  }

  @override
  int get hashCode => Object.hash(firstDay, lastDay);

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime _shiftCalendarDays(DateTime value, int dayOffset) {
    return DateTime(value.year, value.month, value.day + dayOffset);
  }
}
