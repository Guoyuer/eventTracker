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

class ActivityAggregateRecord {
  const ActivityAggregateRecord({
    required this.id,
    required this.endTime,
    this.startTime,
    this.value,
  });

  final int id;
  final DateTime? startTime;
  final DateTime endTime;
  final double? value;

  Duration get contribution {
    final startedAt = startTime;
    if (startedAt == null) {
      return const Duration(seconds: 1);
    }

    final duration = endTime.difference(startedAt);
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Completed record duration cannot be negative.',
      );
    }
    return duration;
  }
}

class ActivityAggregateSnapshot {
  const ActivityAggregateSnapshot({
    required this.lastRecordId,
    required this.sumTime,
    required this.sumValue,
  });

  factory ActivityAggregateSnapshot.fromCompletedRecords(
    Iterable<ActivityAggregateRecord> records, {
    int? activeRecordId,
  }) {
    final orderedRecords = records.toList()
      ..sort((left, right) {
        final endTimeComparison = left.endTime.compareTo(right.endTime);
        if (endTimeComparison != 0) {
          return endTimeComparison;
        }
        return left.id.compareTo(right.id);
      });

    var sumTime = Duration.zero;
    var sumValue = 0.0;
    for (final record in orderedRecords) {
      sumTime += record.contribution;
      sumValue += record.value ?? 0;
    }

    return ActivityAggregateSnapshot(
      lastRecordId:
          activeRecordId ??
          (orderedRecords.isEmpty ? null : orderedRecords.last.id),
      sumTime: sumTime,
      sumValue: sumValue,
    );
  }

  final int? lastRecordId;
  final Duration sumTime;
  final double sumValue;
}
