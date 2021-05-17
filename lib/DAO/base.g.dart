// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class Step extends DataClass implements Insertable<Step> {
  final int id;
  final int step;
  final DateTime time;
  Step({required this.id, required this.step, required this.time});
  factory Step.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return Step(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      step: intType.mapFromDatabaseResponse(data['${effectivePrefix}step'])!,
      time:
          dateTimeType.mapFromDatabaseResponse(data['${effectivePrefix}time'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['step'] = Variable<int>(step);
    map['time'] = Variable<DateTime>(time);
    return map;
  }

  StepsCompanion toCompanion(bool nullToAbsent) {
    return StepsCompanion(
      id: Value(id),
      step: Value(step),
      time: Value(time),
    );
  }

  factory Step.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Step(
      id: serializer.fromJson<int>(json['id']),
      step: serializer.fromJson<int>(json['step']),
      time: serializer.fromJson<DateTime>(json['time']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'step': serializer.toJson<int>(step),
      'time': serializer.toJson<DateTime>(time),
    };
  }

  Step copyWith({int? id, int? step, DateTime? time}) => Step(
        id: id ?? this.id,
        step: step ?? this.step,
        time: time ?? this.time,
      );
  @override
  String toString() {
    return (StringBuffer('Step(')
          ..write('id: $id, ')
          ..write('step: $step, ')
          ..write('time: $time')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(id.hashCode, $mrjc(step.hashCode, time.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Step &&
          other.id == this.id &&
          other.step == this.step &&
          other.time == this.time);
}

class StepsCompanion extends UpdateCompanion<Step> {
  final Value<int> id;
  final Value<int> step;
  final Value<DateTime> time;
  const StepsCompanion({
    this.id = const Value.absent(),
    this.step = const Value.absent(),
    this.time = const Value.absent(),
  });
  StepsCompanion.insert({
    this.id = const Value.absent(),
    this.step = const Value.absent(),
    required DateTime time,
  }) : time = Value(time);
  static Insertable<Step> custom({
    Expression<int>? id,
    Expression<int>? step,
    Expression<DateTime>? time,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (step != null) 'step': step,
      if (time != null) 'time': time,
    });
  }

  StepsCompanion copyWith(
      {Value<int>? id, Value<int>? step, Value<DateTime>? time}) {
    return StepsCompanion(
      id: id ?? this.id,
      step: step ?? this.step,
      time: time ?? this.time,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepsCompanion(')
          ..write('id: $id, ')
          ..write('step: $step, ')
          ..write('time: $time')
          ..write(')'))
        .toString();
  }
}

class $StepsTable extends Steps with TableInfo<$StepsTable, Step> {
  final GeneratedDatabase _db;
  final String? _alias;
  $StepsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedIntColumn step = _constructStep();
  GeneratedIntColumn _constructStep() {
    return GeneratedIntColumn('step', $tableName, false,
        defaultValue: Constant(0));
  }

  final VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedDateTimeColumn time = _constructTime();
  GeneratedDateTimeColumn _constructTime() {
    return GeneratedDateTimeColumn(
      'time',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [id, step, time];
  @override
  $StepsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'steps';
  @override
  final String actualTableName = 'steps';
  @override
  VerificationContext validateIntegrity(Insertable<Step> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('step')) {
      context.handle(
          _stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Step map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Step.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $StepsTable createAlias(String alias) {
    return $StepsTable(_db, alias);
  }
}

class Record extends DataClass implements Insertable<Record> {
  final int id;
  final int eventId;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? value;
  Record(
      {required this.id,
      required this.eventId,
      this.startTime,
      this.endTime,
      this.value});
  factory Record.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    final doubleType = db.typeSystem.forDartType<double>();
    return Record(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      eventId:
          intType.mapFromDatabaseResponse(data['${effectivePrefix}event_id'])!,
      startTime: dateTimeType
          .mapFromDatabaseResponse(data['${effectivePrefix}start_time']),
      endTime: dateTimeType
          .mapFromDatabaseResponse(data['${effectivePrefix}end_time']),
      value:
          doubleType.mapFromDatabaseResponse(data['${effectivePrefix}value']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<int>(eventId);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<DateTime?>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime?>(endTime);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double?>(value);
    }
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory Record.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Record(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<int>(json['eventId']),
      startTime: serializer.fromJson<DateTime?>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      value: serializer.fromJson<double?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<int>(eventId),
      'startTime': serializer.toJson<DateTime?>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'value': serializer.toJson<double?>(value),
    };
  }

  Record copyWith(
          {int? id,
          int? eventId,
          DateTime? startTime,
          DateTime? endTime,
          double? value}) =>
      Record(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        value: value ?? this.value,
      );
  @override
  String toString() {
    return (StringBuffer('Record(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(eventId.hashCode,
          $mrjc(startTime.hashCode, $mrjc(endTime.hashCode, value.hashCode)))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Record &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.value == this.value);
}

class RecordsCompanion extends UpdateCompanion<Record> {
  final Value<int> id;
  final Value<int> eventId;
  final Value<DateTime?> startTime;
  final Value<DateTime?> endTime;
  final Value<double?> value;
  const RecordsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.value = const Value.absent(),
  });
  RecordsCompanion.insert({
    this.id = const Value.absent(),
    required int eventId,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.value = const Value.absent(),
  }) : eventId = Value(eventId);
  static Insertable<Record> custom({
    Expression<int>? id,
    Expression<int>? eventId,
    Expression<DateTime?>? startTime,
    Expression<DateTime?>? endTime,
    Expression<double?>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (value != null) 'value': value,
    });
  }

  RecordsCompanion copyWith(
      {Value<int>? id,
      Value<int>? eventId,
      Value<DateTime?>? startTime,
      Value<DateTime?>? endTime,
      Value<double?>? value}) {
    return RecordsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime?>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime?>(endTime.value);
    }
    if (value.present) {
      map['value'] = Variable<double?>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $RecordsTable extends Records with TableInfo<$RecordsTable, Record> {
  final GeneratedDatabase _db;
  final String? _alias;
  $RecordsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedIntColumn eventId = _constructEventId();
  GeneratedIntColumn _constructEventId() {
    return GeneratedIntColumn(
      'event_id',
      $tableName,
      false,
    );
  }

  final VerificationMeta _startTimeMeta = const VerificationMeta('startTime');
  @override
  late final GeneratedDateTimeColumn startTime = _constructStartTime();
  GeneratedDateTimeColumn _constructStartTime() {
    return GeneratedDateTimeColumn(
      'start_time',
      $tableName,
      true,
    );
  }

  final VerificationMeta _endTimeMeta = const VerificationMeta('endTime');
  @override
  late final GeneratedDateTimeColumn endTime = _constructEndTime();
  GeneratedDateTimeColumn _constructEndTime() {
    return GeneratedDateTimeColumn(
      'end_time',
      $tableName,
      true,
    );
  }

  final VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedRealColumn value = _constructValue();
  GeneratedRealColumn _constructValue() {
    return GeneratedRealColumn(
      'value',
      $tableName,
      true,
    );
  }

  @override
  List<GeneratedColumn> get $columns =>
      [id, eventId, startTime, endTime, value];
  @override
  $RecordsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'records';
  @override
  final String actualTableName = 'records';
  @override
  VerificationContext validateIntegrity(Insertable<Record> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Record map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Record.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(_db, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int id;
  final String name;
  final String? description;
  final bool careTime;
  final int? lastRecordId;
  final String? unit;
  final double sumVal;
  final Duration sumTime;
  Event(
      {required this.id,
      required this.name,
      this.description,
      required this.careTime,
      this.lastRecordId,
      this.unit,
      required this.sumVal,
      required this.sumTime});
  factory Event.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    final boolType = db.typeSystem.forDartType<bool>();
    final doubleType = db.typeSystem.forDartType<double>();
    return Event(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      description: stringType
          .mapFromDatabaseResponse(data['${effectivePrefix}description']),
      careTime: boolType
          .mapFromDatabaseResponse(data['${effectivePrefix}care_time'])!,
      lastRecordId: intType
          .mapFromDatabaseResponse(data['${effectivePrefix}last_record_id']),
      unit: stringType.mapFromDatabaseResponse(data['${effectivePrefix}unit']),
      sumVal: doubleType
          .mapFromDatabaseResponse(data['${effectivePrefix}sum_val'])!,
      sumTime: $EventsTable.$converter0.mapToDart(doubleType
          .mapFromDatabaseResponse(data['${effectivePrefix}sum_time']))!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String?>(description);
    }
    map['care_time'] = Variable<bool>(careTime);
    if (!nullToAbsent || lastRecordId != null) {
      map['last_record_id'] = Variable<int?>(lastRecordId);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String?>(unit);
    }
    map['sum_val'] = Variable<double>(sumVal);
    {
      final converter = $EventsTable.$converter0;
      map['sum_time'] = Variable<double>(converter.mapToSql(sumTime)!);
    }
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      careTime: Value(careTime),
      lastRecordId: lastRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRecordId),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      sumVal: Value(sumVal),
      sumTime: Value(sumTime),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      careTime: serializer.fromJson<bool>(json['careTime']),
      lastRecordId: serializer.fromJson<int?>(json['lastRecordId']),
      unit: serializer.fromJson<String?>(json['unit']),
      sumVal: serializer.fromJson<double>(json['sumVal']),
      sumTime: serializer.fromJson<Duration>(json['sumTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'careTime': serializer.toJson<bool>(careTime),
      'lastRecordId': serializer.toJson<int?>(lastRecordId),
      'unit': serializer.toJson<String?>(unit),
      'sumVal': serializer.toJson<double>(sumVal),
      'sumTime': serializer.toJson<Duration>(sumTime),
    };
  }

  Event copyWith(
          {int? id,
          String? name,
          String? description,
          bool? careTime,
          int? lastRecordId,
          String? unit,
          double? sumVal,
          Duration? sumTime}) =>
      Event(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        careTime: careTime ?? this.careTime,
        lastRecordId: lastRecordId ?? this.lastRecordId,
        unit: unit ?? this.unit,
        sumVal: sumVal ?? this.sumVal,
        sumTime: sumTime ?? this.sumTime,
      );
  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('careTime: $careTime, ')
          ..write('lastRecordId: $lastRecordId, ')
          ..write('unit: $unit, ')
          ..write('sumVal: $sumVal, ')
          ..write('sumTime: $sumTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          name.hashCode,
          $mrjc(
              description.hashCode,
              $mrjc(
                  careTime.hashCode,
                  $mrjc(
                      lastRecordId.hashCode,
                      $mrjc(unit.hashCode,
                          $mrjc(sumVal.hashCode, sumTime.hashCode))))))));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.careTime == this.careTime &&
          other.lastRecordId == this.lastRecordId &&
          other.unit == this.unit &&
          other.sumVal == this.sumVal &&
          other.sumTime == this.sumTime);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> careTime;
  final Value<int?> lastRecordId;
  final Value<String?> unit;
  final Value<double> sumVal;
  final Value<Duration> sumTime;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.careTime = const Value.absent(),
    this.lastRecordId = const Value.absent(),
    this.unit = const Value.absent(),
    this.sumVal = const Value.absent(),
    this.sumTime = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required bool careTime,
    this.lastRecordId = const Value.absent(),
    this.unit = const Value.absent(),
    this.sumVal = const Value.absent(),
    this.sumTime = const Value.absent(),
  })  : name = Value(name),
        careTime = Value(careTime);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String?>? description,
    Expression<bool>? careTime,
    Expression<int?>? lastRecordId,
    Expression<String?>? unit,
    Expression<double>? sumVal,
    Expression<Duration>? sumTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (careTime != null) 'care_time': careTime,
      if (lastRecordId != null) 'last_record_id': lastRecordId,
      if (unit != null) 'unit': unit,
      if (sumVal != null) 'sum_val': sumVal,
      if (sumTime != null) 'sum_time': sumTime,
    });
  }

  EventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<bool>? careTime,
      Value<int?>? lastRecordId,
      Value<String?>? unit,
      Value<double>? sumVal,
      Value<Duration>? sumTime}) {
    return EventsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      careTime: careTime ?? this.careTime,
      lastRecordId: lastRecordId ?? this.lastRecordId,
      unit: unit ?? this.unit,
      sumVal: sumVal ?? this.sumVal,
      sumTime: sumTime ?? this.sumTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String?>(description.value);
    }
    if (careTime.present) {
      map['care_time'] = Variable<bool>(careTime.value);
    }
    if (lastRecordId.present) {
      map['last_record_id'] = Variable<int?>(lastRecordId.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String?>(unit.value);
    }
    if (sumVal.present) {
      map['sum_val'] = Variable<double>(sumVal.value);
    }
    if (sumTime.present) {
      final converter = $EventsTable.$converter0;
      map['sum_time'] = Variable<double>(converter.mapToSql(sumTime.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('careTime: $careTime, ')
          ..write('lastRecordId: $lastRecordId, ')
          ..write('unit: $unit, ')
          ..write('sumVal: $sumVal, ')
          ..write('sumTime: $sumTime')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  final GeneratedDatabase _db;
  final String? _alias;
  $EventsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'not null unique');
  }

  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedTextColumn description = _constructDescription();
  GeneratedTextColumn _constructDescription() {
    return GeneratedTextColumn(
      'description',
      $tableName,
      true,
    );
  }

  final VerificationMeta _careTimeMeta = const VerificationMeta('careTime');
  @override
  late final GeneratedBoolColumn careTime = _constructCareTime();
  GeneratedBoolColumn _constructCareTime() {
    return GeneratedBoolColumn(
      'care_time',
      $tableName,
      false,
    );
  }

  final VerificationMeta _lastRecordIdMeta =
      const VerificationMeta('lastRecordId');
  @override
  late final GeneratedIntColumn lastRecordId = _constructLastRecordId();
  GeneratedIntColumn _constructLastRecordId() {
    return GeneratedIntColumn(
      'last_record_id',
      $tableName,
      true,
    );
  }

  final VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedTextColumn unit = _constructUnit();
  GeneratedTextColumn _constructUnit() {
    return GeneratedTextColumn(
      'unit',
      $tableName,
      true,
    );
  }

  final VerificationMeta _sumValMeta = const VerificationMeta('sumVal');
  @override
  late final GeneratedRealColumn sumVal = _constructSumVal();
  GeneratedRealColumn _constructSumVal() {
    return GeneratedRealColumn('sum_val', $tableName, false,
        defaultValue: Constant(0));
  }

  final VerificationMeta _sumTimeMeta = const VerificationMeta('sumTime');
  @override
  late final GeneratedRealColumn sumTime = _constructSumTime();
  GeneratedRealColumn _constructSumTime() {
    return GeneratedRealColumn('sum_time', $tableName, false,
        defaultValue: Constant(0));
  }

  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, careTime, lastRecordId, unit, sumVal, sumTime];
  @override
  $EventsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'events';
  @override
  final String actualTableName = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('care_time')) {
      context.handle(_careTimeMeta,
          careTime.isAcceptableOrUnknown(data['care_time']!, _careTimeMeta));
    } else if (isInserting) {
      context.missing(_careTimeMeta);
    }
    if (data.containsKey('last_record_id')) {
      context.handle(
          _lastRecordIdMeta,
          lastRecordId.isAcceptableOrUnknown(
              data['last_record_id']!, _lastRecordIdMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('sum_val')) {
      context.handle(_sumValMeta,
          sumVal.isAcceptableOrUnknown(data['sum_val']!, _sumValMeta));
    }
    context.handle(_sumTimeMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Event.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(_db, alias);
  }

  static TypeConverter<Duration, double> $converter0 =
      const DurationConverter();
}

class Unit extends DataClass implements Insertable<Unit> {
  final int id;
  final String name;
  Unit({required this.id, required this.name});
  factory Unit.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final stringType = db.typeSystem.forDartType<String>();
    return Unit(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: stringType.mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory Unit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return Unit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Unit copyWith({int? id, String? name}) => Unit(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  @override
  String toString() {
    return (StringBuffer('Unit(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(id.hashCode, name.hashCode));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is Unit && other.id == this.id && other.name == this.name);
}

class UnitsCompanion extends UpdateCompanion<Unit> {
  final Value<int> id;
  final Value<String> name;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  UnitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Unit> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  UnitsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return UnitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, Unit> {
  final GeneratedDatabase _db;
  final String? _alias;
  $UnitsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn('id', $tableName, false,
        hasAutoIncrement: true, declaredAsPrimaryKey: true);
  }

  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedTextColumn name = _constructName();
  GeneratedTextColumn _constructName() {
    return GeneratedTextColumn('name', $tableName, false,
        $customConstraints: 'not null unique');
  }

  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  $UnitsTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'units';
  @override
  final String actualTableName = 'units';
  @override
  VerificationContext validateIntegrity(Insertable<Unit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Unit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return Unit.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(_db, alias);
  }
}

class StepOffsetData extends DataClass implements Insertable<StepOffsetData> {
  final int id;
  final int step;
  final DateTime time;
  StepOffsetData({required this.id, required this.step, required this.time});
  factory StepOffsetData.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    final intType = db.typeSystem.forDartType<int>();
    final dateTimeType = db.typeSystem.forDartType<DateTime>();
    return StepOffsetData(
      id: intType.mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      step: intType.mapFromDatabaseResponse(data['${effectivePrefix}step'])!,
      time:
          dateTimeType.mapFromDatabaseResponse(data['${effectivePrefix}time'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['step'] = Variable<int>(step);
    map['time'] = Variable<DateTime>(time);
    return map;
  }

  StepOffsetCompanion toCompanion(bool nullToAbsent) {
    return StepOffsetCompanion(
      id: Value(id),
      step: Value(step),
      time: Value(time),
    );
  }

  factory StepOffsetData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return StepOffsetData(
      id: serializer.fromJson<int>(json['id']),
      step: serializer.fromJson<int>(json['step']),
      time: serializer.fromJson<DateTime>(json['time']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'step': serializer.toJson<int>(step),
      'time': serializer.toJson<DateTime>(time),
    };
  }

  StepOffsetData copyWith({int? id, int? step, DateTime? time}) =>
      StepOffsetData(
        id: id ?? this.id,
        step: step ?? this.step,
        time: time ?? this.time,
      );
  @override
  String toString() {
    return (StringBuffer('StepOffsetData(')
          ..write('id: $id, ')
          ..write('step: $step, ')
          ..write('time: $time')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(id.hashCode, $mrjc(step.hashCode, time.hashCode)));
  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      (other is StepOffsetData &&
          other.id == this.id &&
          other.step == this.step &&
          other.time == this.time);
}

class StepOffsetCompanion extends UpdateCompanion<StepOffsetData> {
  final Value<int> id;
  final Value<int> step;
  final Value<DateTime> time;
  const StepOffsetCompanion({
    this.id = const Value.absent(),
    this.step = const Value.absent(),
    this.time = const Value.absent(),
  });
  StepOffsetCompanion.insert({
    required int id,
    this.step = const Value.absent(),
    required DateTime time,
  })  : id = Value(id),
        time = Value(time);
  static Insertable<StepOffsetData> custom({
    Expression<int>? id,
    Expression<int>? step,
    Expression<DateTime>? time,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (step != null) 'step': step,
      if (time != null) 'time': time,
    });
  }

  StepOffsetCompanion copyWith(
      {Value<int>? id, Value<int>? step, Value<DateTime>? time}) {
    return StepOffsetCompanion(
      id: id ?? this.id,
      step: step ?? this.step,
      time: time ?? this.time,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepOffsetCompanion(')
          ..write('id: $id, ')
          ..write('step: $step, ')
          ..write('time: $time')
          ..write(')'))
        .toString();
  }
}

class $StepOffsetTable extends StepOffset
    with TableInfo<$StepOffsetTable, StepOffsetData> {
  final GeneratedDatabase _db;
  final String? _alias;
  $StepOffsetTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedIntColumn id = _constructId();
  GeneratedIntColumn _constructId() {
    return GeneratedIntColumn(
      'id',
      $tableName,
      false,
    );
  }

  final VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedIntColumn step = _constructStep();
  GeneratedIntColumn _constructStep() {
    return GeneratedIntColumn('step', $tableName, false,
        defaultValue: Constant(0));
  }

  final VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedDateTimeColumn time = _constructTime();
  GeneratedDateTimeColumn _constructTime() {
    return GeneratedDateTimeColumn(
      'time',
      $tableName,
      false,
    );
  }

  @override
  List<GeneratedColumn> get $columns => [id, step, time];
  @override
  $StepOffsetTable get asDslTable => this;
  @override
  String get $tableName => _alias ?? 'step_offset';
  @override
  final String actualTableName = 'step_offset';
  @override
  VerificationContext validateIntegrity(Insertable<StepOffsetData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
          _stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => <GeneratedColumn>{};
  @override
  StepOffsetData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : null;
    return StepOffsetData.fromData(data, _db, prefix: effectivePrefix);
  }

  @override
  $StepOffsetTable createAlias(String alias) {
    return $StepOffsetTable(_db, alias);
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final $StepsTable steps = $StepsTable(this);
  late final Index stepTime =
      Index('step_time', 'CREATE INDEX step_time ON steps(time);');
  late final $RecordsTable records = $RecordsTable(this);
  late final Index recordsEndTime = Index('records_end_time',
      'CREATE INDEX records_end_time ON records(end_time);');
  late final Index recordsStartTime = Index('records_start_time',
      'CREATE INDEX records_start_time ON records(start_time);');
  late final Index recordsEventId = Index('records_event_id',
      'CREATE INDEX records_event_id ON records(event_id);');
  late final $EventsTable events = $EventsTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $StepOffsetTable stepOffset = $StepOffsetTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        steps,
        stepTime,
        records,
        recordsEndTime,
        recordsStartTime,
        recordsEventId,
        events,
        units,
        stepOffset
      ];
}
