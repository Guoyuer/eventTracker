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
    // Bound is written without scientific notation on purpose: drift_dev
    // 2.34.0 (via sqlparser 0.44.5) re-parses this CHECK text when producing
    // test/generated_migrations/schema_v6.dart, and its numeric-literal
    // tokenizer computes `beforeDecimal * pow(10, exponent)` using integer
    // (not floating-point) exponentiation. For an exponent like 308 that
    // overflows Dart's 64-bit ints and silently wraps to 0, turning this
    // bound into `0.0`. A plain decimal literal has no exponent, so it
    // survives the round trip intact. 1e15 is still far beyond any value
    // this app will ever record; the real goal of this CHECK is only to
    // reject non-finite (infinite) doubles as a defense-in-depth backstop
    // behind validateRecordValue's `isFinite` check.
    'CHECK (value IS NULL OR abs(value) <= 1000000000000000.0)',
  ];
}
