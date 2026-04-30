import 'package:freezed_annotation/freezed_annotation.dart';

part 'boutique_models.freezed.dart';
part 'boutique_models.g.dart';

@freezed
class Boutique with _$Boutique {
  const factory Boutique({
    required String id,
    required String name,
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,

    // Fields populated after Stage 5B (backend extension):
    String? category,        // 'Vêtements' | 'Accessoires' | etc.
    String? city,            // Tunisian governorate name
    String? logoUrl,         // Cloudinary URL
    String? brandColor,      // Hex string (e.g. '#05687B')
    String? address,         // Full address line
    String? email,           // Boutique contact email
    String? mf,              // Tunisian tax ID (Matricule Fiscal)
  }) = _Boutique;

  factory Boutique.fromJson(Map<String, dynamic> json) =>
      _$BoutiqueFromJson(json);
}

extension BoutiqueOnboarded on Boutique {
  /// Returns true when the boutique has the minimum data required for
  /// the user to use the app. Used by the router to decide if a user
  /// needs to complete onboarding.
  bool get isOnboarded =>
      name.isNotEmpty &&
      (category != null && category!.isNotEmpty) &&
      (city != null && city!.isNotEmpty);
}
