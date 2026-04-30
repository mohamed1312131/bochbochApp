import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal_models.freezed.dart';
part 'goal_models.g.dart';

@freezed
class CreateGoalInput with _$CreateGoalInput {
  const factory CreateGoalInput({
    required String kind, // 'TRACKED' | 'SELF_REPORT'
    String? goalType, // 'REVENUE' | 'PROFIT' | 'ORDERS' | 'NEW_CUSTOMERS'
    int? targetValue,
    String? label,
  }) = _CreateGoalInput;

  factory CreateGoalInput.fromJson(Map<String, dynamic> json) =>
      _$CreateGoalInputFromJson(json);
}

extension CreateGoalInputX on CreateGoalInput {
  Map<String, dynamic> toJsonNonNull() {
    return toJson()..removeWhere((_, v) => v == null);
  }
}
