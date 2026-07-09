class ActivityAggregateTotals {
  const ActivityAggregateTotals({
    required this.sumTime,
    required this.sumValue,
  });

  final Duration sumTime;
  final double sumValue;

  ActivityAggregateTotals addPlainRecord({double? value}) {
    return ActivityAggregateTotals(
      sumTime: sumTime + const Duration(seconds: 1),
      sumValue: sumValue + (value ?? 0),
    );
  }

  ActivityAggregateTotals addTimedRecord({
    required Duration duration,
    double? value,
  }) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Timed record duration cannot be negative.',
      );
    }

    return ActivityAggregateTotals(
      sumTime: sumTime + duration,
      sumValue: sumValue + (value ?? 0),
    );
  }
}
