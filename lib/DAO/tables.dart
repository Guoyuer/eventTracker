import 'package:moor_flutter/moor_flutter.dart';

//tables and converters
class DurationConverter extends TypeConverter<Duration, double> {
  const DurationConverter();

  @override
  Duration? mapToDart(double? fromDb) {
    return Duration(seconds: fromDb!.toInt());
  }

  @override
  double? mapToSql(Duration? value) {
    return value!.inSeconds.toDouble();
  }
}

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint("not null unique")();

  TextColumn get description => text().nullable()();

  BoolColumn get careTime => boolean()();

  IntColumn get lastRecordId => integer().nullable()(); //初次添加时可空
  TextColumn get unit => text().nullable()();

  //冗余信息，加速列表显示
  RealColumn get sumVal => real().withDefault(Constant(0))();

  RealColumn get sumTime => real()
      .withDefault(Constant(0)) // 对于TimingEvent以秒的形式记录总时间，对于PlainEvent则记录次数
      .map(const DurationConverter())();//with default了就不会nullable了
}

class Records extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get eventId => integer()();

  DateTimeColumn get startTime => dateTime().nullable()();

  //startTime可为空，当不careTime的事件开始时

  DateTimeColumn get endTime =>
      dateTime().nullable()(); //endTime可为空，当careTime的事件开始时。

  RealColumn get value => real().nullable()();
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
}

class Steps extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get step => integer().withDefault(Constant(0))();

  DateTimeColumn get time => dateTime()(); //要加索引，会用where框选每天的
}

class StepOffset extends Table {
  //存放当天的步数偏移量
  IntColumn get id => integer()();

  IntColumn get step => integer().withDefault(Constant(0))();

  DateTimeColumn get time => dateTime()();
}
