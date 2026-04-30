// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_progress_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GoalWithProgress _$GoalWithProgressFromJson(Map<String, dynamic> json) {
  return _GoalWithProgress.fromJson(json);
}

/// @nodoc
mixin _$GoalWithProgress {
  String get id => throw _privateConstructorUsedError;
  String get kind =>
      throw _privateConstructorUsedError; // 'TRACKED' | 'SELF_REPORT'
  String? get goalType => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  int? get targetValue => throw _privateConstructorUsedError;
  int? get currentValue => throw _privateConstructorUsedError;
  double? get progressPercent => throw _privateConstructorUsedError;
  int get daysRemaining => throw _privateConstructorUsedError;
  int? get dailyPaceRequired => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get periodStart => throw _privateConstructorUsedError;
  DateTime get periodEnd => throw _privateConstructorUsedError;

  /// Serializes this GoalWithProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GoalWithProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoalWithProgressCopyWith<GoalWithProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalWithProgressCopyWith<$Res> {
  factory $GoalWithProgressCopyWith(
    GoalWithProgress value,
    $Res Function(GoalWithProgress) then,
  ) = _$GoalWithProgressCopyWithImpl<$Res, GoalWithProgress>;
  @useResult
  $Res call({
    String id,
    String kind,
    String? goalType,
    String? label,
    int? targetValue,
    int? currentValue,
    double? progressPercent,
    int daysRemaining,
    int? dailyPaceRequired,
    String status,
    DateTime periodStart,
    DateTime periodEnd,
  });
}

/// @nodoc
class _$GoalWithProgressCopyWithImpl<$Res, $Val extends GoalWithProgress>
    implements $GoalWithProgressCopyWith<$Res> {
  _$GoalWithProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GoalWithProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? goalType = freezed,
    Object? label = freezed,
    Object? targetValue = freezed,
    Object? currentValue = freezed,
    Object? progressPercent = freezed,
    Object? daysRemaining = null,
    Object? dailyPaceRequired = freezed,
    Object? status = null,
    Object? periodStart = null,
    Object? periodEnd = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            goalType: freezed == goalType
                ? _value.goalType
                : goalType // ignore: cast_nullable_to_non_nullable
                      as String?,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetValue: freezed == targetValue
                ? _value.targetValue
                : targetValue // ignore: cast_nullable_to_non_nullable
                      as int?,
            currentValue: freezed == currentValue
                ? _value.currentValue
                : currentValue // ignore: cast_nullable_to_non_nullable
                      as int?,
            progressPercent: freezed == progressPercent
                ? _value.progressPercent
                : progressPercent // ignore: cast_nullable_to_non_nullable
                      as double?,
            daysRemaining: null == daysRemaining
                ? _value.daysRemaining
                : daysRemaining // ignore: cast_nullable_to_non_nullable
                      as int,
            dailyPaceRequired: freezed == dailyPaceRequired
                ? _value.dailyPaceRequired
                : dailyPaceRequired // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            periodStart: null == periodStart
                ? _value.periodStart
                : periodStart // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            periodEnd: null == periodEnd
                ? _value.periodEnd
                : periodEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GoalWithProgressImplCopyWith<$Res>
    implements $GoalWithProgressCopyWith<$Res> {
  factory _$$GoalWithProgressImplCopyWith(
    _$GoalWithProgressImpl value,
    $Res Function(_$GoalWithProgressImpl) then,
  ) = __$$GoalWithProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String kind,
    String? goalType,
    String? label,
    int? targetValue,
    int? currentValue,
    double? progressPercent,
    int daysRemaining,
    int? dailyPaceRequired,
    String status,
    DateTime periodStart,
    DateTime periodEnd,
  });
}

