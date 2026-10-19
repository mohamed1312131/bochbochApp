

class OrderCustomer {
  const OrderCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.city,
    this.governorate,
  });

  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? city;
  final String? governorate;

  factory OrderCustomer.fromJson(Map<String, dynamic> json) => OrderCustomer(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String?,
        city: json['city'] as String?,
        governorate: json['governorate'] as String?,
      );
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.subtotal,
    required this.returnedQuantity,
    required this.isBackorder,
    required this.fulfillmentStatus,
    this.variantAttributes,
    this.primaryImageUrl,
    this.estimatedRestockDate,
    this.variantId,
  });

  final String id;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int unitCost;
  final int subtotal;
  final int returnedQuantity;
  final bool isBackorder;
  // Partial fulfillment (Feature 7). 'PENDING' until the seller runs
  // partial-fulfill; then 'SHIPPED' or 'BACKORDERED' per item.
  final String fulfillmentStatus;
  final DateTime? estimatedRestockDate;
  final String? variantId;
  final Map<String, dynamic>? variantAttributes;
  final String? primaryImageUrl;

  String get attributeLabel {
    if (variantAttributes == null || variantAttributes!.isEmpty) return '';
    return variantAttributes!.entries
        .map((e) => '${e.value}')
        .join(' · ');
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        productName: json['productName'] as String,
        quantity: json['quantity'] as int,
        unitPrice: json['unitPrice'] as int,
        unitCost: json['unitCost'] as int,
        subtotal: json['subtotal'] as int,
        returnedQuantity: json['returnedQuantity'] as int,
        // Safe defaults so stale backend responses don't crash.
        isBackorder: json['isBackorder'] as bool? ?? false,
        fulfillmentStatus:
            json['fulfillmentStatus'] as String? ?? 'PENDING',
        estimatedRestockDate: json['estimatedRestockDate'] != null
            ? DateTime.parse(json['estimatedRestockDate'] as String)
            : null,
        variantId: json['variantId'] as String?,
        variantAttributes:
            json['variantAttributes'] as Map<String, dynamic>?,
        primaryImageUrl: json['primaryImageUrl'] as String?,
      );
}

// Full order (detail)
/// Per-order profit breakdown (NEW_FEATURES_SPEC §1.4). All cost
/// fields are positive integers EXCEPT [exchangeCost], which is
/// signed (a cheaper replacement can net a gain).
class ProfitBreakdown {
  const ProfitBreakdown({
    required this.salePrice,
    required this.productCost,
    required this.shippingCost,
    required this.discountApplied,
    required this.exchangeCost,
    required this.netProfit,
    required this.marginPercent,
  });

  final int salePrice;
  final int productCost;
  final int shippingCost;
  final int discountApplied;
  final int exchangeCost;
  final int netProfit;
  final double marginPercent;

  bool get hasExchange => exchangeCost != 0;

  factory ProfitBreakdown.fromJson(Map<String, dynamic> json) =>
      ProfitBreakdown(
        salePrice: (json['salePrice'] as num).toInt(),
        productCost: (json['productCost'] as num).toInt(),
        shippingCost: (json['shippingCost'] as num).toInt(),
        discountApplied: (json['discountApplied'] as num).toInt(),
        exchangeCost: (json['exchangeCost'] as num).toInt(),
        netProfit: (json['netProfit'] as num).toInt(),
        marginPercent: (json['marginPercent'] as num).toDouble(),
      );
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customer,
    required this.items,
    required this.grossRevenue,
    required this.discountAmount,
    required this.netRevenue,
    required this.totalCost,
    required this.shippingCost,
    required this.adSpend,
    required this.orderProfit,
    required this.realProfit,
    required this.profitBreakdown,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.adCampaignId,
    this.rtoReason,
    this.rtoReceivedAt,
  });

  final String id;
  final String orderNumber;
  final String status;
  final OrderCustomer customer;
  final List<OrderItem> items;
  final int grossRevenue;
  final int discountAmount;
  final int netRevenue;
  final int totalCost;
  final int shippingCost;
  final int adSpend;
  final int orderProfit;
  final int realProfit;
  final ProfitBreakdown profitBreakdown;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final String? adCampaignId;
  // RTO tracking (Feature 6). rtoReason captures the most-recent
  // reason; persisted even after re-attempt for historical context.
  final String? rtoReason;
  final DateTime? rtoReceivedAt;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        status: json['status'] as String,
        customer: OrderCustomer.fromJson(
            json['customer'] as Map<String, dynamic>),
        items: (json['items'] as List)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        grossRevenue: json['grossRevenue'] as int,
        discountAmount: json['discountAmount'] as int,
        netRevenue: json['netRevenue'] as int,
        totalCost: json['totalCost'] as int,
        shippingCost: json['shippingCost'] as int,
        adSpend: json['adSpend'] as int,
        orderProfit: json['orderProfit'] as int,
        realProfit: json['realProfit'] as int,
        profitBreakdown: ProfitBreakdown.fromJson(
            json['profitBreakdown'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        notes: json['notes'] as String?,
        adCampaignId: json['adCampaignId'] as String?,
        rtoReason: json['rtoReason'] as String?,
        rtoReceivedAt: json['rtoReceivedAt'] != null
            ? DateTime.parse(json['rtoReceivedAt'] as String)
            : null,
      );
}

