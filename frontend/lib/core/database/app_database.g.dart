// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta('birthDate');
  @override
  late final GeneratedColumn<String> birthDate = GeneratedColumn<String>(
    'birth_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta('heightCm');
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta('targetWeightKg');
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityLevelMeta = const VerificationMeta('activityLevel');
  @override
  late final GeneratedColumn<String> activityLevel = GeneratedColumn<String>(
    'activity_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trainingTypeMeta = const VerificationMeta('trainingType');
  @override
  late final GeneratedColumn<String> trainingType = GeneratedColumn<String>(
    'training_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weeklyChangeKgMeta = const VerificationMeta('weeklyChangeKg');
  @override
  late final GeneratedColumn<double> weeklyChangeKg = GeneratedColumn<double>(
    'weekly_change_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionNoteMeta = const VerificationMeta('conditionNote');
  @override
  late final GeneratedColumn<String> conditionNote = GeneratedColumn<String>(
    'condition_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitsSugarMeta = const VerificationMeta('limitsSugar');
  @override
  late final GeneratedColumn<bool> limitsSugar = GeneratedColumn<bool>(
    'limits_sugar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("limits_sugar" IN (0, 1))'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sex,
    birthDate,
    heightCm,
    weightKg,
    targetWeightKg,
    activityLevel,
    trainingType,
    weeklyChangeKg,
    conditionNote,
    limitsSugar,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sex')) {
      context.handle(_sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(_birthDateMeta, birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta));
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(_heightCmMeta, heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta));
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta, weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(data['target_weight_kg']!, _targetWeightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_targetWeightKgMeta);
    }
    if (data.containsKey('activity_level')) {
      context.handle(
        _activityLevelMeta,
        activityLevel.isAcceptableOrUnknown(data['activity_level']!, _activityLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_activityLevelMeta);
    }
    if (data.containsKey('training_type')) {
      context.handle(_trainingTypeMeta, trainingType.isAcceptableOrUnknown(data['training_type']!, _trainingTypeMeta));
    } else if (isInserting) {
      context.missing(_trainingTypeMeta);
    }
    if (data.containsKey('weekly_change_kg')) {
      context.handle(
        _weeklyChangeKgMeta,
        weeklyChangeKg.isAcceptableOrUnknown(data['weekly_change_kg']!, _weeklyChangeKgMeta),
      );
    }
    if (data.containsKey('condition_note')) {
      context.handle(
        _conditionNoteMeta,
        conditionNote.isAcceptableOrUnknown(data['condition_note']!, _conditionNoteMeta),
      );
    }
    if (data.containsKey('limits_sugar')) {
      context.handle(_limitsSugarMeta, limitsSugar.isAcceptableOrUnknown(data['limits_sugar']!, _limitsSugarMeta));
    } else if (isInserting) {
      context.missing(_limitsSugarMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sex: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sex'])!,
      birthDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}birth_date'])!,
      heightCm: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}height_cm'])!,
      weightKg: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}weight_kg'])!,
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      )!,
      activityLevel: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}activity_level'])!,
      trainingType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}training_type'])!,
      weeklyChangeKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weekly_change_kg'],
      ),
      conditionNote: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}condition_note']),
      limitsSugar: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}limits_sugar'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final String sex;

  /// `yyyy-MM-dd`, so the birthday never shifts with the time zone.
  final String birthDate;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final String activityLevel;
  final String trainingType;
  final double? weeklyChangeKg;
  final String? conditionNote;
  final bool limitsSugar;
  const ProfileRow({
    required this.id,
    required this.sex,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.trainingType,
    this.weeklyChangeKg,
    this.conditionNote,
    required this.limitsSugar,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sex'] = Variable<String>(sex);
    map['birth_date'] = Variable<String>(birthDate);
    map['height_cm'] = Variable<double>(heightCm);
    map['weight_kg'] = Variable<double>(weightKg);
    map['target_weight_kg'] = Variable<double>(targetWeightKg);
    map['activity_level'] = Variable<String>(activityLevel);
    map['training_type'] = Variable<String>(trainingType);
    if (!nullToAbsent || weeklyChangeKg != null) {
      map['weekly_change_kg'] = Variable<double>(weeklyChangeKg);
    }
    if (!nullToAbsent || conditionNote != null) {
      map['condition_note'] = Variable<String>(conditionNote);
    }
    map['limits_sugar'] = Variable<bool>(limitsSugar);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      sex: Value(sex),
      birthDate: Value(birthDate),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      targetWeightKg: Value(targetWeightKg),
      activityLevel: Value(activityLevel),
      trainingType: Value(trainingType),
      weeklyChangeKg: weeklyChangeKg == null && nullToAbsent ? const Value.absent() : Value(weeklyChangeKg),
      conditionNote: conditionNote == null && nullToAbsent ? const Value.absent() : Value(conditionNote),
      limitsSugar: Value(limitsSugar),
    );
  }

  factory ProfileRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      sex: serializer.fromJson<String>(json['sex']),
      birthDate: serializer.fromJson<String>(json['birthDate']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      targetWeightKg: serializer.fromJson<double>(json['targetWeightKg']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
      trainingType: serializer.fromJson<String>(json['trainingType']),
      weeklyChangeKg: serializer.fromJson<double?>(json['weeklyChangeKg']),
      conditionNote: serializer.fromJson<String?>(json['conditionNote']),
      limitsSugar: serializer.fromJson<bool>(json['limitsSugar']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sex': serializer.toJson<String>(sex),
      'birthDate': serializer.toJson<String>(birthDate),
      'heightCm': serializer.toJson<double>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'targetWeightKg': serializer.toJson<double>(targetWeightKg),
      'activityLevel': serializer.toJson<String>(activityLevel),
      'trainingType': serializer.toJson<String>(trainingType),
      'weeklyChangeKg': serializer.toJson<double?>(weeklyChangeKg),
      'conditionNote': serializer.toJson<String?>(conditionNote),
      'limitsSugar': serializer.toJson<bool>(limitsSugar),
    };
  }

  ProfileRow copyWith({
    int? id,
    String? sex,
    String? birthDate,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? activityLevel,
    String? trainingType,
    Value<double?> weeklyChangeKg = const Value.absent(),
    Value<String?> conditionNote = const Value.absent(),
    bool? limitsSugar,
  }) => ProfileRow(
    id: id ?? this.id,
    sex: sex ?? this.sex,
    birthDate: birthDate ?? this.birthDate,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    activityLevel: activityLevel ?? this.activityLevel,
    trainingType: trainingType ?? this.trainingType,
    weeklyChangeKg: weeklyChangeKg.present ? weeklyChangeKg.value : this.weeklyChangeKg,
    conditionNote: conditionNote.present ? conditionNote.value : this.conditionNote,
    limitsSugar: limitsSugar ?? this.limitsSugar,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      sex: data.sex.present ? data.sex.value : this.sex,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      targetWeightKg: data.targetWeightKg.present ? data.targetWeightKg.value : this.targetWeightKg,
      activityLevel: data.activityLevel.present ? data.activityLevel.value : this.activityLevel,
      trainingType: data.trainingType.present ? data.trainingType.value : this.trainingType,
      weeklyChangeKg: data.weeklyChangeKg.present ? data.weeklyChangeKg.value : this.weeklyChangeKg,
      conditionNote: data.conditionNote.present ? data.conditionNote.value : this.conditionNote,
      limitsSugar: data.limitsSugar.present ? data.limitsSugar.value : this.limitsSugar,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('trainingType: $trainingType, ')
          ..write('weeklyChangeKg: $weeklyChangeKg, ')
          ..write('conditionNote: $conditionNote, ')
          ..write('limitsSugar: $limitsSugar')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sex,
    birthDate,
    heightCm,
    weightKg,
    targetWeightKg,
    activityLevel,
    trainingType,
    weeklyChangeKg,
    conditionNote,
    limitsSugar,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.sex == this.sex &&
          other.birthDate == this.birthDate &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.targetWeightKg == this.targetWeightKg &&
          other.activityLevel == this.activityLevel &&
          other.trainingType == this.trainingType &&
          other.weeklyChangeKg == this.weeklyChangeKg &&
          other.conditionNote == this.conditionNote &&
          other.limitsSugar == this.limitsSugar);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<String> sex;
  final Value<String> birthDate;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<double> targetWeightKg;
  final Value<String> activityLevel;
  final Value<String> trainingType;
  final Value<double?> weeklyChangeKg;
  final Value<String?> conditionNote;
  final Value<bool> limitsSugar;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.trainingType = const Value.absent(),
    this.weeklyChangeKg = const Value.absent(),
    this.conditionNote = const Value.absent(),
    this.limitsSugar = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String sex,
    required String birthDate,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required String activityLevel,
    required String trainingType,
    this.weeklyChangeKg = const Value.absent(),
    this.conditionNote = const Value.absent(),
    required bool limitsSugar,
  }) : sex = Value(sex),
       birthDate = Value(birthDate),
       heightCm = Value(heightCm),
       weightKg = Value(weightKg),
       targetWeightKg = Value(targetWeightKg),
       activityLevel = Value(activityLevel),
       trainingType = Value(trainingType),
       limitsSugar = Value(limitsSugar);
  static Insertable<ProfileRow> custom({
    Expression<int>? id,
    Expression<String>? sex,
    Expression<String>? birthDate,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<double>? targetWeightKg,
    Expression<String>? activityLevel,
    Expression<String>? trainingType,
    Expression<double>? weeklyChangeKg,
    Expression<String>? conditionNote,
    Expression<bool>? limitsSugar,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sex != null) 'sex': sex,
      if (birthDate != null) 'birth_date': birthDate,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (trainingType != null) 'training_type': trainingType,
      if (weeklyChangeKg != null) 'weekly_change_kg': weeklyChangeKg,
      if (conditionNote != null) 'condition_note': conditionNote,
      if (limitsSugar != null) 'limits_sugar': limitsSugar,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? sex,
    Value<String>? birthDate,
    Value<double>? heightCm,
    Value<double>? weightKg,
    Value<double>? targetWeightKg,
    Value<String>? activityLevel,
    Value<String>? trainingType,
    Value<double?>? weeklyChangeKg,
    Value<String?>? conditionNote,
    Value<bool>? limitsSugar,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      trainingType: trainingType ?? this.trainingType,
      weeklyChangeKg: weeklyChangeKg ?? this.weeklyChangeKg,
      conditionNote: conditionNote ?? this.conditionNote,
      limitsSugar: limitsSugar ?? this.limitsSugar,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<String>(birthDate.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(activityLevel.value);
    }
    if (trainingType.present) {
      map['training_type'] = Variable<String>(trainingType.value);
    }
    if (weeklyChangeKg.present) {
      map['weekly_change_kg'] = Variable<double>(weeklyChangeKg.value);
    }
    if (conditionNote.present) {
      map['condition_note'] = Variable<String>(conditionNote.value);
    }
    if (limitsSugar.present) {
      map['limits_sugar'] = Variable<bool>(limitsSugar.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('trainingType: $trainingType, ')
          ..write('weeklyChangeKg: $weeklyChangeKg, ')
          ..write('conditionNote: $conditionNote, ')
          ..write('limitsSugar: $limitsSugar')
          ..write(')'))
        .toString();
  }
}

