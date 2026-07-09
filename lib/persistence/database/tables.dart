import 'package:drift/drift.dart';

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint("not null unique")();

  TextColumn get description => text().nullable()();

  BoolColumn get careTime => boolean()();

  TextColumn get unit => text().nullable()();
}

class Records extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get eventId =>
      integer().references(Events, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get startTime => dateTime().nullable()();

  DateTimeColumn get endTime => dateTime().nullable()();

  RealColumn get value => real().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK ('
        '(start_time IS NULL AND end_time IS NOT NULL) OR '
        '(start_time IS NOT NULL AND end_time IS NULL AND value IS NULL) OR '
        '(start_time IS NOT NULL AND end_time IS NOT NULL '
        'AND end_time >= start_time)'
        ')',
  ];
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint("not null unique")();
}
