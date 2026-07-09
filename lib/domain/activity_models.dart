enum EventStatus { plain, active, paused, notActive }

class BaseEventModel {
  int id;
  String name;
  String? unit;
  String? description;
  int? lastRecordId;

  BaseEventModel(
    this.id,
    this.name, [
    this.unit,
    this.description,
    this.lastRecordId,
  ]);
}

class PlainEventModel extends BaseEventModel {
  int time;
  double? sumVal;

  PlainEventModel(
    int id,
    String name,
    String? unit,
    this.time, [
    this.sumVal,
    String? description,
    int? lastRecordId,
  ]) : super(id, name, unit, description, lastRecordId);
}

class TimingEventModel extends BaseEventModel {
  EventStatus status;
  DateTime? startTime;
  Duration sumDuration;
  double? sumVal;

  TimingEventModel(
    int id,
    String name,
    String? unit,
    this.status,
    this.sumDuration, [
    this.startTime,
    this.sumVal,
    String? description,
    int? lastRecordId,
  ]) : super(id, name, unit, description, lastRecordId);
}

class ActivityRecord {
  ActivityRecord({
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
}

class StatisticsActivity {
  StatisticsActivity({required this.id, required this.name});

  final int id;
  final String name;
}

class ActivityUnit {
  ActivityUnit({required this.id, required this.name});

  final int id;
  final String name;
}
