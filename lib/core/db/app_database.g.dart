// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OnboardingDraftsTable extends OnboardingDrafts
    with TableInfo<$OnboardingDraftsTable, OnboardingDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OnboardingDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boutiqueNameMeta = const VerificationMeta(
    'boutiqueName',
  );
  @override
  late final GeneratedColumn<String> boutiqueName = GeneratedColumn<String>(
    'boutique_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boutiqueCategoryMeta = const VerificationMeta(
    'boutiqueCategory',
  );
  @override
  late final GeneratedColumn<String> boutiqueCategory = GeneratedColumn<String>(
    'boutique_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boutiqueCityMeta = const VerificationMeta(
    'boutiqueCity',
  );
  @override
  late final GeneratedColumn<String> boutiqueCity = GeneratedColumn<String>(
    'boutique_city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boutiqueLogoUrlMeta = const VerificationMeta(
    'boutiqueLogoUrl',
  );
  @override
  late final GeneratedColumn<String> boutiqueLogoUrl = GeneratedColumn<String>(
    'boutique_logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boutiqueBrandColorMeta =
      const VerificationMeta('boutiqueBrandColor');
  @override
  late final GeneratedColumn<String> boutiqueBrandColor =
      GeneratedColumn<String>(
        'boutique_brand_color',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _goalKindMeta = const VerificationMeta(
    'goalKind',
  );
  @override
  late final GeneratedColumn<String> goalKind = GeneratedColumn<String>(
    'goal_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalTypeMeta = const VerificationMeta(
    'goalType',
  );
  @override
  late final GeneratedColumn<String> goalType = GeneratedColumn<String>(
    'goal_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalLabelMeta = const VerificationMeta(
    'goalLabel',
  );
  @override
  late final GeneratedColumn<String> goalLabel = GeneratedColumn<String>(
    'goal_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalTargetValueMeta = const VerificationMeta(
    'goalTargetValue',
  );
  @override
  late final GeneratedColumn<int> goalTargetValue = GeneratedColumn<int>(
    'goal_target_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentStepMeta = const VerificationMeta(
    'currentStep',
  );
  @override
  late final GeneratedColumn<int> currentStep = GeneratedColumn<int>(
    'current_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    boutiqueName,
    boutiqueCategory,
    boutiqueCity,
    boutiqueLogoUrl,
    boutiqueBrandColor,
    goalKind,
    goalType,
    goalLabel,
    goalTargetValue,
    currentStep,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'onboarding_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<OnboardingDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('boutique_name')) {
      context.handle(
        _boutiqueNameMeta,
        boutiqueName.isAcceptableOrUnknown(
          data['boutique_name']!,
          _boutiqueNameMeta,
        ),
      );
    }
    if (data.containsKey('boutique_category')) {
      context.handle(
        _boutiqueCategoryMeta,
        boutiqueCategory.isAcceptableOrUnknown(
          data['boutique_category']!,
          _boutiqueCategoryMeta,
        ),
      );
    }
    if (data.containsKey('boutique_city')) {
      context.handle(
        _boutiqueCityMeta,
        boutiqueCity.isAcceptableOrUnknown(
          data['boutique_city']!,
          _boutiqueCityMeta,
        ),
      );
    }
    if (data.containsKey('boutique_logo_url')) {
      context.handle(
        _boutiqueLogoUrlMeta,
        boutiqueLogoUrl.isAcceptableOrUnknown(
          data['boutique_logo_url']!,
          _boutiqueLogoUrlMeta,
        ),
      );
    }
    if (data.containsKey('boutique_brand_color')) {
      context.handle(
        _boutiqueBrandColorMeta,
        boutiqueBrandColor.isAcceptableOrUnknown(
          data['boutique_brand_color']!,
          _boutiqueBrandColorMeta,
        ),
      );
    }
    if (data.containsKey('goal_kind')) {
      context.handle(
        _goalKindMeta,
        goalKind.isAcceptableOrUnknown(data['goal_kind']!, _goalKindMeta),
      );
    }
    if (data.containsKey('goal_type')) {
      context.handle(
        _goalTypeMeta,
        goalType.isAcceptableOrUnknown(data['goal_type']!, _goalTypeMeta),
      );
    }
    if (data.containsKey('goal_label')) {
      context.handle(
        _goalLabelMeta,
        goalLabel.isAcceptableOrUnknown(data['goal_label']!, _goalLabelMeta),
      );
    }
    if (data.containsKey('goal_target_value')) {
      context.handle(
        _goalTargetValueMeta,
        goalTargetValue.isAcceptableOrUnknown(
          data['goal_target_value']!,
          _goalTargetValueMeta,
        ),
      );
    }
    if (data.containsKey('current_step')) {
      context.handle(
        _currentStepMeta,
        currentStep.isAcceptableOrUnknown(
          data['current_step']!,
          _currentStepMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  OnboardingDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OnboardingDraftRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      boutiqueName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boutique_name'],
      ),
      boutiqueCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boutique_category'],
      ),
      boutiqueCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boutique_city'],
      ),
      boutiqueLogoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boutique_logo_url'],
      ),
      boutiqueBrandColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boutique_brand_color'],
      ),
      goalKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_kind'],
      ),
      goalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_type'],
      ),
      goalLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_label'],
      ),
      goalTargetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_target_value'],
      ),
      currentStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_step'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OnboardingDraftsTable createAlias(String alias) {
    return $OnboardingDraftsTable(attachedDatabase, alias);
  }
}

