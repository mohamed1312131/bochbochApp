

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
    this.variantAttributes,
    this.primaryImageUrl,
  });

  final String id;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int unitCost;
  final int subtotal;
  final int returnedQuantity;
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
        variantAttributes:
            json['variantAttributes'] as Map<String, dynamic>?,
        primaryImageUrl: json['primaryImageUrl'] as String?,
      );
}

// Full order (detail)
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
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.adCampaignId,
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final String? adCampaignId;

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
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        notes: json['notes'] as String?,
        adCampaignId: json['adCampaignId'] as String?,
      );
}

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

  bool get isProfit => orderProfit > 0;

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