/// @nodoc
class __$$GoalWithProgressImplCopyWithImpl<$Res>
    extends _$GoalWithProgressCopyWithImpl<$Res, _$GoalWithProgressImpl>
    implements _$$GoalWithProgressImplCopyWith<$Res> {
  __$$GoalWithProgressImplCopyWithImpl(
    _$GoalWithProgressImpl _value,
    $Res Function(_$GoalWithProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GoalWithProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? goalType = freezed,
    Object? label = freezed,
    Object? targetValue = freezed,
    Object? currentValue = freezed,
    Object? progressPercent = freezed,
    Object? daysRemaining = null,
    Object? dailyPaceRequired = freezed,
    Object? status = null,
    Object? periodStart = null,
    Object? periodEnd = null,
  }) {
    return _then(
      _$GoalWithProgressImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        goalType: freezed == goalType
            ? _value.goalType
            : goalType // ignore: cast_nullable_to_non_nullable
                  as String?,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetValue: freezed == targetValue
            ? _value.targetValue
            : targetValue // ignore: cast_nullable_to_non_nullable
                  as int?,
        currentValue: freezed == currentValue
            ? _value.currentValue
            : currentValue // ignore: cast_nullable_to_non_nullable
                  as int?,
        progressPercent: freezed == progressPercent
            ? _value.progressPercent
            : progressPercent // ignore: cast_nullable_to_non_nullable
                  as double?,
        daysRemaining: null == daysRemaining
            ? _value.daysRemaining
            : daysRemaining // ignore: cast_nullable_to_non_nullable
                  as int,
        dailyPaceRequired: freezed == dailyPaceRequired
            ? _value.dailyPaceRequired
            : dailyPaceRequired // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        periodStart: null == periodStart
            ? _value.periodStart
            : periodStart // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        periodEnd: null == periodEnd
            ? _value.periodEnd
            : periodEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalWithProgressImpl implements _GoalWithProgress {
  const _$GoalWithProgressImpl({
    required this.id,
    required this.kind,
    this.goalType,
    this.label,
    this.targetValue,
    this.currentValue,
    this.progressPercent,
    required this.daysRemaining,
    this.dailyPaceRequired,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
  });

  factory _$GoalWithProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalWithProgressImplFromJson(json);

  @override
  final String id;
  @override
  final String kind;
  // 'TRACKED' | 'SELF_REPORT'
  @override
  final String? goalType;
  @override
  final String? label;
  @override
  final int? targetValue;
  @override
  final int? currentValue;
  @override
  final double? progressPercent;
  @override
  final int daysRemaining;
  @override
  final int? dailyPaceRequired;
  @override
  final String status;
  @override
  final DateTime periodStart;
  @override
  final DateTime periodEnd;

  @override
  String toString() {
    return 'GoalWithProgress(id: $id, kind: $kind, goalType: $goalType, label: $label, targetValue: $targetValue, currentValue: $currentValue, progressPercent: $progressPercent, daysRemaining: $daysRemaining, dailyPaceRequired: $dailyPaceRequired, status: $status, periodStart: $periodStart, periodEnd: $periodEnd)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalWithProgressImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.goalType, goalType) ||
                other.goalType == goalType) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.targetValue, targetValue) ||
                other.targetValue == targetValue) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.progressPercent, progressPercent) ||
                other.progressPercent == progressPercent) &&
            (identical(other.daysRemaining, daysRemaining) ||
                other.daysRemaining == daysRemaining) &&
            (identical(other.dailyPaceRequired, dailyPaceRequired) ||
                other.dailyPaceRequired == dailyPaceRequired) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    kind,
    goalType,
    label,
    targetValue,
    currentValue,
    progressPercent,
    daysRemaining,
    dailyPaceRequired,
    status,
    periodStart,
    periodEnd,
  );

  /// Create a copy of GoalWithProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalWithProgressImplCopyWith<_$GoalWithProgressImpl> get copyWith =>
      __$$GoalWithProgressImplCopyWithImpl<_$GoalWithProgressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalWithProgressImplToJson(this);
  }
}

abstract class _GoalWithProgress implements GoalWithProgress {
  const factory _GoalWithProgress({
    required final String id,
    required final String kind,
    final String? goalType,
    final String? label,
    final int? targetValue,
    final int? currentValue,
    final double? progressPercent,
    required final int daysRemaining,
    final int? dailyPaceRequired,
    required final String status,
    required final DateTime periodStart,
    required final DateTime periodEnd,
  }) = _$GoalWithProgressImpl;

  factory _GoalWithProgress.fromJson(Map<String, dynamic> json) =
      _$GoalWithProgressImpl.fromJson;

  @override
  String get id;
  @override
  String get kind; // 'TRACKED' | 'SELF_REPORT'
  @override
  String? get goalType;
  @override
  String? get label;
  @override
  int? get targetValue;
  @override
  int? get currentValue;
  @override
  double? get progressPercent;
  @override
  int get daysRemaining;
  @override
  int? get dailyPaceRequired;
  @override
  String get status;
  @override
  DateTime get periodStart;
  @override
  DateTime get periodEnd;

  /// Create a copy of GoalWithProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoalWithProgressImplCopyWith<_$GoalWithProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
