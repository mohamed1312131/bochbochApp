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
    required this.codAccepted,
    required this.codTotal,
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
  final int codAccepted;
  final int codTotal;
  final DateTime? firstOrderDate;
  final DateTime? lastOrderDate;
  final double? returnRate;
  final double? avgDaysBetweenOrders;
  final DateTime? predictedNextOrderDate;

  /// True when the customer is "at risk by cadence" (FLUTTER_SPEC §3.8):
  /// has at least 3 orders AND went silent for >1.5× their avg cadence.
  bool get isAtRiskByCadence {
    if (totalOrders < 3) return false;
    final cadence = avgDaysBetweenOrders;
    if (cadence == null || cadence <= 0) return false;
    return daysSinceLastOrder > cadence * 1.5;
  }

  /// `daysSinceLastOrder / avgDaysBetweenOrders` as a ratio; null when
  /// cadence isn't available.
  double? get cadenceRatio {
    final cadence = avgDaysBetweenOrders;
    if (cadence == null || cadence <= 0) return null;
    return daysSinceLastOrder / cadence;
  }

  factory CustomerStats.fromJson(Map<String, dynamic> json) => CustomerStats(
        totalOrders: json['totalOrders'] as int? ?? 0,
        totalSpent: json['totalSpent'] as int? ?? 0,
        avgOrderValue: json['avgOrderValue'] as int? ?? 0,
        daysSinceLastOrder: json['daysSinceLastOrder'] as int? ?? 0,
        hasHighReturnRate: json['hasHighReturnRate'] as bool? ?? false,
        codAccepted: json['codAccepted'] as int? ?? 0,
        codTotal: json['codTotal'] as int? ?? 0,
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

// Sentinel for copyWith null-clearing of nullable fields (blockReason,
// blockedAt, birthday, riskReason, riskUpdatedAt, rfmUpdatedAt).
// Without it, `?? this` makes it impossible to clear a stale value
// when unblocking / clearing birthday / dropping risk reason
// optimistically.
const Object _customerUnchanged = Object();

/// Customer's preferred contact channel — drives the F7 contact pill
/// and the F10 channel chip in the profile header.
enum ContactChannel {
  whatsapp('WHATSAPP', 'WhatsApp'),
  sms('SMS', 'SMS'),
  call('CALL', 'Appel'),
  instagramDm('INSTAGRAM_DM', 'Instagram DM'),
  facebookDm('FACEBOOK_DM', 'Facebook DM');

  const ContactChannel(this.wire, this.label);
  final String wire;
  final String label;

  static ContactChannel fromWire(String wire) =>
      ContactChannel.values.firstWhere(
        (e) => e.wire == wire,
        orElse: () => ContactChannel.whatsapp,
      );
}

/// Customer's risk level — surfaced as a colored badge in F10.
enum RiskLevel {
  green('GREEN', 'Faible'),
  yellow('YELLOW', 'Modéré'),
  red('RED', 'Élevé');

  const RiskLevel(this.wire, this.label);
  final String wire;
  final String label;

  static RiskLevel fromWire(String wire) =>
      RiskLevel.values.firstWhere(
        (e) => e.wire == wire,
        orElse: () => RiskLevel.green,
      );
}

/// RFM segment — computed nightly by F11 cron, displayed as the
/// header pill in F10.
enum RfmSegment {
  champion('CHAMPION', 'Champion'),
  loyal('LOYAL', 'Fidèle'),
  promising('PROMISING', 'Prometteur'),
  atRisk('AT_RISK', 'À risque'),
  dormant('DORMANT', 'Dormant'),
  newCustomer('NEW', 'Nouveau');

  const RfmSegment(this.wire, this.label);
  final String wire;
  final String label;

  static RfmSegment fromWire(String wire) =>
      RfmSegment.values.firstWhere(
        (e) => e.wire == wire,
        orElse: () => RfmSegment.newCustomer,
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
    this.isBlocked = false,
    this.blockReason,
    this.blockedAt,
    this.requirePrepayment = false,
    this.birthday,
    this.preferredContactChannel = ContactChannel.whatsapp,
    this.codEnabled = true,
    this.codRefusalCount = 0,
    this.riskLevel = RiskLevel.green,
    this.riskReason,
    this.riskUpdatedAt,
    this.rfmSegment = RfmSegment.newCustomer,
    this.rfmUpdatedAt,
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
  final bool isBlocked;
  final String? blockReason;
  final DateTime? blockedAt;
  final bool requirePrepayment;
  // F5 — customer profile (NEW_FEATURES_SPEC §2.1)
  final DateTime? birthday;
  final ContactChannel preferredContactChannel;
  final bool codEnabled;
  final int codRefusalCount;
  final RiskLevel riskLevel;
  final String? riskReason;
  final DateTime? riskUpdatedAt;
  final RfmSegment rfmSegment;
  final DateTime? rfmUpdatedAt;

  /// True when the customer's birthday is within the next 7 days
  /// (year-agnostic). Drives the 🎂 emoji indicator in the F10 profile
  /// header.
  bool get isBirthdaySoon {
    final b = birthday;
    if (b == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Year-agnostic: project the birthday onto this year, but if it has
    // already passed by more than a day, project onto next year.
    DateTime nextOccurrence = DateTime(today.year, b.month, b.day);
    if (nextOccurrence.isBefore(today)) {
      nextOccurrence = DateTime(today.year + 1, b.month, b.day);
    }
    final daysAway = nextOccurrence.difference(today).inDays;
    return daysAway >= 0 && daysAway <= 7;
  }

  /// Days until the next birthday occurrence (0 = today, 7 = a week
  /// away). Returns null when [birthday] is null.
  int? get daysUntilBirthday {
    final b = birthday;
    if (b == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime nextOccurrence = DateTime(today.year, b.month, b.day);
    if (nextOccurrence.isBefore(today)) {
      nextOccurrence = DateTime(today.year + 1, b.month, b.day);
    }
    return nextOccurrence.difference(today).inDays;
  }

  CustomerDetail copyWith({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? governorate,
    String? notes,
    int? defaultDiscountAmount,
    bool? isBlocked,
    Object? blockReason = _customerUnchanged,
    Object? blockedAt = _customerUnchanged,
    bool? requirePrepayment,
    Object? birthday = _customerUnchanged,
    ContactChannel? preferredContactChannel,
    bool? codEnabled,
    int? codRefusalCount,
    RiskLevel? riskLevel,
    Object? riskReason = _customerUnchanged,
    Object? riskUpdatedAt = _customerUnchanged,
    RfmSegment? rfmSegment,
    Object? rfmUpdatedAt = _customerUnchanged,
    List<String>? tags,
  }) {
    return CustomerDetail(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      stats: stats,
      lastProducts: lastProducts,
      createdAt: createdAt,
      address: address ?? this.address,
      city: city ?? this.city,
      governorate: governorate ?? this.governorate,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      segment: segment,
      defaultDiscountAmount:
          defaultDiscountAmount ?? this.defaultDiscountAmount,
      defaultDiscountExpiresAt: defaultDiscountExpiresAt,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: identical(blockReason, _customerUnchanged)
          ? this.blockReason
          : blockReason as String?,
      blockedAt: identical(blockedAt, _customerUnchanged)
          ? this.blockedAt
          : blockedAt as DateTime?,
      requirePrepayment: requirePrepayment ?? this.requirePrepayment,
      birthday: identical(birthday, _customerUnchanged)
          ? this.birthday
          : birthday as DateTime?,
      preferredContactChannel:
          preferredContactChannel ?? this.preferredContactChannel,
      codEnabled: codEnabled ?? this.codEnabled,
      codRefusalCount: codRefusalCount ?? this.codRefusalCount,
      riskLevel: riskLevel ?? this.riskLevel,
      riskReason: identical(riskReason, _customerUnchanged)
          ? this.riskReason
          : riskReason as String?,
      riskUpdatedAt: identical(riskUpdatedAt, _customerUnchanged)
          ? this.riskUpdatedAt
          : riskUpdatedAt as DateTime?,
      rfmSegment: rfmSegment ?? this.rfmSegment,
      rfmUpdatedAt: identical(rfmUpdatedAt, _customerUnchanged)
          ? this.rfmUpdatedAt
          : rfmUpdatedAt as DateTime?,
    );
  }

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
        isBlocked: json['isBlocked'] as bool? ?? false,
        blockReason: json['blockReason'] as String?,
        blockedAt: json['blockedAt'] != null
            ? DateTime.parse(json['blockedAt'] as String)
            : null,
        requirePrepayment:
            json['requirePrepayment'] as bool? ?? false,
        // F5 fields. Safe defaults so a stale backend response (server
        // not yet on the new build) doesn't crash the screen.
        birthday: json['birthday'] != null
            ? DateTime.parse(json['birthday'] as String)
            : null,
        preferredContactChannel: json['preferredContactChannel'] != null
            ? ContactChannel.fromWire(json['preferredContactChannel'] as String)
            : ContactChannel.whatsapp,
        codEnabled: json['codEnabled'] as bool? ?? true,
        codRefusalCount: json['codRefusalCount'] as int? ?? 0,
        riskLevel: json['riskLevel'] != null
            ? RiskLevel.fromWire(json['riskLevel'] as String)
            : RiskLevel.green,
        riskReason: json['riskReason'] as String?,
        riskUpdatedAt: json['riskUpdatedAt'] != null
            ? DateTime.parse(json['riskUpdatedAt'] as String)
            : null,
        rfmSegment: json['rfmSegment'] != null
            ? RfmSegment.fromWire(json['rfmSegment'] as String)
            : RfmSegment.newCustomer,
        rfmUpdatedAt: json['rfmUpdatedAt'] != null
            ? DateTime.parse(json['rfmUpdatedAt'] as String)
            : null,
      );
}

/// Payload for `PUT /customers/:id`. Optional fields are omitted when null
/// so the backend keeps the existing value.
class CustomerUpdateInput {
  const CustomerUpdateInput({
    required this.name,
    required this.phone,
    this.address,
    this.city,
    this.governorate,
    this.notes,
    this.defaultDiscountAmount,
  });

  final String name;
  final String phone;
  final String? address;
  final String? city;
  final String? governorate;
  final String? notes;
  final int? defaultDiscountAmount;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (governorate != null && governorate!.isNotEmpty)
          'governorate': governorate,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (defaultDiscountAmount != null)
          'defaultDiscountAmount': defaultDiscountAmount,
      };
}