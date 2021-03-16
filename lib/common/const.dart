import 'package:flutter/material.dart';
import '../DAO/UnitsProvider.dart';

// ignore: must_be_immutable

class Global {
  static List<String> units;
  static UnitDbProvider unitProvide = new UnitDbProvider();

  static Future init() async {
    units = await unitProvide.getAllUsers();
    print(units);
  }
}
