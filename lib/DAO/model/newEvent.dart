enum Unit { duration, number, time, distance } //小时、个数、次、距离

class NewEventModel {
  String eventName;
  String eventDesc;
  Unit unit;

  NewEventModel({this.eventName, this.eventDesc});
}