class OnboardingDraftRow extends DataClass
    implements Insertable<OnboardingDraftRow> {
  final String userId;
  final String? boutiqueName;
  final String? boutiqueCategory;
  final String? boutiqueCity;
  final String? boutiqueLogoUrl;
  final String? boutiqueBrandColor;
  final String? goalKind;
  final String? goalType;
  final String? goalLabel;
  final int? goalTargetValue;
  final int currentStep;
  final DateTime updatedAt;
  const OnboardingDraftRow({
    required this.userId,
    this.boutiqueName,
    this.boutiqueCategory,
    this.boutiqueCity,
    this.boutiqueLogoUrl,
    this.boutiqueBrandColor,
    this.goalKind,
    this.goalType,
    this.goalLabel,
    this.goalTargetValue,
    required this.currentStep,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || boutiqueName != null) {
      map['boutique_name'] = Variable<String>(boutiqueName);
    }
    if (!nullToAbsent || boutiqueCategory != null) {
      map['boutique_category'] = Variable<String>(boutiqueCategory);
    }
    if (!nullToAbsent || boutiqueCity != null) {
      map['boutique_city'] = Variable<String>(boutiqueCity);
    }
    if (!nullToAbsent || boutiqueLogoUrl != null) {
      map['boutique_logo_url'] = Variable<String>(boutiqueLogoUrl);
    }
    if (!nullToAbsent || boutiqueBrandColor != null) {
      map['boutique_brand_color'] = Variable<String>(boutiqueBrandColor);
    }
    if (!nullToAbsent || goalKind != null) {
      map['goal_kind'] = Variable<String>(goalKind);
    }
    if (!nullToAbsent || goalType != null) {
      map['goal_type'] = Variable<String>(goalType);
    }
    if (!nullToAbsent || goalLabel != null) {
      map['goal_label'] = Variable<String>(goalLabel);
    }
    if (!nullToAbsent || goalTargetValue != null) {
      map['goal_target_value'] = Variable<int>(goalTargetValue);
    }
    map['current_step'] = Variable<int>(currentStep);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OnboardingDraftsCompanion toCompanion(bool nullToAbsent) {
    return OnboardingDraftsCompanion(
      userId: Value(userId),
      boutiqueName: boutiqueName == null && nullToAbsent
          ? const Value.absent()
          : Value(boutiqueName),
      boutiqueCategory: boutiqueCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(boutiqueCategory),
      boutiqueCity: boutiqueCity == null && nullToAbsent
          ? const Value.absent()
          : Value(boutiqueCity),
      boutiqueLogoUrl: boutiqueLogoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(boutiqueLogoUrl),
      boutiqueBrandColor: boutiqueBrandColor == null && nullToAbsent
          ? const Value.absent()
          : Value(boutiqueBrandColor),
      goalKind: goalKind == null && nullToAbsent
          ? const Value.absent()
          : Value(goalKind),
      goalType: goalType == null && nullToAbsent
          ? const Value.absent()
          : Value(goalType),
      goalLabel: goalLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(goalLabel),
      goalTargetValue: goalTargetValue == null && nullToAbsent
          ? const Value.absent()
          : Value(goalTargetValue),
      currentStep: Value(currentStep),
      updatedAt: Value(updatedAt),
    );
  }

  factory OnboardingDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OnboardingDraftRow(
      userId: serializer.fromJson<String>(json['userId']),
      boutiqueName: serializer.fromJson<String?>(json['boutiqueName']),
      boutiqueCategory: serializer.fromJson<String?>(json['boutiqueCategory']),
      boutiqueCity: serializer.fromJson<String?>(json['boutiqueCity']),
      boutiqueLogoUrl: serializer.fromJson<String?>(json['boutiqueLogoUrl']),
      boutiqueBrandColor: serializer.fromJson<String?>(
        json['boutiqueBrandColor'],
      ),
      goalKind: serializer.fromJson<String?>(json['goalKind']),
      goalType: serializer.fromJson<String?>(json['goalType']),
      goalLabel: serializer.fromJson<String?>(json['goalLabel']),
      goalTargetValue: serializer.fromJson<int?>(json['goalTargetValue']),
      currentStep: serializer.fromJson<int>(json['currentStep']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'boutiqueName': serializer.toJson<String?>(boutiqueName),
      'boutiqueCategory': serializer.toJson<String?>(boutiqueCategory),
      'boutiqueCity': serializer.toJson<String?>(boutiqueCity),
      'boutiqueLogoUrl': serializer.toJson<String?>(boutiqueLogoUrl),
      'boutiqueBrandColor': serializer.toJson<String?>(boutiqueBrandColor),
      'goalKind': serializer.toJson<String?>(goalKind),
      'goalType': serializer.toJson<String?>(goalType),
      'goalLabel': serializer.toJson<String?>(goalLabel),
      'goalTargetValue': serializer.toJson<int?>(goalTargetValue),
      'currentStep': serializer.toJson<int>(currentStep),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OnboardingDraftRow copyWith({
    String? userId,
    Value<String?> boutiqueName = const Value.absent(),
    Value<String?> boutiqueCategory = const Value.absent(),
    Value<String?> boutiqueCity = const Value.absent(),
    Value<String?> boutiqueLogoUrl = const Value.absent(),
    Value<String?> boutiqueBrandColor = const Value.absent(),
    Value<String?> goalKind = const Value.absent(),
    Value<String?> goalType = const Value.absent(),
    Value<String?> goalLabel = const Value.absent(),
    Value<int?> goalTargetValue = const Value.absent(),
    int? currentStep,
    DateTime? updatedAt,
  }) => OnboardingDraftRow(
    userId: userId ?? this.userId,
    boutiqueName: boutiqueName.present ? boutiqueName.value : this.boutiqueName,
    boutiqueCategory: boutiqueCategory.present
        ? boutiqueCategory.value
        : this.boutiqueCategory,
    boutiqueCity: boutiqueCity.present ? boutiqueCity.value : this.boutiqueCity,
    boutiqueLogoUrl: boutiqueLogoUrl.present
        ? boutiqueLogoUrl.value
        : this.boutiqueLogoUrl,
    boutiqueBrandColor: boutiqueBrandColor.present
        ? boutiqueBrandColor.value
        : this.boutiqueBrandColor,
    goalKind: goalKind.present ? goalKind.value : this.goalKind,
    goalType: goalType.present ? goalType.value : this.goalType,
    goalLabel: goalLabel.present ? goalLabel.value : this.goalLabel,
    goalTargetValue: goalTargetValue.present
        ? goalTargetValue.value
        : this.goalTargetValue,
    currentStep: currentStep ?? this.currentStep,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OnboardingDraftRow copyWithCompanion(OnboardingDraftsCompanion data) {
    return OnboardingDraftRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      boutiqueName: data.boutiqueName.present
          ? data.boutiqueName.value
          : this.boutiqueName,
      boutiqueCategory: data.boutiqueCategory.present
          ? data.boutiqueCategory.value
          : this.boutiqueCategory,
      boutiqueCity: data.boutiqueCity.present
          ? data.boutiqueCity.value
          : this.boutiqueCity,
      boutiqueLogoUrl: data.boutiqueLogoUrl.present
          ? data.boutiqueLogoUrl.value
          : this.boutiqueLogoUrl,
      boutiqueBrandColor: data.boutiqueBrandColor.present
          ? data.boutiqueBrandColor.value
          : this.boutiqueBrandColor,
      goalKind: data.goalKind.present ? data.goalKind.value : this.goalKind,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      goalLabel: data.goalLabel.present ? data.goalLabel.value : this.goalLabel,
      goalTargetValue: data.goalTargetValue.present
          ? data.goalTargetValue.value
          : this.goalTargetValue,
      currentStep: data.currentStep.present
          ? data.currentStep.value
          : this.currentStep,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingDraftRow(')
          ..write('userId: $userId, ')
          ..write('boutiqueName: $boutiqueName, ')
          ..write('boutiqueCategory: $boutiqueCategory, ')
          ..write('boutiqueCity: $boutiqueCity, ')
          ..write('boutiqueLogoUrl: $boutiqueLogoUrl, ')
          ..write('boutiqueBrandColor: $boutiqueBrandColor, ')
          ..write('goalKind: $goalKind, ')
          ..write('goalType: $goalType, ')
          ..write('goalLabel: $goalLabel, ')
          ..write('goalTargetValue: $goalTargetValue, ')
          ..write('currentStep: $currentStep, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    boutiqueName,
    boutiqueCategory,
    boutiqueCity,
    boutiqueLogoUrl,
    boutiqueBrandColor,
    goalKind,
    goalType,
    goalLabel,
    goalTargetValue,
    currentStep,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OnboardingDraftRow &&
          other.userId == this.userId &&
          other.boutiqueName == this.boutiqueName &&
          other.boutiqueCategory == this.boutiqueCategory &&
          other.boutiqueCity == this.boutiqueCity &&
          other.boutiqueLogoUrl == this.boutiqueLogoUrl &&
          other.boutiqueBrandColor == this.boutiqueBrandColor &&
          other.goalKind == this.goalKind &&
          other.goalType == this.goalType &&
          other.goalLabel == this.goalLabel &&
          other.goalTargetValue == this.goalTargetValue &&
          other.currentStep == this.currentStep &&
          other.updatedAt == this.updatedAt);
}

class OnboardingDraftsCompanion extends UpdateCompanion<OnboardingDraftRow> {
  final Value<String> userId;
  final Value<String?> boutiqueName;
  final Value<String?> boutiqueCategory;
  final Value<String?> boutiqueCity;
  final Value<String?> boutiqueLogoUrl;
  final Value<String?> boutiqueBrandColor;
  final Value<String?> goalKind;
  final Value<String?> goalType;
  final Value<String?> goalLabel;
  final Value<int?> goalTargetValue;
  final Value<int> currentStep;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OnboardingDraftsCompanion({
    this.userId = const Value.absent(),
    this.boutiqueName = const Value.absent(),
    this.boutiqueCategory = const Value.absent(),
    this.boutiqueCity = const Value.absent(),
    this.boutiqueLogoUrl = const Value.absent(),
    this.boutiqueBrandColor = const Value.absent(),
    this.goalKind = const Value.absent(),
    this.goalType = const Value.absent(),
    this.goalLabel = const Value.absent(),
    this.goalTargetValue = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OnboardingDraftsCompanion.insert({
    required String userId,
    this.boutiqueName = const Value.absent(),
    this.boutiqueCategory = const Value.absent(),
    this.boutiqueCity = const Value.absent(),
    this.boutiqueLogoUrl = const Value.absent(),
    this.boutiqueBrandColor = const Value.absent(),
    this.goalKind = const Value.absent(),
    this.goalType = const Value.absent(),
    this.goalLabel = const Value.absent(),
    this.goalTargetValue = const Value.absent(),
    this.currentStep = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       updatedAt = Value(updatedAt);
  static Insertable<OnboardingDraftRow> custom({
    Expression<String>? userId,
    Expression<String>? boutiqueName,
    Expression<String>? boutiqueCategory,
    Expression<String>? boutiqueCity,
    Expression<String>? boutiqueLogoUrl,
    Expression<String>? boutiqueBrandColor,
    Expression<String>? goalKind,
    Expression<String>? goalType,
    Expression<String>? goalLabel,
    Expression<int>? goalTargetValue,
    Expression<int>? currentStep,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (boutiqueName != null) 'boutique_name': boutiqueName,
      if (boutiqueCategory != null) 'boutique_category': boutiqueCategory,
      if (boutiqueCity != null) 'boutique_city': boutiqueCity,
      if (boutiqueLogoUrl != null) 'boutique_logo_url': boutiqueLogoUrl,
      if (boutiqueBrandColor != null)
        'boutique_brand_color': boutiqueBrandColor,
      if (goalKind != null) 'goal_kind': goalKind,
      if (goalType != null) 'goal_type': goalType,
      if (goalLabel != null) 'goal_label': goalLabel,
      if (goalTargetValue != null) 'goal_target_value': goalTargetValue,
      if (currentStep != null) 'current_step': currentStep,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OnboardingDraftsCompanion copyWith({
    Value<String>? userId,
    Value<String?>? boutiqueName,
    Value<String?>? boutiqueCategory,
    Value<String?>? boutiqueCity,
    Value<String?>? boutiqueLogoUrl,
    Value<String?>? boutiqueBrandColor,
    Value<String?>? goalKind,
    Value<String?>? goalType,
    Value<String?>? goalLabel,
    Value<int?>? goalTargetValue,
    Value<int>? currentStep,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OnboardingDraftsCompanion(
      userId: userId ?? this.userId,
      boutiqueName: boutiqueName ?? this.boutiqueName,
      boutiqueCategory: boutiqueCategory ?? this.boutiqueCategory,
      boutiqueCity: boutiqueCity ?? this.boutiqueCity,
      boutiqueLogoUrl: boutiqueLogoUrl ?? this.boutiqueLogoUrl,
      boutiqueBrandColor: boutiqueBrandColor ?? this.boutiqueBrandColor,
      goalKind: goalKind ?? this.goalKind,
      goalType: goalType ?? this.goalType,
      goalLabel: goalLabel ?? this.goalLabel,
      goalTargetValue: goalTargetValue ?? this.goalTargetValue,
      currentStep: currentStep ?? this.currentStep,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (boutiqueName.present) {
      map['boutique_name'] = Variable<String>(boutiqueName.value);
    }
    if (boutiqueCategory.present) {
      map['boutique_category'] = Variable<String>(boutiqueCategory.value);
    }
    if (boutiqueCity.present) {
      map['boutique_city'] = Variable<String>(boutiqueCity.value);
    }
    if (boutiqueLogoUrl.present) {
      map['boutique_logo_url'] = Variable<String>(boutiqueLogoUrl.value);
    }
    if (boutiqueBrandColor.present) {
      map['boutique_brand_color'] = Variable<String>(boutiqueBrandColor.value);
    }
    if (goalKind.present) {
      map['goal_kind'] = Variable<String>(goalKind.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(goalType.value);
    }
    if (goalLabel.present) {
      map['goal_label'] = Variable<String>(goalLabel.value);
    }
    if (goalTargetValue.present) {
      map['goal_target_value'] = Variable<int>(goalTargetValue.value);
    }
    if (currentStep.present) {
      map['current_step'] = Variable<int>(currentStep.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingDraftsCompanion(')
          ..write('userId: $userId, ')
          ..write('boutiqueName: $boutiqueName, ')
          ..write('boutiqueCategory: $boutiqueCategory, ')
          ..write('boutiqueCity: $boutiqueCity, ')
          ..write('boutiqueLogoUrl: $boutiqueLogoUrl, ')
          ..write('boutiqueBrandColor: $boutiqueBrandColor, ')
          ..write('goalKind: $goalKind, ')
          ..write('goalType: $goalType, ')
          ..write('goalLabel: $goalLabel, ')
          ..write('goalTargetValue: $goalTargetValue, ')
          ..write('currentStep: $currentStep, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OnboardingDraftsTable onboardingDrafts = $OnboardingDraftsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [onboardingDrafts];
}

typedef $$OnboardingDraftsTableCreateCompanionBuilder =
    OnboardingDraftsCompanion Function({
      required String userId,
      Value<String?> boutiqueName,
      Value<String?> boutiqueCategory,
      Value<String?> boutiqueCity,
      Value<String?> boutiqueLogoUrl,
      Value<String?> boutiqueBrandColor,
      Value<String?> goalKind,
      Value<String?> goalType,
      Value<String?> goalLabel,
      Value<int?> goalTargetValue,
      Value<int> currentStep,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OnboardingDraftsTableUpdateCompanionBuilder =
    OnboardingDraftsCompanion Function({
      Value<String> userId,
      Value<String?> boutiqueName,
      Value<String?> boutiqueCategory,
      Value<String?> boutiqueCity,
      Value<String?> boutiqueLogoUrl,
      Value<String?> boutiqueBrandColor,
      Value<String?> goalKind,
      Value<String?> goalType,
      Value<String?> goalLabel,
      Value<int?> goalTargetValue,
      Value<int> currentStep,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OnboardingDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $OnboardingDraftsTable> {
  $$OnboardingDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boutiqueName => $composableBuilder(
    column: $table.boutiqueName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boutiqueCategory => $composableBuilder(
    column: $table.boutiqueCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boutiqueCity => $composableBuilder(
    column: $table.boutiqueCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boutiqueLogoUrl => $composableBuilder(
    column: $table.boutiqueLogoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boutiqueBrandColor => $composableBuilder(
    column: $table.boutiqueBrandColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalKind => $composableBuilder(
    column: $table.goalKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalLabel => $composableBuilder(
    column: $table.goalLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalTargetValue => $composableBuilder(
    column: $table.goalTargetValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OnboardingDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $OnboardingDraftsTable> {
  $$OnboardingDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boutiqueName => $composableBuilder(
    column: $table.boutiqueName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boutiqueCategory => $composableBuilder(
    column: $table.boutiqueCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boutiqueCity => $composableBuilder(
    column: $table.boutiqueCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boutiqueLogoUrl => $composableBuilder(
    column: $table.boutiqueLogoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boutiqueBrandColor => $composableBuilder(
    column: $table.boutiqueBrandColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalKind => $composableBuilder(
    column: $table.goalKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalLabel => $composableBuilder(
    column: $table.goalLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalTargetValue => $composableBuilder(
    column: $table.goalTargetValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OnboardingDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OnboardingDraftsTable> {
  $$OnboardingDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get boutiqueName => $composableBuilder(
    column: $table.boutiqueName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boutiqueCategory => $composableBuilder(
    column: $table.boutiqueCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boutiqueCity => $composableBuilder(
    column: $table.boutiqueCity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boutiqueLogoUrl => $composableBuilder(
    column: $table.boutiqueLogoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boutiqueBrandColor => $composableBuilder(
    column: $table.boutiqueBrandColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get goalKind =>
      $composableBuilder(column: $table.goalKind, builder: (column) => column);

  GeneratedColumn<String> get goalType =>
      $composableBuilder(column: $table.goalType, builder: (column) => column);

  GeneratedColumn<String> get goalLabel =>
      $composableBuilder(column: $table.goalLabel, builder: (column) => column);

  GeneratedColumn<int> get goalTargetValue => $composableBuilder(
    column: $table.goalTargetValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OnboardingDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OnboardingDraftsTable,
          OnboardingDraftRow,
          $$OnboardingDraftsTableFilterComposer,
          $$OnboardingDraftsTableOrderingComposer,
          $$OnboardingDraftsTableAnnotationComposer,
          $$OnboardingDraftsTableCreateCompanionBuilder,
          $$OnboardingDraftsTableUpdateCompanionBuilder,
          (
            OnboardingDraftRow,
            BaseReferences<
              _$AppDatabase,
              $OnboardingDraftsTable,
              OnboardingDraftRow
            >,
          ),
          OnboardingDraftRow,
          PrefetchHooks Function()
        > {
  $$OnboardingDraftsTableTableManager(
    _$AppDatabase db,
    $OnboardingDraftsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OnboardingDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OnboardingDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OnboardingDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> boutiqueName = const Value.absent(),
                Value<String?> boutiqueCategory = const Value.absent(),
                Value<String?> boutiqueCity = const Value.absent(),
                Value<String?> boutiqueLogoUrl = const Value.absent(),
                Value<String?> boutiqueBrandColor = const Value.absent(),
                Value<String?> goalKind = const Value.absent(),
                Value<String?> goalType = const Value.absent(),
                Value<String?> goalLabel = const Value.absent(),
                Value<int?> goalTargetValue = const Value.absent(),
                Value<int> currentStep = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OnboardingDraftsCompanion(
                userId: userId,
                boutiqueName: boutiqueName,
                boutiqueCategory: boutiqueCategory,
                boutiqueCity: boutiqueCity,
                boutiqueLogoUrl: boutiqueLogoUrl,
                boutiqueBrandColor: boutiqueBrandColor,
                goalKind: goalKind,
                goalType: goalType,
                goalLabel: goalLabel,
                goalTargetValue: goalTargetValue,
                currentStep: currentStep,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> boutiqueName = const Value.absent(),
                Value<String?> boutiqueCategory = const Value.absent(),
                Value<String?> boutiqueCity = const Value.absent(),
                Value<String?> boutiqueLogoUrl = const Value.absent(),
                Value<String?> boutiqueBrandColor = const Value.absent(),
                Value<String?> goalKind = const Value.absent(),
                Value<String?> goalType = const Value.absent(),
                Value<String?> goalLabel = const Value.absent(),
                Value<int?> goalTargetValue = const Value.absent(),
                Value<int> currentStep = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OnboardingDraftsCompanion.insert(
                userId: userId,
                boutiqueName: boutiqueName,
                boutiqueCategory: boutiqueCategory,
                boutiqueCity: boutiqueCity,
                boutiqueLogoUrl: boutiqueLogoUrl,
                boutiqueBrandColor: boutiqueBrandColor,
                goalKind: goalKind,
                goalType: goalType,
                goalLabel: goalLabel,
                goalTargetValue: goalTargetValue,
                currentStep: currentStep,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OnboardingDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OnboardingDraftsTable,
      OnboardingDraftRow,
      $$OnboardingDraftsTableFilterComposer,
      $$OnboardingDraftsTableOrderingComposer,
      $$OnboardingDraftsTableAnnotationComposer,
      $$OnboardingDraftsTableCreateCompanionBuilder,
      $$OnboardingDraftsTableUpdateCompanionBuilder,
      (
        OnboardingDraftRow,
        BaseReferences<
          _$AppDatabase,
          $OnboardingDraftsTable,
          OnboardingDraftRow
        >,
      ),
      OnboardingDraftRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OnboardingDraftsTableTableManager get onboardingDrafts =>
      $$OnboardingDraftsTableTableManager(_db, _db.onboardingDrafts);
}
