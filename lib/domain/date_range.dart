class DateRange {
  DateRange({
    required this.start,
    required this.end,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'must be on or after start');
    }
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) {
    return !value.isBefore(start) && !value.isAfter(end);
  }

  @override
  bool operator ==(Object other) {
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
