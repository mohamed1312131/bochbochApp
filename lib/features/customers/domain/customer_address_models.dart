/// Domain types for Customer Addresses (Feature 9).
library;

const Object _addrUnchanged = Object();

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.customerId,
    required this.addressLine,
    required this.city,
    required this.governorate,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.label,
    this.deliveryNotes,
  });

  final String id;
  final String customerId;
  final String? label;
  final String addressLine;
  final String city;
  final String governorate;
  final String? deliveryNotes;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// copyWith uses a sentinel for nullable fields so `null` is a
  /// meaningful "clear this" signal and not "leave unchanged".
  CustomerAddress copyWith({
    Object? label = _addrUnchanged,
    String? addressLine,
    String? city,
    String? governorate,
    Object? deliveryNotes = _addrUnchanged,
    bool? isDefault,
    DateTime? updatedAt,
  }) =>
      CustomerAddress(
        id: id,
        customerId: customerId,
        label: identical(label, _addrUnchanged)
            ? this.label
            : label as String?,
        addressLine: addressLine ?? this.addressLine,
        city: city ?? this.city,
        governorate: governorate ?? this.governorate,
        deliveryNotes: identical(deliveryNotes, _addrUnchanged)
            ? this.deliveryNotes
            : deliveryNotes as String?,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        label: json['label'] as String?,
        addressLine: json['addressLine'] as String,
        city: json['city'] as String,
        governorate: json['governorate'] as String,
        deliveryNotes: json['deliveryNotes'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
