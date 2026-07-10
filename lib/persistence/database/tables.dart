import 'package:drift/drift.dart';

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint(
    'NOT NULL COLLATE NOCASE UNIQUE '
    'CHECK (name = trim(name) AND length(name) > 0)',
  )();

  TextColumn get description => text().nullable()();

  BoolColumn get careTime => boolean()();

  TextColumn get unit => text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (unit IS NULL OR (unit = trim(unit) AND length(unit) > 0))',
  ];
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
    'CHECK (value IS NULL OR abs(value) <= 1.7976931348623157e308)',
  ];
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint(
    'NOT NULL COLLATE NOCASE UNIQUE '
    'CHECK (name = trim(name) AND length(name) > 0)',
  )();
}
