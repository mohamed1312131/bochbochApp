// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreateGoalInputImpl _$$CreateGoalInputImplFromJson(
  Map<String, dynamic> json,
) => _$CreateGoalInputImpl(
  kind: json['kind'] as String,
  goalType: json['goalType'] as String?,
  targetValue: (json['targetValue'] as num?)?.toInt(),
  label: json['label'] as String?,
);

Map<String, dynamic> _$$CreateGoalInputImplToJson(
  _$CreateGoalInputImpl instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'goalType': instance.goalType,
  'targetValue': instance.targetValue,
  'label': instance.label,
};
