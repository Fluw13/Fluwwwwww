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
  static const VerificationMeta _displayNameMeta = const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _bmrFormulaMeta = const VerificationMeta('bmrFormula');
  @override
  late final GeneratedColumn<String> bmrFormula = GeneratedColumn<String>(
    'bmr_formula',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _dietStyleMeta = const VerificationMeta('dietStyle');
  @override
  late final GeneratedColumn<String> dietStyle = GeneratedColumn<String>(
    'diet_style',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allergyNoteMeta = const VerificationMeta('allergyNote');
  @override
  late final GeneratedColumn<String> allergyNote = GeneratedColumn<String>(
    'allergy_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedGoalMeta = const VerificationMeta('plannedGoal');
  @override
  late final GeneratedColumn<String> plannedGoal = GeneratedColumn<String>(
    'planned_goal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    sex,
    bmrFormula,
    birthDate,
    heightCm,
    weightKg,
    targetWeightKg,
    activityLevel,
    trainingType,
    weeklyChangeKg,
    conditionNote,
    limitsSugar,
    dietStyle,
    allergyNote,
    plannedGoal,
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
    if (data.containsKey('display_name')) {
      context.handle(_displayNameMeta, displayName.isAcceptableOrUnknown(data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('sex')) {
      context.handle(_sexMeta, sex.isAcceptableOrUnknown(data['sex']!, _sexMeta));
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('bmr_formula')) {
      context.handle(_bmrFormulaMeta, bmrFormula.isAcceptableOrUnknown(data['bmr_formula']!, _bmrFormulaMeta));
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
    if (data.containsKey('diet_style')) {
      context.handle(_dietStyleMeta, dietStyle.isAcceptableOrUnknown(data['diet_style']!, _dietStyleMeta));
    }
    if (data.containsKey('allergy_note')) {
      context.handle(_allergyNoteMeta, allergyNote.isAcceptableOrUnknown(data['allergy_note']!, _allergyNoteMeta));
    }
    if (data.containsKey('planned_goal')) {
      context.handle(_plannedGoalMeta, plannedGoal.isAcceptableOrUnknown(data['planned_goal']!, _plannedGoalMeta));
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
      displayName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      sex: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sex'])!,
      bmrFormula: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}bmr_formula']),
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
      dietStyle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}diet_style']),
      allergyNote: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}allergy_note']),
      plannedGoal: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}planned_goal']),
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final String? displayName;
  final String sex;

  /// Added in schema v2; only set when the sex is "other".
  final String? bmrFormula;

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

  /// Added in schema v3. Old rows read as the regular style.
  final String? dietStyle;
  final String? allergyNote;

  /// Added in schema v3. Old rows derive it from the two weights.
  final String? plannedGoal;
  const ProfileRow({
    required this.id,
    this.displayName,
    required this.sex,
    this.bmrFormula,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.trainingType,
    this.weeklyChangeKg,
    this.conditionNote,
    required this.limitsSugar,
    this.dietStyle,
    this.allergyNote,
    this.plannedGoal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['sex'] = Variable<String>(sex);
    if (!nullToAbsent || bmrFormula != null) {
      map['bmr_formula'] = Variable<String>(bmrFormula);
    }
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
    if (!nullToAbsent || dietStyle != null) {
      map['diet_style'] = Variable<String>(dietStyle);
    }
    if (!nullToAbsent || allergyNote != null) {
      map['allergy_note'] = Variable<String>(allergyNote);
    }
    if (!nullToAbsent || plannedGoal != null) {
      map['planned_goal'] = Variable<String>(plannedGoal);
    }
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      displayName: displayName == null && nullToAbsent ? const Value.absent() : Value(displayName),
      sex: Value(sex),
      bmrFormula: bmrFormula == null && nullToAbsent ? const Value.absent() : Value(bmrFormula),
      birthDate: Value(birthDate),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      targetWeightKg: Value(targetWeightKg),
      activityLevel: Value(activityLevel),
      trainingType: Value(trainingType),
      weeklyChangeKg: weeklyChangeKg == null && nullToAbsent ? const Value.absent() : Value(weeklyChangeKg),
      conditionNote: conditionNote == null && nullToAbsent ? const Value.absent() : Value(conditionNote),
      limitsSugar: Value(limitsSugar),
      dietStyle: dietStyle == null && nullToAbsent ? const Value.absent() : Value(dietStyle),
      allergyNote: allergyNote == null && nullToAbsent ? const Value.absent() : Value(allergyNote),
      plannedGoal: plannedGoal == null && nullToAbsent ? const Value.absent() : Value(plannedGoal),
    );
  }

  factory ProfileRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      sex: serializer.fromJson<String>(json['sex']),
      bmrFormula: serializer.fromJson<String?>(json['bmrFormula']),
      birthDate: serializer.fromJson<String>(json['birthDate']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      targetWeightKg: serializer.fromJson<double>(json['targetWeightKg']),
      activityLevel: serializer.fromJson<String>(json['activityLevel']),
      trainingType: serializer.fromJson<String>(json['trainingType']),
      weeklyChangeKg: serializer.fromJson<double?>(json['weeklyChangeKg']),
      conditionNote: serializer.fromJson<String?>(json['conditionNote']),
      limitsSugar: serializer.fromJson<bool>(json['limitsSugar']),
      dietStyle: serializer.fromJson<String?>(json['dietStyle']),
      allergyNote: serializer.fromJson<String?>(json['allergyNote']),
      plannedGoal: serializer.fromJson<String?>(json['plannedGoal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String?>(displayName),
      'sex': serializer.toJson<String>(sex),
      'bmrFormula': serializer.toJson<String?>(bmrFormula),
      'birthDate': serializer.toJson<String>(birthDate),
      'heightCm': serializer.toJson<double>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'targetWeightKg': serializer.toJson<double>(targetWeightKg),
      'activityLevel': serializer.toJson<String>(activityLevel),
      'trainingType': serializer.toJson<String>(trainingType),
      'weeklyChangeKg': serializer.toJson<double?>(weeklyChangeKg),
      'conditionNote': serializer.toJson<String?>(conditionNote),
      'limitsSugar': serializer.toJson<bool>(limitsSugar),
      'dietStyle': serializer.toJson<String?>(dietStyle),
      'allergyNote': serializer.toJson<String?>(allergyNote),
      'plannedGoal': serializer.toJson<String?>(plannedGoal),
    };
  }

  ProfileRow copyWith({
    int? id,
    Value<String?> displayName = const Value.absent(),
    String? sex,
    Value<String?> bmrFormula = const Value.absent(),
    String? birthDate,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? activityLevel,
    String? trainingType,
    Value<double?> weeklyChangeKg = const Value.absent(),
    Value<String?> conditionNote = const Value.absent(),
    bool? limitsSugar,
    Value<String?> dietStyle = const Value.absent(),
    Value<String?> allergyNote = const Value.absent(),
    Value<String?> plannedGoal = const Value.absent(),
  }) => ProfileRow(
    id: id ?? this.id,
    displayName: displayName.present ? displayName.value : this.displayName,
    sex: sex ?? this.sex,
    bmrFormula: bmrFormula.present ? bmrFormula.value : this.bmrFormula,
    birthDate: birthDate ?? this.birthDate,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    activityLevel: activityLevel ?? this.activityLevel,
    trainingType: trainingType ?? this.trainingType,
    weeklyChangeKg: weeklyChangeKg.present ? weeklyChangeKg.value : this.weeklyChangeKg,
    conditionNote: conditionNote.present ? conditionNote.value : this.conditionNote,
    limitsSugar: limitsSugar ?? this.limitsSugar,
    dietStyle: dietStyle.present ? dietStyle.value : this.dietStyle,
    allergyNote: allergyNote.present ? allergyNote.value : this.allergyNote,
    plannedGoal: plannedGoal.present ? plannedGoal.value : this.plannedGoal,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present ? data.displayName.value : this.displayName,
      sex: data.sex.present ? data.sex.value : this.sex,
      bmrFormula: data.bmrFormula.present ? data.bmrFormula.value : this.bmrFormula,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      targetWeightKg: data.targetWeightKg.present ? data.targetWeightKg.value : this.targetWeightKg,
      activityLevel: data.activityLevel.present ? data.activityLevel.value : this.activityLevel,
      trainingType: data.trainingType.present ? data.trainingType.value : this.trainingType,
      weeklyChangeKg: data.weeklyChangeKg.present ? data.weeklyChangeKg.value : this.weeklyChangeKg,
      conditionNote: data.conditionNote.present ? data.conditionNote.value : this.conditionNote,
      limitsSugar: data.limitsSugar.present ? data.limitsSugar.value : this.limitsSugar,
      dietStyle: data.dietStyle.present ? data.dietStyle.value : this.dietStyle,
      allergyNote: data.allergyNote.present ? data.allergyNote.value : this.allergyNote,
      plannedGoal: data.plannedGoal.present ? data.plannedGoal.value : this.plannedGoal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('sex: $sex, ')
          ..write('bmrFormula: $bmrFormula, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('trainingType: $trainingType, ')
          ..write('weeklyChangeKg: $weeklyChangeKg, ')
          ..write('conditionNote: $conditionNote, ')
          ..write('limitsSugar: $limitsSugar, ')
          ..write('dietStyle: $dietStyle, ')
          ..write('allergyNote: $allergyNote, ')
          ..write('plannedGoal: $plannedGoal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    sex,
    bmrFormula,
    birthDate,
    heightCm,
    weightKg,
    targetWeightKg,
    activityLevel,
    trainingType,
    weeklyChangeKg,
    conditionNote,
    limitsSugar,
    dietStyle,
    allergyNote,
    plannedGoal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.sex == this.sex &&
          other.bmrFormula == this.bmrFormula &&
          other.birthDate == this.birthDate &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.targetWeightKg == this.targetWeightKg &&
          other.activityLevel == this.activityLevel &&
          other.trainingType == this.trainingType &&
          other.weeklyChangeKg == this.weeklyChangeKg &&
          other.conditionNote == this.conditionNote &&
          other.limitsSugar == this.limitsSugar &&
          other.dietStyle == this.dietStyle &&
          other.allergyNote == this.allergyNote &&
          other.plannedGoal == this.plannedGoal);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<String?> displayName;
  final Value<String> sex;
  final Value<String?> bmrFormula;
  final Value<String> birthDate;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<double> targetWeightKg;
  final Value<String> activityLevel;
  final Value<String> trainingType;
  final Value<double?> weeklyChangeKg;
  final Value<String?> conditionNote;
  final Value<bool> limitsSugar;
  final Value<String?> dietStyle;
  final Value<String?> allergyNote;
  final Value<String?> plannedGoal;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.sex = const Value.absent(),
    this.bmrFormula = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.trainingType = const Value.absent(),
    this.weeklyChangeKg = const Value.absent(),
    this.conditionNote = const Value.absent(),
    this.limitsSugar = const Value.absent(),
    this.dietStyle = const Value.absent(),
    this.allergyNote = const Value.absent(),
    this.plannedGoal = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    required String sex,
    this.bmrFormula = const Value.absent(),
    required String birthDate,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required String activityLevel,
    required String trainingType,
    this.weeklyChangeKg = const Value.absent(),
    this.conditionNote = const Value.absent(),
    required bool limitsSugar,
    this.dietStyle = const Value.absent(),
    this.allergyNote = const Value.absent(),
    this.plannedGoal = const Value.absent(),
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
    Expression<String>? displayName,
    Expression<String>? sex,
    Expression<String>? bmrFormula,
    Expression<String>? birthDate,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<double>? targetWeightKg,
    Expression<String>? activityLevel,
    Expression<String>? trainingType,
    Expression<double>? weeklyChangeKg,
    Expression<String>? conditionNote,
    Expression<bool>? limitsSugar,
    Expression<String>? dietStyle,
    Expression<String>? allergyNote,
    Expression<String>? plannedGoal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (sex != null) 'sex': sex,
      if (bmrFormula != null) 'bmr_formula': bmrFormula,
      if (birthDate != null) 'birth_date': birthDate,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (trainingType != null) 'training_type': trainingType,
      if (weeklyChangeKg != null) 'weekly_change_kg': weeklyChangeKg,
      if (conditionNote != null) 'condition_note': conditionNote,
      if (limitsSugar != null) 'limits_sugar': limitsSugar,
      if (dietStyle != null) 'diet_style': dietStyle,
      if (allergyNote != null) 'allergy_note': allergyNote,
      if (plannedGoal != null) 'planned_goal': plannedGoal,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String?>? displayName,
    Value<String>? sex,
    Value<String?>? bmrFormula,
    Value<String>? birthDate,
    Value<double>? heightCm,
    Value<double>? weightKg,
    Value<double>? targetWeightKg,
    Value<String>? activityLevel,
    Value<String>? trainingType,
    Value<double?>? weeklyChangeKg,
    Value<String?>? conditionNote,
    Value<bool>? limitsSugar,
    Value<String?>? dietStyle,
    Value<String?>? allergyNote,
    Value<String?>? plannedGoal,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      sex: sex ?? this.sex,
      bmrFormula: bmrFormula ?? this.bmrFormula,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      trainingType: trainingType ?? this.trainingType,
      weeklyChangeKg: weeklyChangeKg ?? this.weeklyChangeKg,
      conditionNote: conditionNote ?? this.conditionNote,
      limitsSugar: limitsSugar ?? this.limitsSugar,
      dietStyle: dietStyle ?? this.dietStyle,
      allergyNote: allergyNote ?? this.allergyNote,
      plannedGoal: plannedGoal ?? this.plannedGoal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (bmrFormula.present) {
      map['bmr_formula'] = Variable<String>(bmrFormula.value);
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
    if (dietStyle.present) {
      map['diet_style'] = Variable<String>(dietStyle.value);
    }
    if (allergyNote.present) {
      map['allergy_note'] = Variable<String>(allergyNote.value);
    }
    if (plannedGoal.present) {
      map['planned_goal'] = Variable<String>(plannedGoal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('sex: $sex, ')
          ..write('bmrFormula: $bmrFormula, ')
          ..write('birthDate: $birthDate, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('targetWeightKg: $targetWeightKg, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('trainingType: $trainingType, ')
          ..write('weeklyChangeKg: $weeklyChangeKg, ')
          ..write('conditionNote: $conditionNote, ')
          ..write('limitsSugar: $limitsSugar, ')
          ..write('dietStyle: $dietStyle, ')
          ..write('allergyNote: $allergyNote, ')
          ..write('plannedGoal: $plannedGoal')
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

class $ProfileAllergiesTable extends ProfileAllergies with TableInfo<$ProfileAllergiesTable, ProfileAllergyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileAllergiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _allergenKeyMeta = const VerificationMeta('allergenKey');
  @override
  late final GeneratedColumn<String> allergenKey = GeneratedColumn<String>(
    'allergen_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityKeyMeta = const VerificationMeta('severityKey');
  @override
  late final GeneratedColumn<String> severityKey = GeneratedColumn<String>(
    'severity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [allergenKey, severityKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_allergies';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileAllergyRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('allergen_key')) {
      context.handle(_allergenKeyMeta, allergenKey.isAcceptableOrUnknown(data['allergen_key']!, _allergenKeyMeta));
    } else if (isInserting) {
      context.missing(_allergenKeyMeta);
    }
    if (data.containsKey('severity_key')) {
      context.handle(_severityKeyMeta, severityKey.isAcceptableOrUnknown(data['severity_key']!, _severityKeyMeta));
    } else if (isInserting) {
      context.missing(_severityKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {allergenKey};
  @override
  ProfileAllergyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileAllergyRow(
      allergenKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}allergen_key'])!,
      severityKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}severity_key'])!,
    );
  }

  @override
  $ProfileAllergiesTable createAlias(String alias) {
    return $ProfileAllergiesTable(attachedDatabase, alias);
  }
}

class ProfileAllergyRow extends DataClass implements Insertable<ProfileAllergyRow> {
  final String allergenKey;
  final String severityKey;
  const ProfileAllergyRow({required this.allergenKey, required this.severityKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['allergen_key'] = Variable<String>(allergenKey);
    map['severity_key'] = Variable<String>(severityKey);
    return map;
  }

  ProfileAllergiesCompanion toCompanion(bool nullToAbsent) {
    return ProfileAllergiesCompanion(allergenKey: Value(allergenKey), severityKey: Value(severityKey));
  }

  factory ProfileAllergyRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileAllergyRow(
      allergenKey: serializer.fromJson<String>(json['allergenKey']),
      severityKey: serializer.fromJson<String>(json['severityKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'allergenKey': serializer.toJson<String>(allergenKey),
      'severityKey': serializer.toJson<String>(severityKey),
    };
  }

  ProfileAllergyRow copyWith({String? allergenKey, String? severityKey}) =>
      ProfileAllergyRow(allergenKey: allergenKey ?? this.allergenKey, severityKey: severityKey ?? this.severityKey);
  ProfileAllergyRow copyWithCompanion(ProfileAllergiesCompanion data) {
    return ProfileAllergyRow(
      allergenKey: data.allergenKey.present ? data.allergenKey.value : this.allergenKey,
      severityKey: data.severityKey.present ? data.severityKey.value : this.severityKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileAllergyRow(')
          ..write('allergenKey: $allergenKey, ')
          ..write('severityKey: $severityKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(allergenKey, severityKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileAllergyRow && other.allergenKey == this.allergenKey && other.severityKey == this.severityKey);
}

class ProfileAllergiesCompanion extends UpdateCompanion<ProfileAllergyRow> {
  final Value<String> allergenKey;
  final Value<String> severityKey;
  final Value<int> rowid;
  const ProfileAllergiesCompanion({
    this.allergenKey = const Value.absent(),
    this.severityKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileAllergiesCompanion.insert({
    required String allergenKey,
    required String severityKey,
    this.rowid = const Value.absent(),
  }) : allergenKey = Value(allergenKey),
       severityKey = Value(severityKey);
  static Insertable<ProfileAllergyRow> custom({
    Expression<String>? allergenKey,
    Expression<String>? severityKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (allergenKey != null) 'allergen_key': allergenKey,
      if (severityKey != null) 'severity_key': severityKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileAllergiesCompanion copyWith({Value<String>? allergenKey, Value<String>? severityKey, Value<int>? rowid}) {
    return ProfileAllergiesCompanion(
      allergenKey: allergenKey ?? this.allergenKey,
      severityKey: severityKey ?? this.severityKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (allergenKey.present) {
      map['allergen_key'] = Variable<String>(allergenKey.value);
    }
    if (severityKey.present) {
      map['severity_key'] = Variable<String>(severityKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileAllergiesCompanion(')
          ..write('allergenKey: $allergenKey, ')
          ..write('severityKey: $severityKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilePreferencesTable extends ProfilePreferences
    with TableInfo<$ProfilePreferencesTable, ProfilePreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilePreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _preferenceKeyMeta = const VerificationMeta('preferenceKey');
  @override
  late final GeneratedColumn<String> preferenceKey = GeneratedColumn<String>(
    'preference_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [preferenceKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_preferences';
  @override
  VerificationContext validateIntegrity(Insertable<ProfilePreferenceRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('preference_key')) {
      context.handle(
        _preferenceKeyMeta,
        preferenceKey.isAcceptableOrUnknown(data['preference_key']!, _preferenceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_preferenceKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {preferenceKey};
  @override
  ProfilePreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfilePreferenceRow(
      preferenceKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}preference_key'])!,
    );
  }

  @override
  $ProfilePreferencesTable createAlias(String alias) {
    return $ProfilePreferencesTable(attachedDatabase, alias);
  }
}

class ProfilePreferenceRow extends DataClass implements Insertable<ProfilePreferenceRow> {
  final String preferenceKey;
  const ProfilePreferenceRow({required this.preferenceKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['preference_key'] = Variable<String>(preferenceKey);
    return map;
  }

  ProfilePreferencesCompanion toCompanion(bool nullToAbsent) {
    return ProfilePreferencesCompanion(preferenceKey: Value(preferenceKey));
  }

  factory ProfilePreferenceRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfilePreferenceRow(preferenceKey: serializer.fromJson<String>(json['preferenceKey']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'preferenceKey': serializer.toJson<String>(preferenceKey)};
  }

  ProfilePreferenceRow copyWith({String? preferenceKey}) =>
      ProfilePreferenceRow(preferenceKey: preferenceKey ?? this.preferenceKey);
  ProfilePreferenceRow copyWithCompanion(ProfilePreferencesCompanion data) {
    return ProfilePreferenceRow(
      preferenceKey: data.preferenceKey.present ? data.preferenceKey.value : this.preferenceKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfilePreferenceRow(')
          ..write('preferenceKey: $preferenceKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => preferenceKey.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ProfilePreferenceRow && other.preferenceKey == this.preferenceKey);
}

class ProfilePreferencesCompanion extends UpdateCompanion<ProfilePreferenceRow> {
  final Value<String> preferenceKey;
  final Value<int> rowid;
  const ProfilePreferencesCompanion({this.preferenceKey = const Value.absent(), this.rowid = const Value.absent()});
  ProfilePreferencesCompanion.insert({required String preferenceKey, this.rowid = const Value.absent()})
    : preferenceKey = Value(preferenceKey);
  static Insertable<ProfilePreferenceRow> custom({Expression<String>? preferenceKey, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (preferenceKey != null) 'preference_key': preferenceKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilePreferencesCompanion copyWith({Value<String>? preferenceKey, Value<int>? rowid}) {
    return ProfilePreferencesCompanion(preferenceKey: preferenceKey ?? this.preferenceKey, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (preferenceKey.present) {
      map['preference_key'] = Variable<String>(preferenceKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilePreferencesCompanion(')
          ..write('preferenceKey: $preferenceKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries with TableInfo<$WeightEntriesTable, WeightEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [date, weightKg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(Insertable<WeightEntryRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta, weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  WeightEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntryRow(
      date: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      weightKg: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}weight_kg'])!,
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntryRow extends DataClass implements Insertable<WeightEntryRow> {
  final String date;
  final double weightKg;
  const WeightEntryRow({required this.date, required this.weightKg});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['weight_kg'] = Variable<double>(weightKg);
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(date: Value(date), weightKg: Value(weightKg));
  }

  factory WeightEntryRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntryRow(
      date: serializer.fromJson<String>(json['date']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'date': serializer.toJson<String>(date), 'weightKg': serializer.toJson<double>(weightKg)};
  }

  WeightEntryRow copyWith({String? date, double? weightKg}) =>
      WeightEntryRow(date: date ?? this.date, weightKg: weightKg ?? this.weightKg);
  WeightEntryRow copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntryRow(
      date: data.date.present ? data.date.value : this.date,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntryRow(')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, weightKg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is WeightEntryRow && other.date == this.date && other.weightKg == this.weightKg);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntryRow> {
  final Value<String> date;
  final Value<double> weightKg;
  final Value<int> rowid;
  const WeightEntriesCompanion({
    this.date = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightEntriesCompanion.insert({required String date, required double weightKg, this.rowid = const Value.absent()})
    : date = Value(date),
      weightKg = Value(weightKg);
  static Insertable<WeightEntryRow> custom({
    Expression<String>? date,
    Expression<double>? weightKg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (weightKg != null) 'weight_kg': weightKg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightEntriesCompanion copyWith({Value<String>? date, Value<double>? weightKg, Value<int>? rowid}) {
    return WeightEntriesCompanion(
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('date: $date, ')
          ..write('weightKg: $weightKg, ')
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
  late final $ProfileAllergiesTable profileAllergies = $ProfileAllergiesTable(this);
  late final $ProfilePreferencesTable profilePreferences = $ProfilePreferencesTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    profileConditions,
    profileAllergies,
    profilePreferences,
    weightEntries,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String?> displayName,
  required String sex,
  Value<String?> bmrFormula,
  required String birthDate,
  required double heightCm,
  required double weightKg,
  required double targetWeightKg,
  required String activityLevel,
  required String trainingType,
  Value<double?> weeklyChangeKg,
  Value<String?> conditionNote,
  required bool limitsSugar,
  Value<String?> dietStyle,
  Value<String?> allergyNote,
  Value<String?> plannedGoal,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String?> displayName,
  Value<String> sex,
  Value<String?> bmrFormula,
  Value<String> birthDate,
  Value<double> heightCm,
  Value<double> weightKg,
  Value<double> targetWeightKg,
  Value<String> activityLevel,
  Value<String> trainingType,
  Value<double?> weeklyChangeKg,
  Value<String?> conditionNote,
  Value<bool> limitsSugar,
  Value<String?> dietStyle,
  Value<String?> allergyNote,
  Value<String?> plannedGoal,
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

  ColumnFilters<String> get displayName =>
      $composableBuilder(column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sex => $composableBuilder(column: $table.sex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bmrFormula =>
      $composableBuilder(column: $table.bmrFormula, builder: (column) => ColumnFilters(column));

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

  ColumnFilters<String> get dietStyle =>
      $composableBuilder(column: $table.dietStyle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get allergyNote =>
      $composableBuilder(column: $table.allergyNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plannedGoal =>
      $composableBuilder(column: $table.plannedGoal, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get displayName =>
      $composableBuilder(column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bmrFormula =>
      $composableBuilder(column: $table.bmrFormula, builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<String> get dietStyle =>
      $composableBuilder(column: $table.dietStyle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get allergyNote =>
      $composableBuilder(column: $table.allergyNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plannedGoal =>
      $composableBuilder(column: $table.plannedGoal, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get displayName =>
      $composableBuilder(column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get sex => $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get bmrFormula => $composableBuilder(column: $table.bmrFormula, builder: (column) => column);

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

  GeneratedColumn<String> get dietStyle => $composableBuilder(column: $table.dietStyle, builder: (column) => column);

  GeneratedColumn<String> get allergyNote =>
      $composableBuilder(column: $table.allergyNote, builder: (column) => column);

  GeneratedColumn<String> get plannedGoal =>
      $composableBuilder(column: $table.plannedGoal, builder: (column) => column);
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
                Value<String?> displayName = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<String?> bmrFormula = const Value.absent(),
                Value<String> birthDate = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<double> targetWeightKg = const Value.absent(),
                Value<String> activityLevel = const Value.absent(),
                Value<String> trainingType = const Value.absent(),
                Value<double?> weeklyChangeKg = const Value.absent(),
                Value<String?> conditionNote = const Value.absent(),
                Value<bool> limitsSugar = const Value.absent(),
                Value<String?> dietStyle = const Value.absent(),
                Value<String?> allergyNote = const Value.absent(),
                Value<String?> plannedGoal = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                displayName: displayName,
                sex: sex,
                bmrFormula: bmrFormula,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                targetWeightKg: targetWeightKg,
                activityLevel: activityLevel,
                trainingType: trainingType,
                weeklyChangeKg: weeklyChangeKg,
                conditionNote: conditionNote,
                limitsSugar: limitsSugar,
                dietStyle: dietStyle,
                allergyNote: allergyNote,
                plannedGoal: plannedGoal,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                required String sex,
                Value<String?> bmrFormula = const Value.absent(),
                required String birthDate,
                required double heightCm,
                required double weightKg,
                required double targetWeightKg,
                required String activityLevel,
                required String trainingType,
                Value<double?> weeklyChangeKg = const Value.absent(),
                Value<String?> conditionNote = const Value.absent(),
                required bool limitsSugar,
                Value<String?> dietStyle = const Value.absent(),
                Value<String?> allergyNote = const Value.absent(),
                Value<String?> plannedGoal = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                sex: sex,
                bmrFormula: bmrFormula,
                birthDate: birthDate,
                heightCm: heightCm,
                weightKg: weightKg,
                targetWeightKg: targetWeightKg,
                activityLevel: activityLevel,
                trainingType: trainingType,
                weeklyChangeKg: weeklyChangeKg,
                conditionNote: conditionNote,
                limitsSugar: limitsSugar,
                dietStyle: dietStyle,
                allergyNote: allergyNote,
                plannedGoal: plannedGoal,
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
typedef $$ProfileAllergiesTableCreateCompanionBuilder = ProfileAllergiesCompanion Function({
  required String allergenKey,
  required String severityKey,
  Value<int> rowid,
});
typedef $$ProfileAllergiesTableUpdateCompanionBuilder = ProfileAllergiesCompanion Function({
  Value<String> allergenKey,
  Value<String> severityKey,
  Value<int> rowid,
});

class $$ProfileAllergiesTableFilterComposer extends Composer<_$AppDatabase, $ProfileAllergiesTable> {
  $$ProfileAllergiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get allergenKey =>
      $composableBuilder(column: $table.allergenKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severityKey =>
      $composableBuilder(column: $table.severityKey, builder: (column) => ColumnFilters(column));
}

class $$ProfileAllergiesTableOrderingComposer extends Composer<_$AppDatabase, $ProfileAllergiesTable> {
  $$ProfileAllergiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get allergenKey =>
      $composableBuilder(column: $table.allergenKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severityKey =>
      $composableBuilder(column: $table.severityKey, builder: (column) => ColumnOrderings(column));
}

class $$ProfileAllergiesTableAnnotationComposer extends Composer<_$AppDatabase, $ProfileAllergiesTable> {
  $$ProfileAllergiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get allergenKey =>
      $composableBuilder(column: $table.allergenKey, builder: (column) => column);

  GeneratedColumn<String> get severityKey =>
      $composableBuilder(column: $table.severityKey, builder: (column) => column);
}

class $$ProfileAllergiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileAllergiesTable,
          ProfileAllergyRow,
          $$ProfileAllergiesTableFilterComposer,
          $$ProfileAllergiesTableOrderingComposer,
          $$ProfileAllergiesTableAnnotationComposer,
          $$ProfileAllergiesTableCreateCompanionBuilder,
          $$ProfileAllergiesTableUpdateCompanionBuilder,
          (ProfileAllergyRow, BaseReferences<_$AppDatabase, $ProfileAllergiesTable, ProfileAllergyRow>),
          ProfileAllergyRow,
          PrefetchHooks Function()
        > {
  $$ProfileAllergiesTableTableManager(_$AppDatabase db, $ProfileAllergiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProfileAllergiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProfileAllergiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProfileAllergiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> allergenKey = const Value.absent(),
            Value<String> severityKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ProfileAllergiesCompanion(allergenKey: allergenKey, severityKey: severityKey, rowid: rowid),
          createCompanionCallback: ({
            required String allergenKey,
            required String severityKey,
            Value<int> rowid = const Value.absent(),
          }) => ProfileAllergiesCompanion.insert(allergenKey: allergenKey, severityKey: severityKey, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfileAllergiesTable, ProfileAllergyRow>(table),
                  BaseReferences<_$AppDatabase, $ProfileAllergiesTable, ProfileAllergyRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileAllergiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileAllergiesTable,
      ProfileAllergyRow,
      $$ProfileAllergiesTableFilterComposer,
      $$ProfileAllergiesTableOrderingComposer,
      $$ProfileAllergiesTableAnnotationComposer,
      $$ProfileAllergiesTableCreateCompanionBuilder,
      $$ProfileAllergiesTableUpdateCompanionBuilder,
      (ProfileAllergyRow, BaseReferences<_$AppDatabase, $ProfileAllergiesTable, ProfileAllergyRow>),
      ProfileAllergyRow,
      PrefetchHooks Function()
    >;
typedef $$ProfilePreferencesTableCreateCompanionBuilder = ProfilePreferencesCompanion Function({
  required String preferenceKey,
  Value<int> rowid,
});
typedef $$ProfilePreferencesTableUpdateCompanionBuilder = ProfilePreferencesCompanion Function({
  Value<String> preferenceKey,
  Value<int> rowid,
});

class $$ProfilePreferencesTableFilterComposer extends Composer<_$AppDatabase, $ProfilePreferencesTable> {
  $$ProfilePreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get preferenceKey =>
      $composableBuilder(column: $table.preferenceKey, builder: (column) => ColumnFilters(column));
}

class $$ProfilePreferencesTableOrderingComposer extends Composer<_$AppDatabase, $ProfilePreferencesTable> {
  $$ProfilePreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get preferenceKey =>
      $composableBuilder(column: $table.preferenceKey, builder: (column) => ColumnOrderings(column));
}

class $$ProfilePreferencesTableAnnotationComposer extends Composer<_$AppDatabase, $ProfilePreferencesTable> {
  $$ProfilePreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get preferenceKey =>
      $composableBuilder(column: $table.preferenceKey, builder: (column) => column);
}

class $$ProfilePreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilePreferencesTable,
          ProfilePreferenceRow,
          $$ProfilePreferencesTableFilterComposer,
          $$ProfilePreferencesTableOrderingComposer,
          $$ProfilePreferencesTableAnnotationComposer,
          $$ProfilePreferencesTableCreateCompanionBuilder,
          $$ProfilePreferencesTableUpdateCompanionBuilder,
          (ProfilePreferenceRow, BaseReferences<_$AppDatabase, $ProfilePreferencesTable, ProfilePreferenceRow>),
          ProfilePreferenceRow,
          PrefetchHooks Function()
        > {
  $$ProfilePreferencesTableTableManager(_$AppDatabase db, $ProfilePreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProfilePreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProfilePreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProfilePreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> preferenceKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ProfilePreferencesCompanion(preferenceKey: preferenceKey, rowid: rowid),
          createCompanionCallback: ({required String preferenceKey, Value<int> rowid = const Value.absent()}) =>
              ProfilePreferencesCompanion.insert(preferenceKey: preferenceKey, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilePreferencesTable, ProfilePreferenceRow>(table),
                  BaseReferences<_$AppDatabase, $ProfilePreferencesTable, ProfilePreferenceRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilePreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilePreferencesTable,
      ProfilePreferenceRow,
      $$ProfilePreferencesTableFilterComposer,
      $$ProfilePreferencesTableOrderingComposer,
      $$ProfilePreferencesTableAnnotationComposer,
      $$ProfilePreferencesTableCreateCompanionBuilder,
      $$ProfilePreferencesTableUpdateCompanionBuilder,
      (ProfilePreferenceRow, BaseReferences<_$AppDatabase, $ProfilePreferencesTable, ProfilePreferenceRow>),
      ProfilePreferenceRow,
      PrefetchHooks Function()
    >;
typedef $$WeightEntriesTableCreateCompanionBuilder = WeightEntriesCompanion Function({
  required String date,
  required double weightKg,
  Value<int> rowid,
});
typedef $$WeightEntriesTableUpdateCompanionBuilder = WeightEntriesCompanion Function({
  Value<String> date,
  Value<double> weightKg,
  Value<int> rowid,
});

class $$WeightEntriesTableFilterComposer extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => ColumnFilters(column));
}

class $$WeightEntriesTableOrderingComposer extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => ColumnOrderings(column));
}

class $$WeightEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get weightKg => $composableBuilder(column: $table.weightKg, builder: (column) => column);
}

class $$WeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightEntriesTable,
          WeightEntryRow,
          $$WeightEntriesTableFilterComposer,
          $$WeightEntriesTableOrderingComposer,
          $$WeightEntriesTableAnnotationComposer,
          $$WeightEntriesTableCreateCompanionBuilder,
          $$WeightEntriesTableUpdateCompanionBuilder,
          (WeightEntryRow, BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntryRow>),
          WeightEntryRow,
          PrefetchHooks Function()
        > {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<double> weightKg = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => WeightEntriesCompanion(date: date, weightKg: weightKg, rowid: rowid),
          createCompanionCallback: ({
            required String date,
            required double weightKg,
            Value<int> rowid = const Value.absent(),
          }) => WeightEntriesCompanion.insert(date: date, weightKg: weightKg, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeightEntriesTable, WeightEntryRow>(table),
                  BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntryRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightEntriesTable,
      WeightEntryRow,
      $$WeightEntriesTableFilterComposer,
      $$WeightEntriesTableOrderingComposer,
      $$WeightEntriesTableAnnotationComposer,
      $$WeightEntriesTableCreateCompanionBuilder,
      $$WeightEntriesTableUpdateCompanionBuilder,
      (WeightEntryRow, BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntryRow>),
      WeightEntryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles => $$ProfilesTableTableManager(_db, _db.profiles);
  $$ProfileConditionsTableTableManager get profileConditions =>
      $$ProfileConditionsTableTableManager(_db, _db.profileConditions);
  $$ProfileAllergiesTableTableManager get profileAllergies =>
      $$ProfileAllergiesTableTableManager(_db, _db.profileAllergies);
  $$ProfilePreferencesTableTableManager get profilePreferences =>
      $$ProfilePreferencesTableTableManager(_db, _db.profilePreferences);
  $$WeightEntriesTableTableManager get weightEntries => $$WeightEntriesTableTableManager(_db, _db.weightEntries);
}
