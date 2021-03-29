// enum Unit { duration, number, time, distance } //小时、个数、次、距离

class EventModel {
  int id;
  String name;
  String description;
  String units;

  EventModel(String name, String desc, String units) {
    this.name = name;
    this.description = desc;
    this.units = units;
  }
}
