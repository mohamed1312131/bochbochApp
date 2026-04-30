// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreateGoalInput _$CreateGoalInputFromJson(Map<String, dynamic> json) {
  return _CreateGoalInput.fromJson(json);
}

/// @nodoc
mixin _$CreateGoalInput {
  String get kind =>
      throw _privateConstructorUsedError; // 'TRACKED' | 'SELF_REPORT'
  String? get goalType =>
      throw _privateConstructorUsedError; // 'REVENUE' | 'PROFIT' | 'ORDERS' | 'NEW_CUSTOMERS'
  int? get targetValue => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;

  /// Serializes this CreateGoalInput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateGoalInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateGoalInputCopyWith<CreateGoalInput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateGoalInputCopyWith<$Res> {
  factory $CreateGoalInputCopyWith(
    CreateGoalInput value,
    $Res Function(CreateGoalInput) then,
  ) = _$CreateGoalInputCopyWithImpl<$Res, CreateGoalInput>;
  @useResult
  $Res call({String kind, String? goalType, int? targetValue, String? label});
}

/// @nodoc
class _$CreateGoalInputCopyWithImpl<$Res, $Val extends CreateGoalInput>
    implements $CreateGoalInputCopyWith<$Res> {
  _$CreateGoalInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateGoalInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? goalType = freezed,
    Object? targetValue = freezed,
    Object? label = freezed,
  }) {
    return _then(
      _value.copyWith(
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as String,
            goalType: freezed == goalType
                ? _value.goalType
                : goalType // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetValue: freezed == targetValue
                ? _value.targetValue
                : targetValue // ignore: cast_nullable_to_non_nullable
                      as int?,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateGoalInputImplCopyWith<$Res>
    implements $CreateGoalInputCopyWith<$Res> {
  factory _$$CreateGoalInputImplCopyWith(
    _$CreateGoalInputImpl value,
    $Res Function(_$CreateGoalInputImpl) then,
  ) = __$$CreateGoalInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String kind, String? goalType, int? targetValue, String? label});
}

/// @nodoc
class __$$CreateGoalInputImplCopyWithImpl<$Res>
    extends _$CreateGoalInputCopyWithImpl<$Res, _$CreateGoalInputImpl>
    implements _$$CreateGoalInputImplCopyWith<$Res> {
  __$$CreateGoalInputImplCopyWithImpl(
    _$CreateGoalInputImpl _value,
    $Res Function(_$CreateGoalInputImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreateGoalInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? kind = null,
    Object? goalType = freezed,
    Object? targetValue = freezed,
    Object? label = freezed,
  }) {
    return _then(
      _$CreateGoalInputImpl(
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
        goalType: freezed == goalType
            ? _value.goalType
            : goalType // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetValue: freezed == targetValue
            ? _value.targetValue
            : targetValue // ignore: cast_nullable_to_non_nullable
                  as int?,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateGoalInputImpl implements _CreateGoalInput {
  const _$CreateGoalInputImpl({
    required this.kind,
    this.goalType,
    this.targetValue,
    this.label,
  });

  factory _$CreateGoalInputImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateGoalInputImplFromJson(json);

  @override
  final String kind;
  // 'TRACKED' | 'SELF_REPORT'
  @override
  final String? goalType;
  // 'REVENUE' | 'PROFIT' | 'ORDERS' | 'NEW_CUSTOMERS'
  @override
  final int? targetValue;
  @override
  final String? label;

  @override
  String toString() {
    return 'CreateGoalInput(kind: $kind, goalType: $goalType, targetValue: $targetValue, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateGoalInputImpl &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.goalType, goalType) ||
                other.goalType == goalType) &&
            (identical(other.targetValue, targetValue) ||
                other.targetValue == targetValue) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, kind, goalType, targetValue, label);

  /// Create a copy of CreateGoalInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateGoalInputImplCopyWith<_$CreateGoalInputImpl> get copyWith =>
      __$$CreateGoalInputImplCopyWithImpl<_$CreateGoalInputImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateGoalInputImplToJson(this);
  }
}

abstract class _CreateGoalInput implements CreateGoalInput {
  const factory _CreateGoalInput({
    required final String kind,
    final String? goalType,
    final int? targetValue,
    final String? label,
  }) = _$CreateGoalInputImpl;

  factory _CreateGoalInput.fromJson(Map<String, dynamic> json) =
      _$CreateGoalInputImpl.fromJson;

  @override
  String get kind; // 'TRACKED' | 'SELF_REPORT'
  @override
  String? get goalType; // 'REVENUE' | 'PROFIT' | 'ORDERS' | 'NEW_CUSTOMERS'
  @override
  int? get targetValue;
  @override
  String? get label;

  /// Create a copy of CreateGoalInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateGoalInputImplCopyWith<_$CreateGoalInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
