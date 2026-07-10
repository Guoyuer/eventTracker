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

sealed class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.activityId,
    this.value,
  });

  final int id;
  final int activityId;
  final double? value;
}

sealed class CompletedActivityRecord extends ActivityRecord {
  const CompletedActivityRecord({
    required super.id,
    required super.activityId,
    required this.endedAt,
    super.value,
  });

  final DateTime endedAt;
}

final class PlainRecord extends CompletedActivityRecord {
  const PlainRecord({
    required super.id,
    required super.activityId,
    required super.endedAt,
    super.value,
  });
}

final class CompletedTimedRecord extends CompletedActivityRecord {
  const CompletedTimedRecord({
    required super.id,
    required super.activityId,
    required this.startedAt,
    required super.endedAt,
    super.value,
  });

  final DateTime startedAt;

  Duration get duration => endedAt.difference(startedAt);
}

final class ActiveTimedRecord extends ActivityRecord {
  const ActiveTimedRecord({
    required super.id,
    required super.activityId,
    required this.startedAt,
  }) : super(value: null);

  final DateTime startedAt;
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
