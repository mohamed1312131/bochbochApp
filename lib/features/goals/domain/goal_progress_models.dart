import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal_progress_models.freezed.dart';
part 'goal_progress_models.g.dart';

@freezed
class GoalWithProgress with _$GoalWithProgress {
  const factory GoalWithProgress({
    required String id,
    required String kind, // 'TRACKED' | 'SELF_REPORT'
    String? goalType,
    String? label,
    int? targetValue,
    int? currentValue,
    double? progressPercent,
    required int daysRemaining,
    int? dailyPaceRequired,
    required String status,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) = _GoalWithProgress;

  factory GoalWithProgress.fromJson(Map<String, dynamic> json) =>
      _$GoalWithProgressFromJson(json);
}