/// FLUTTER_SPEC §2.9 — kinds of pill that can appear on an order row.
enum OrderFlag {
  vip,
  cod,
  bloque,
  retour,
  echange,
}

/// Priority order used when truncating to fit the 2-pill cap. Higher
/// up the list = higher priority (Bloqué wins, COD loses).
const _flagPriority = [
  OrderFlag.bloque,
  OrderFlag.vip,
  OrderFlag.retour,
  OrderFlag.echange,
  OrderFlag.cod,
];

// Lean order (list)
class OrderLean {
  const OrderLean({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.itemCount,
    required this.grossRevenue,
    required this.discountAmount,
    required this.netRevenue,
    required this.shippingCost,
    required this.adSpend,
    required this.orderProfit,
    required this.createdAt,
    required this.customerTags,
    required this.customerIsBlocked,
    required this.customerCodEnabled,
    required this.hasActiveReturn,
    required this.hasActiveExchange,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String customerName;
  final String customerPhone;
  final int itemCount;
  final int grossRevenue;
  final int discountAmount;
  final int netRevenue;
  final int shippingCost;
  final int adSpend;
  final int orderProfit;
  final DateTime createdAt;
  // F12 — flag-source signals.
  final List<String> customerTags;
  final bool customerIsBlocked;
  final bool customerCodEnabled;
  final bool hasActiveReturn;
  final bool hasActiveExchange;

  bool get isProfit => orderProfit > 0;

  /// All flags raised on this order, in priority order. The UI is
  /// expected to cap at 2 + overflow — see [visibleFlags].
  List<OrderFlag> get flags {
    final out = <OrderFlag>[];
    for (final f in _flagPriority) {
      switch (f) {
        case OrderFlag.bloque:
          if (customerIsBlocked) out.add(f);
        case OrderFlag.vip:
          // Case-insensitive match — sellers might type "vip", "Vip", etc.
          if (customerTags.any((t) => t.toLowerCase() == 'vip')) out.add(f);
        case OrderFlag.retour:
          if (hasActiveReturn) out.add(f);
        case OrderFlag.echange:
          if (hasActiveExchange || status == 'EXCHANGE_IN_PROGRESS') {
            out.add(f);
          }
        case OrderFlag.cod:
          if (customerCodEnabled) out.add(f);
      }
    }
    return out;
  }

  /// Capped slice of [flags] suitable for direct rendering. Returns
  /// the first 2 flags, leaving overflow handling to the UI (it can
  /// inspect `flags.length` to decide whether to render a `+N` pill).
  List<OrderFlag> get visibleFlags {
    final all = flags;
    return all.length <= 2 ? all : all.sublist(0, 2);
  }

  /// Number of flags hidden by the cap. Returns 0 when all fit.
  int get overflowCount {
    final n = flags.length;
    return n > 2 ? n - 2 : 0;
  }

  factory OrderLean.fromJson(Map<String, dynamic> json) => OrderLean(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        status: json['status'] as String,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String,
        itemCount: json['itemCount'] as int,
        grossRevenue: json['grossRevenue'] as int,
        discountAmount: json['discountAmount'] as int? ?? 0,
        netRevenue: json['netRevenue'] as int,
        shippingCost: json['shippingCost'] as int? ?? 0,
        adSpend: json['adSpend'] as int? ?? 0,
        orderProfit: json['orderProfit'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        // Safe defaults so a stale server response (without F12 fields)
        // doesn't crash the list.
        customerTags: (json['customerTags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList(growable: false) ??
            const <String>[],
        customerIsBlocked: json['customerIsBlocked'] as bool? ?? false,
        customerCodEnabled: json['customerCodEnabled'] as bool? ?? true,
        hasActiveReturn: json['hasActiveReturn'] as bool? ?? false,
        hasActiveExchange: json['hasActiveExchange'] as bool? ?? false,
      );
}

// Input models for creating order
class OrderItemInput {
  const OrderItemInput({
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.productName,
  });

  final String productId;
  final String variantId;
  final int quantity;
  final int unitPrice;
  final String productName;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}