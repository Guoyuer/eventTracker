sealed class Activity {
  const Activity({
    required this.id,
    required this.name,
    required this.totalValue,
    this.unit,
    this.description,
  });

  final int id;
  final String name;
  final String? unit;
  final String? description;
  final double totalValue;

  String get requiredUnit {
    return unit ?? (throw StateError('Activity $id has no unit'));
  }
}

final class PlainActivity extends Activity {
  const PlainActivity({
    required super.id,
    required super.name,
    required this.occurrenceCount,
    required super.totalValue,
    super.unit,
    super.description,
  });

  final int occurrenceCount;
}

sealed class TimedActivity extends Activity {
  const TimedActivity({
    required super.id,
    required super.name,
    required this.totalDuration,
    required super.totalValue,
    super.unit,
    super.description,
  });

  final Duration totalDuration;
}

final class InactiveTimedActivity extends TimedActivity {
  const InactiveTimedActivity({
    required super.id,
    required super.name,
    required super.totalDuration,
    required super.totalValue,
    super.unit,
    super.description,
  });
}

final class ActiveTimedActivity extends TimedActivity {
  const ActiveTimedActivity({
    required super.id,
    required super.name,
    required this.startedAt,
    required super.totalDuration,
    required super.totalValue,
    super.unit,
    super.description,
  });

  final DateTime startedAt;
}

class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.eventId,
    required this.endTime,
    this.startTime,
    this.value,
  });

  final int id;
  final int eventId;
  final DateTime? startTime;
  final DateTime endTime;
  final double? value;

  DateTime get requiredStartTime {
    return startTime ??
        (throw StateError('Timed Record $id has no start time'));
  }

  double get requiredValue {
    return value ?? (throw StateError('Record $id has no value'));
  }
}

class StatisticsActivity {
  const StatisticsActivity({required this.id, required this.name});

  final int id;
  final String name;
}

class ActivityUnit {
  const ActivityUnit({required this.id, required this.name});

  final int id;
  final String name;
}
