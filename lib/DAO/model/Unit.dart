final String columnId = 'id';
final String columnUnit = 'name';

class UnitModel {
  //数据库里的一行
  int id;
  String unit;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnId: id,
      columnUnit: unit,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  UnitModel(String unit) {
    this.unit = unit;
  }

  UnitModel.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    unit = map[columnUnit];
  }
}
