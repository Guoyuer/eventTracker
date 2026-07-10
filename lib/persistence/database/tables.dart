import 'package:drift/drift.dart';

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint(
    'NOT NULL COLLATE NOCASE UNIQUE '
    'CHECK (name = trim(name) AND length(name) > 0)',
  )();
}

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().customConstraint(
    'NOT NULL COLLATE NOCASE UNIQUE '
    'CHECK (name = trim(name) AND length(name) > 0)',
  )();

  TextColumn get description => text().nullable()();

  BoolColumn get careTime => boolean()();

  IntColumn get unitId => integer().nullable().references(
    Units,
    #id,
    onDelete: KeyAction.restrict,
  )();
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
