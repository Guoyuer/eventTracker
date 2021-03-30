import 'dart:convert';

class EventModel {
  //这里直接面向数据库
  int id;
  String name;
  String description;
  String unit; //单位及其累计
  int careTime;


  EventModel(String name, String desc, bool careTime, String unit) {
    //这里面向输入，构造函数里完成面向数据库的转换
    this.name = name;
    this.description = desc;
    Map<String, double> tmp = Map();
    tmp[unit] = 0;
    this.unit = jsonEncode(tmp); // 记录同时累计时间
    if (careTime)
      this.careTime = 1;
    else
      this.careTime = 0;
  }
}
