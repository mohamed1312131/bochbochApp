import 'package:freezed_annotation/freezed_annotation.dart';

part 'boutique_patch_input.freezed.dart';
part 'boutique_patch_input.g.dart';

@freezed
class BoutiquePatchInput with _$BoutiquePatchInput {
  const factory BoutiquePatchInput({
    String? name,
    String? category,
    String? city,
    String? brandColor,
    String? address,
    String? email,
    String? mf,
  }) = _BoutiquePatchInput;

  factory BoutiquePatchInput.fromJson(Map<String, dynamic> json) =>
      _$BoutiquePatchInputFromJson(json);
}

extension BoutiquePatchInputX on BoutiquePatchInput {
  Map<String, dynamic> toJsonNonNull() {
    return toJson()..removeWhere((_, v) => v == null);
  }
}
