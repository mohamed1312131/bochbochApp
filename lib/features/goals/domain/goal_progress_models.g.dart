// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_progress_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GoalWithProgressImpl _$$GoalWithProgressImplFromJson(
  Map<String, dynamic> json,
) => _$GoalWithProgressImpl(
  id: json['id'] as String,
  kind: json['kind'] as String,
  goalType: json['goalType'] as String?,
  label: json['label'] as String?,
  targetValue: (json['targetValue'] as num?)?.toInt(),
  currentValue: (json['currentValue'] as num?)?.toInt(),
  progressPercent: (json['progressPercent'] as num?)?.toDouble(),
  daysRemaining: (json['daysRemaining'] as num).toInt(),
  dailyPaceRequired: (json['dailyPaceRequired'] as num?)?.toInt(),
  status: json['status'] as String,
  periodStart: DateTime.parse(json['periodStart'] as String),
  periodEnd: DateTime.parse(json['periodEnd'] as String),
);

Map<String, dynamic> _$$GoalWithProgressImplToJson(
  _$GoalWithProgressImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.kind,
  'goalType': instance.goalType,
  'label': instance.label,
  'targetValue': instance.targetValue,
  'currentValue': instance.currentValue,
  'progressPercent': instance.progressPercent,
  'daysRemaining': instance.daysRemaining,
  'dailyPaceRequired': instance.dailyPaceRequired,
  'status': instance.status,
  'periodStart': instance.periodStart.toIso8601String(),
  'periodEnd': instance.periodEnd.toIso8601String(),
};
