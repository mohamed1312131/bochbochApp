class CustomerLean {
  const CustomerLean({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.totalSpent,
    required this.createdAt,
    this.city,
    this.governorate,
    this.segment,
    this.lastOrderDate,
    this.defaultDiscountAmount = 0,
    this.hasHighReturnRate = false,
  });

  final String id;
  final String name;
  final String phone;
  final int totalOrders;
  final int totalSpent;
  final DateTime createdAt;
  final String? city;
  final String? governorate;
  final String? segment;
  final DateTime? lastOrderDate;
  final int defaultDiscountAmount;
  final bool hasHighReturnRate;

  factory CustomerLean.fromJson(Map<String, dynamic> json) => CustomerLean(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        totalOrders: json['totalOrders'] as int? ?? 0,
        totalSpent: json['totalSpent'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        city: json['city'] as String?,
        governorate: json['governorate'] as String?,
        segment: json['segment'] as String?,
        lastOrderDate: json['lastOrderDate'] != null
            ? DateTime.parse(json['lastOrderDate'] as String)
            : null,
        defaultDiscountAmount: json['defaultDiscountAmount'] as int? ?? 0,
        hasHighReturnRate: json['hasHighReturnRate'] as bool? ?? false,
      );
}

class CustomerStats {
  const CustomerStats({
    required this.totalOrders,
    required this.totalSpent,
    required this.avgOrderValue,
    required this.daysSinceLastOrder,
    required this.hasHighReturnRate,
    this.firstOrderDate,
    this.lastOrderDate,
    this.returnRate,
    this.avgDaysBetweenOrders,
    this.predictedNextOrderDate,
  });

  final int totalOrders;
  final int totalSpent;
  final int avgOrderValue;
  final int daysSinceLastOrder;
  final bool hasHighReturnRate;
  final DateTime? firstOrderDate;
  final DateTime? lastOrderDate;
  final double? returnRate;
  final double? avgDaysBetweenOrders;
  final DateTime? predictedNextOrderDate;

  factory CustomerStats.fromJson(Map<String, dynamic> json) => CustomerStats(
        totalOrders: json['totalOrders'] as int? ?? 0,
        totalSpent: json['totalSpent'] as int? ?? 0,
        avgOrderValue: json['avgOrderValue'] as int? ?? 0,
        daysSinceLastOrder: json['daysSinceLastOrder'] as int? ?? 0,
        hasHighReturnRate: json['hasHighReturnRate'] as bool? ?? false,
        firstOrderDate: json['firstOrderDate'] != null
            ? DateTime.parse(json['firstOrderDate'] as String)
            : null,
        lastOrderDate: json['lastOrderDate'] != null
            ? DateTime.parse(json['lastOrderDate'] as String)
            : null,
        returnRate: (json['returnRate'] as num?)?.toDouble(),
        avgDaysBetweenOrders:
            (json['avgDaysBetweenOrders'] as num?)?.toDouble(),
        predictedNextOrderDate: json['predictedNextOrderDate'] != null
            ? DateTime.parse(json['predictedNextOrderDate'] as String)
            : null,
      );
}

class CustomerLastProduct {
  const CustomerLastProduct({
    required this.productId,
    required this.productName,
    required this.lastOrderedAt,
    required this.inStock,
  });

  final String productId;
  final String productName;
  final DateTime lastOrderedAt;
  final bool inStock;

  factory CustomerLastProduct.fromJson(Map<String, dynamic> json) =>
      CustomerLastProduct(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        lastOrderedAt:
            DateTime.parse(json['lastOrderedAt'] as String),
        inStock: json['inStock'] as bool? ?? false,
      );
}

class CustomerDetail {
  const CustomerDetail({
    required this.id,
    required this.name,
    required this.phone,
    required this.stats,
    required this.lastProducts,
    required this.createdAt,
    this.address,
    this.city,
    this.governorate,
    this.notes,
    this.tags = const [],
    this.segment,
    this.defaultDiscountAmount = 0,
    this.defaultDiscountExpiresAt,
  });

  final String id;
  final String name;
  final String phone;
  final CustomerStats stats;
  final List<CustomerLastProduct> lastProducts;
  final DateTime createdAt;
  final String? address;
  final String? city;
  final String? governorate;
  final String? notes;
  final List<String> tags;
  final String? segment;
  final int defaultDiscountAmount;
  final DateTime? defaultDiscountExpiresAt;

  factory CustomerDetail.fromJson(Map<String, dynamic> json) =>
      CustomerDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        stats: CustomerStats.fromJson(
            json['stats'] as Map<String, dynamic>),
        lastProducts: (json['lastProducts'] as List? ?? [])
            .map((e) => CustomerLastProduct.fromJson(
                e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        address: json['address'] as String?,
        city: json['city'] as String?,
        governorate: json['governorate'] as String?,
        notes: json['notes'] as String?,
        tags: (json['tags'] as List? ?? []).cast<String>(),
        segment: json['segment'] as String?,
        defaultDiscountAmount:
            json['defaultDiscountAmount'] as int? ?? 0,
        defaultDiscountExpiresAt:
            json['defaultDiscountExpiresAt'] != null
                ? DateTime.parse(
                    json['defaultDiscountExpiresAt'] as String)
                : null,
      );
}