import 'input_validation.dart';

class ActivityHistoryRecord {
  const ActivityHistoryRecord({
    required this.id,
    this.startTime,
    this.endTime,
    this.value,
  });

  final int id;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? value;
}

class ActivityRecordHistory {
  const ActivityRecordHistory._({
    required this.occurrenceCount,
    required this.totalDuration,
    required this.totalValue,
    required this.activeStartedAt,
  });

  factory ActivityRecordHistory.evaluate({
    required int activityId,
    required bool careTime,
    required bool hasUnit,
    required Iterable<ActivityHistoryRecord> records,
  }) {
    var occurrenceCount = 0;
    var totalDuration = Duration.zero;
    var totalValue = 0.0;
    DateTime? activeStartedAt;

    for (final record in records) {
      final startedAt = record.startTime;
      final endedAt = record.endTime;

      if (!careTime) {
        if (startedAt != null || endedAt == null) {
          throw StateError(
            'Plain Activity $activityId has malformed Record ${record.id}',
          );
        }
        occurrenceCount++;
        totalValue += validateRecordValue(record.value, hasUnit: hasUnit) ?? 0;
        _validateTotalValue(totalValue);
        continue;
      }

      if (startedAt == null) {
        throw StateError(
          'Timed Activity $activityId has Record ${record.id} without a start',
        );
      }
      if (endedAt == null) {
        if (record.value != null) {
          throw StateError(
            'Active Record ${record.id} for Timed Activity $activityId '
            'already has a value',
          );
        }
        if (activeStartedAt != null) {
          throw StateError(
            'Timed Activity $activityId has multiple active Records',
          );
        }
        activeStartedAt = startedAt;
        continue;
      }

      final duration = endedAt.difference(startedAt);
      if (duration.isNegative) {
        throw StateError(
          'Timed Activity $activityId has Record ${record.id} ending before '
          'it starts',
        );
      }
      totalDuration += duration;
      totalValue += validateRecordValue(record.value, hasUnit: hasUnit) ?? 0;
      _validateTotalValue(totalValue);
    }

    return ActivityRecordHistory._(
      occurrenceCount: occurrenceCount,
      totalDuration: totalDuration,
      totalValue: totalValue,
      activeStartedAt: activeStartedAt,
    );
  }

  final int occurrenceCount;
  final Duration totalDuration;
  final double totalValue;
  final DateTime? activeStartedAt;

  static void _validateTotalValue(double value) {
    if (!value.isFinite) {
      throw StateError('Activity Record value total overflowed');
    }
  }
}
