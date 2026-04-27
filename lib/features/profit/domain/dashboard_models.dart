class DashboardToday {
  const DashboardToday({
    required this.grossRevenue,
    required this.realProfit,
    required this.orderCount,
    required this.profitMarginPct,
  });

  final int grossRevenue;
  final int realProfit;
  final int orderCount;
  final double profitMarginPct;

  factory DashboardToday.fromJson(Map<String, dynamic> json) => DashboardToday(
        grossRevenue: json['grossRevenue'] as int,
        realProfit: json['realProfit'] as int,
        orderCount: json['orderCount'] as int,
        profitMarginPct: (json['profitMarginPct'] as num).toDouble(),
      );
}

class LowStockProduct {
  const LowStockProduct({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantSku,
    required this.stockQuantity,
    required this.threshold,
  });

  final String productId;
  final String productName;
  final String variantId;
  final String variantSku;
  final int stockQuantity;
  final int threshold;

  factory LowStockProduct.fromJson(Map<String, dynamic> json) =>
      LowStockProduct(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        variantId: json['variantId'] as String,
        variantSku: json['variantSku'] as String,
        stockQuantity: json['stockQuantity'] as int,
        threshold: json['threshold'] as int,
      );
}

class DashboardAlerts {
  const DashboardAlerts({
    required this.lowStockProducts,
    required this.lowStockCount,
  });

  final List<LowStockProduct> lowStockProducts;
  final int lowStockCount;

  factory DashboardAlerts.fromJson(Map<String, dynamic> json) =>
      DashboardAlerts(
        lowStockProducts: (json['lowStockProducts'] as List)
            .map((e) => LowStockProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
        lowStockCount: json['lowStockCount'] as int,
      );
}

class DashboardData {
  const DashboardData({
    required this.today,
    required this.alerts,
    required this.insights,
  });

  final DashboardToday today;
  final DashboardAlerts alerts;
  final List<String> insights;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        today: DashboardToday.fromJson(json['today'] as Map<String, dynamic>),
        alerts:
            DashboardAlerts.fromJson(json['alerts'] as Map<String, dynamic>),
        insights: List<String>.from(json['insights'] as List),
      );
}