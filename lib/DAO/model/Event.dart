import 'dart:convert';

class EventModelDisplay {
  int id; //
  String name;
  bool careTime;
  bool isActive;

  EventModelDisplay(this.id, this.name, this.careTime, this.isActive);
}

class EventModel {
  //这里直接面向数据库
  int id;
  String name;
  String description;
  int careTime;
  String unit; //单位及其累计。可以不附加单位的。
  int lastRecord; //在record变动的时候，这个值应该变动。靠eventId来find

  EventModel(String name, String desc, bool careTime, String unit) {
    //这里面向输入，构造函数里完成面向数据库的转换
    this.name = name;
    this.description = desc;
    if (unit != null && unit.isNotEmpty) {
      Map<String, double> tmp = Map();
      tmp[unit] = 0;
      this.unit = jsonEncode(tmp); // 记录同时累计时间
    } else {
      this.unit = "";
    }
    if (careTime)
      this.careTime = 1;
    else
      this.careTime = 0;
  }
}
