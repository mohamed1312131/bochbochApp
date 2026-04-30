// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'boutique_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Boutique _$BoutiqueFromJson(Map<String, dynamic> json) {
  return _Boutique.fromJson(json);
}

/// @nodoc
mixin _$Boutique {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime? get archivedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // Fields populated after Stage 5B (backend extension):
  String? get category =>
      throw _privateConstructorUsedError; // 'Vêtements' | 'Accessoires' | etc.
  String? get city =>
      throw _privateConstructorUsedError; // Tunisian governorate name
  String? get logoUrl => throw _privateConstructorUsedError; // Cloudinary URL
  String? get brandColor =>
      throw _privateConstructorUsedError; // Hex string (e.g. '#05687B')
  String? get address =>
      throw _privateConstructorUsedError; // Full address line
  String? get email =>
      throw _privateConstructorUsedError; // Boutique contact email
  String? get mf => throw _privateConstructorUsedError;

  /// Serializes this Boutique to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Boutique
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoutiqueCopyWith<Boutique> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoutiqueCopyWith<$Res> {
  factory $BoutiqueCopyWith(Boutique value, $Res Function(Boutique) then) =
      _$BoutiqueCopyWithImpl<$Res, Boutique>;
  @useResult
  $Res call({
    String id,
    String name,
    DateTime? archivedAt,
    DateTime createdAt,
    DateTime updatedAt,
    String? category,
    String? city,
    String? logoUrl,
    String? brandColor,
    String? address,
    String? email,
    String? mf,
  });
}

/// @nodoc
class _$BoutiqueCopyWithImpl<$Res, $Val extends Boutique>
    implements $BoutiqueCopyWith<$Res> {
  _$BoutiqueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Boutique
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? archivedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? category = freezed,
    Object? city = freezed,
    Object? logoUrl = freezed,
    Object? brandColor = freezed,
    Object? address = freezed,
    Object? email = freezed,
    Object? mf = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            archivedAt: freezed == archivedAt
                ? _value.archivedAt
                : archivedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            city: freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String?,
            logoUrl: freezed == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            brandColor: freezed == brandColor
                ? _value.brandColor
                : brandColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            mf: freezed == mf
                ? _value.mf
                : mf // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BoutiqueImplCopyWith<$Res>
    implements $BoutiqueCopyWith<$Res> {
  factory _$$BoutiqueImplCopyWith(
    _$BoutiqueImpl value,
    $Res Function(_$BoutiqueImpl) then,
  ) = __$$BoutiqueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    DateTime? archivedAt,
    DateTime createdAt,
    DateTime updatedAt,
    String? category,
    String? city,
    String? logoUrl,
    String? brandColor,
    String? address,
    String? email,
    String? mf,
  });
}

/// @nodoc
class __$$BoutiqueImplCopyWithImpl<$Res>
    extends _$BoutiqueCopyWithImpl<$Res, _$BoutiqueImpl>
    implements _$$BoutiqueImplCopyWith<$Res> {
  __$$BoutiqueImplCopyWithImpl(
    _$BoutiqueImpl _value,
    $Res Function(_$BoutiqueImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Boutique
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? archivedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? category = freezed,
    Object? city = freezed,
    Object? logoUrl = freezed,
    Object? brandColor = freezed,
    Object? address = freezed,
    Object? email = freezed,
    Object? mf = freezed,
  }) {
    return _then(
      _$BoutiqueImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        archivedAt: freezed == archivedAt
            ? _value.archivedAt
            : archivedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        city: freezed == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String?,
        logoUrl: freezed == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        brandColor: freezed == brandColor
            ? _value.brandColor
            : brandColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        mf: freezed == mf
            ? _value.mf
            : mf // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BoutiqueImpl implements _Boutique {
  const _$BoutiqueImpl({
    required this.id,
    required this.name,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.city,
    this.logoUrl,
    this.brandColor,
    this.address,
    this.email,
    this.mf,
  });

  factory _$BoutiqueImpl.fromJson(Map<String, dynamic> json) =>
      _$$BoutiqueImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime? archivedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  // Fields populated after Stage 5B (backend extension):
  @override
  final String? category;
  // 'Vêtements' | 'Accessoires' | etc.
  @override
  final String? city;
  // Tunisian governorate name
  @override
  final String? logoUrl;
  // Cloudinary URL
  @override
  final String? brandColor;
  // Hex string (e.g. '#05687B')
  @override
  final String? address;
  // Full address line
  @override
  final String? email;
  // Boutique contact email
  @override
  final String? mf;

  @override
  String toString() {
    return 'Boutique(id: $id, name: $name, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, category: $category, city: $city, logoUrl: $logoUrl, brandColor: $brandColor, address: $address, email: $email, mf: $mf)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoutiqueImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.archivedAt, archivedAt) ||
                other.archivedAt == archivedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.brandColor, brandColor) ||
                other.brandColor == brandColor) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.mf, mf) || other.mf == mf));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    archivedAt,
    createdAt,
    updatedAt,
    category,
    city,
    logoUrl,
    brandColor,
    address,
    email,
    mf,
  );

  /// Create a copy of Boutique
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoutiqueImplCopyWith<_$BoutiqueImpl> get copyWith =>
      __$$BoutiqueImplCopyWithImpl<_$BoutiqueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BoutiqueImplToJson(this);
  }
}

abstract class _Boutique implements Boutique {
  const factory _Boutique({
    required final String id,
    required final String name,
    final DateTime? archivedAt,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final String? category,
    final String? city,
    final String? logoUrl,
    final String? brandColor,
    final String? address,
    final String? email,
    final String? mf,
  }) = _$BoutiqueImpl;

  factory _Boutique.fromJson(Map<String, dynamic> json) =
      _$BoutiqueImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  DateTime? get archivedAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt; // Fields populated after Stage 5B (backend extension):
  @override
  String? get category; // 'Vêtements' | 'Accessoires' | etc.
  @override
  String? get city; // Tunisian governorate name
  @override
  String? get logoUrl; // Cloudinary URL
  @override
  String? get brandColor; // Hex string (e.g. '#05687B')
  @override
  String? get address; // Full address line
  @override
  String? get email; // Boutique contact email
  @override
  String? get mf;

  /// Create a copy of Boutique
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoutiqueImplCopyWith<_$BoutiqueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