class $ProfileConditionsTable extends ProfileConditions with TableInfo<$ProfileConditionsTable, ProfileConditionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileConditionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conditionKeyMeta = const VerificationMeta('conditionKey');
  @override
  late final GeneratedColumn<String> conditionKey = GeneratedColumn<String>(
    'condition_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [conditionKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_conditions';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileConditionRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('condition_key')) {
      context.handle(_conditionKeyMeta, conditionKey.isAcceptableOrUnknown(data['condition_key']!, _conditionKeyMeta));
    } else if (isInserting) {
      context.missing(_conditionKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conditionKey};
  @override
  ProfileConditionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileConditionRow(
      conditionKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}condition_key'])!,
    );
  }

  @override
  $ProfileConditionsTable createAlias(String alias) {
    return $ProfileConditionsTable(attachedDatabase, alias);
  }
}

class ProfileConditionRow extends DataClass implements Insertable<ProfileConditionRow> {
  final String conditionKey;
  const ProfileConditionRow({required this.conditionKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['condition_key'] = Variable<String>(conditionKey);
    return map;
  }

  ProfileConditionsCompanion toCompanion(bool nullToAbsent) {
    return ProfileConditionsCompanion(conditionKey: Value(conditionKey));
  }

  factory ProfileConditionRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileConditionRow(conditionKey: serializer.fromJson<String>(json['conditionKey']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'conditionKey': serializer.toJson<String>(conditionKey)};
  }

  ProfileConditionRow copyWith({String? conditionKey}) =>
      ProfileConditionRow(conditionKey: conditionKey ?? this.conditionKey);
  ProfileConditionRow copyWithCompanion(ProfileConditionsCompanion data) {
    return ProfileConditionRow(conditionKey: data.conditionKey.present ? data.conditionKey.value : this.conditionKey);
  }

  @override
  String toString() {
    return (StringBuffer('ProfileConditionRow(')
          ..write('conditionKey: $conditionKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => conditionKey.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ProfileConditionRow && other.conditionKey == this.conditionKey);
}

class ProfileConditionsCompanion extends UpdateCompanion<ProfileConditionRow> {
  final Value<String> conditionKey;
  final Value<int> rowid;
  const ProfileConditionsCompanion({this.conditionKey = const Value.absent(), this.rowid = const Value.absent()});
  ProfileConditionsCompanion.insert({required String conditionKey, this.rowid = const Value.absent()})
    : conditionKey = Value(conditionKey);
  static Insertable<ProfileConditionRow> custom({Expression<String>? conditionKey, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (conditionKey != null) 'condition_key': conditionKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileConditionsCompanion copyWith({Value<String>? conditionKey, Value<int>? rowid}) {
    return ProfileConditionsCompanion(conditionKey: conditionKey ?? this.conditionKey, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conditionKey.present) {
      map['condition_key'] = Variable<String>(conditionKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileConditionsCompanion(')
          ..write('conditionKey: $conditionKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $ProfileConditionsTable profileConditions = $ProfileConditionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [profiles, profileConditions];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required String sex,
  required String birthDate,
  required double heightCm,
  required double weightKg,
  required double targetWeightKg,
  required String activityLevel,
  required String trainingType,
  Value<double?> weeklyChangeKg,
  Value<String?> conditionNote,
  required bool limitsSugar,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> sex,
  Value<String> birthDate,
  Value<double> heightCm,
  Value<double> weightKg,
  Value<double> targetWeightKg,
  Value<String> activityLevel,
  Value<String> trainingType,
  Value<double?> weeklyChangeKg,
  Value<String?> conditionNote,
  Value<bool> limitsSugar,
});

class $$ProfilesTableFilterComposer extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex => $composableBuilder(column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetWeightKg =>
      $composableBuilder(column: $table.targetWeightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityLevel =>
      $composableBuilder(column: $table.activityLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trainingType =>
      $composableBuilder(column: $table.trainingType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weeklyChangeKg =>
      $composableBuilder(column: $table.weeklyChangeKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conditionNote =>
      $composableBuilder(column: $table.conditionNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get limitsSugar =>
      $composableBuilder(column: $table.limitsSugar, builder: (column) => ColumnFilters(column));
}

class $$ProfilesTableOrderingComposer extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetWeightKg =>
      $composableBuilder(column: $table.targetWeightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityLevel =>
      $composableBuilder(column: $table.activityLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trainingType =>
      $composableBuilder(column: $table.trainingType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weeklyChangeKg =>
      $composableBuilder(column: $table.weeklyChangeKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conditionNote =>
      $composableBuilder(column: $table.conditionNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get limitsSugar =>
      $composableBuilder(column: $table.limitsSugar, builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sex => $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get birthDate => $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<double> get heightCm => $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg => $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get targetWeightKg =>
      $composableBuilder(column: $table.targetWeightKg, builder: (column) => column);

  GeneratedColumn<String> get activityLevel =>
      $composableBuilder(column: $table.activityLevel, builder: (column) => column);

  GeneratedColumn<String> get trainingType =>
      $composableBuilder(column: $table.trainingType, builder: (column) => column);

  GeneratedColumn<double> get weeklyChangeKg =>
      $composableBuilder(column: $table.weeklyChangeKg, builder: (column) => column);

  GeneratedColumn<String> get conditionNote =>
      $composableBuilder(column: $table.conditionNote, builder: (column) => column);

  GeneratedColumn<bool> get limitsSugar => $composableBuilder(column: $table.limitsSugar, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<String> birthDate = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<double> targetWeightKg = const Value.absent(),
                Value<String> activityLevel = const Value.absent(),
                Value<String> trainingType = const Value.absent(),
                Value<double?> weeklyChangeKg = const Value.absent(),
                Value<String?> conditionNote = const Value.absent(),
                Value<bool> limitsSugar = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                sex: sex,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                targetWeightKg: targetWeightKg,
                activityLevel: activityLevel,
                trainingType: trainingType,
                weeklyChangeKg: weeklyChangeKg,
                conditionNote: conditionNote,
                limitsSugar: limitsSugar,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sex,
                required String birthDate,
                required double heightCm,
                required double weightKg,
                required double targetWeightKg,
                required String activityLevel,
                required String trainingType,
                Value<double?> weeklyChangeKg = const Value.absent(),
                Value<String?> conditionNote = const Value.absent(),
                required bool limitsSugar,
              }) => ProfilesCompanion.insert(
                id: id,
                sex: sex,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                targetWeightKg: targetWeightKg,
                activityLevel: activityLevel,
                trainingType: trainingType,
                weeklyChangeKg: weeklyChangeKg,
                conditionNote: conditionNote,
                limitsSugar: limitsSugar,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, ProfileRow>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$ProfileConditionsTableCreateCompanionBuilder = ProfileConditionsCompanion Function({
  required String conditionKey,
  Value<int> rowid,
});
typedef $$ProfileConditionsTableUpdateCompanionBuilder = ProfileConditionsCompanion Function({
  Value<String> conditionKey,
  Value<int> rowid,
});

class $$ProfileConditionsTableFilterComposer extends Composer<_$AppDatabase, $ProfileConditionsTable> {
  $$ProfileConditionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conditionKey =>
      $composableBuilder(column: $table.conditionKey, builder: (column) => ColumnFilters(column));
}

class $$ProfileConditionsTableOrderingComposer extends Composer<_$AppDatabase, $ProfileConditionsTable> {
  $$ProfileConditionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conditionKey =>
      $composableBuilder(column: $table.conditionKey, builder: (column) => ColumnOrderings(column));
}

class $$ProfileConditionsTableAnnotationComposer extends Composer<_$AppDatabase, $ProfileConditionsTable> {
  $$ProfileConditionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conditionKey =>
      $composableBuilder(column: $table.conditionKey, builder: (column) => column);
}

class $$ProfileConditionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileConditionsTable,
          ProfileConditionRow,
          $$ProfileConditionsTableFilterComposer,
          $$ProfileConditionsTableOrderingComposer,
          $$ProfileConditionsTableAnnotationComposer,
          $$ProfileConditionsTableCreateCompanionBuilder,
          $$ProfileConditionsTableUpdateCompanionBuilder,
          (ProfileConditionRow, BaseReferences<_$AppDatabase, $ProfileConditionsTable, ProfileConditionRow>),
          ProfileConditionRow,
          PrefetchHooks Function()
        > {
  $$ProfileConditionsTableTableManager(_$AppDatabase db, $ProfileConditionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProfileConditionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProfileConditionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProfileConditionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> conditionKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ProfileConditionsCompanion(conditionKey: conditionKey, rowid: rowid),
          createCompanionCallback: ({required String conditionKey, Value<int> rowid = const Value.absent()}) =>
              ProfileConditionsCompanion.insert(conditionKey: conditionKey, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfileConditionsTable, ProfileConditionRow>(table),
                  BaseReferences<_$AppDatabase, $ProfileConditionsTable, ProfileConditionRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileConditionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileConditionsTable,
      ProfileConditionRow,
      $$ProfileConditionsTableFilterComposer,
      $$ProfileConditionsTableOrderingComposer,
      $$ProfileConditionsTableAnnotationComposer,
      $$ProfileConditionsTableCreateCompanionBuilder,
      $$ProfileConditionsTableUpdateCompanionBuilder,
      (ProfileConditionRow, BaseReferences<_$AppDatabase, $ProfileConditionsTable, ProfileConditionRow>),
      ProfileConditionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles => $$ProfilesTableTableManager(_db, _db.profiles);
  $$ProfileConditionsTableTableManager get profileConditions =>
      $$ProfileConditionsTableTableManager(_db, _db.profileConditions);
}
