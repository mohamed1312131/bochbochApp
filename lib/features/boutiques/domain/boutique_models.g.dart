// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boutique_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BoutiqueImpl _$$BoutiqueImplFromJson(Map<String, dynamic> json) =>
    _$BoutiqueImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      archivedAt: json['archivedAt'] == null
          ? null
          : DateTime.parse(json['archivedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      category: json['category'] as String?,
      city: json['city'] as String?,
      logoUrl: json['logoUrl'] as String?,
      brandColor: json['brandColor'] as String?,
      address: json['address'] as String?,
      email: json['email'] as String?,
      mf: json['mf'] as String?,
    );

Map<String, dynamic> _$$BoutiqueImplToJson(_$BoutiqueImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'archivedAt': instance.archivedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'category': instance.category,
      'city': instance.city,
      'logoUrl': instance.logoUrl,
      'brandColor': instance.brandColor,
      'address': instance.address,
      'email': instance.email,
      'mf': instance.mf,
    };
