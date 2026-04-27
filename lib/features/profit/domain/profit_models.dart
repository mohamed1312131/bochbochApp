class ProfitSummary {
  const ProfitSummary({
    required this.grossRevenue,
    required this.totalDiscount,
    required this.netRevenue,
    required this.productCost,
    required this.shippingCost,
    required this.adSpend,
    required this.totalRefunds,
    required this.realProfit,
    required this.profitMarginPct,
    required this.orderCount,
    required this.returnCount,
    required this.periodLabel,
    required this.insights,
    this.prevNetRevenue,
    this.prevRealProfit,
    this.prevOrderCount,
    this.revenueChangePercent,
    this.profitChangePercent,
  });

  final int grossRevenue;
  final int totalDiscount;
  final int netRevenue;
  final int productCost;
  final int shippingCost;
  final int adSpend;
  final int totalRefunds;
  final int realProfit;
  final double profitMarginPct;
  final int orderCount;
  final int returnCount;
  final String periodLabel;
  final List<String> insights;
  final int? prevNetRevenue;
  final int? prevRealProfit;
  final int? prevOrderCount;
  final int? revenueChangePercent;
  final int? profitChangePercent;

  bool get isProfit => realProfit >= 0;

  factory ProfitSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    final period = json['period'] as Map<String, dynamic>;
    return ProfitSummary(
      grossRevenue: summary['grossRevenue'] as int,
      totalDiscount: summary['totalDiscount'] as int,
      netRevenue: summary['netRevenue'] as int,
      productCost: summary['productCost'] as int,
      shippingCost: summary['shippingCost'] as int,
      adSpend: summary['adSpend'] as int,
      totalRefunds: summary['totalRefunds'] as int,
      realProfit: summary['realProfit'] as int,
      profitMarginPct: (summary['profitMarginPct'] as num).toDouble(),
      orderCount: summary['orderCount'] as int,
      returnCount: summary['returnCount'] as int,
      periodLabel: period['label'] as String,
      insights: (json['insights'] as List).cast<String>(),
      prevNetRevenue: (json['previousPeriod'] as Map<String, dynamic>?)?['netRevenue'] as int?,
      prevRealProfit: (json['previousPeriod'] as Map<String, dynamic>?)?['realProfit'] as int?,
      prevOrderCount: (json['previousPeriod'] as Map<String, dynamic>?)?['orderCount'] as int?,
      revenueChangePercent: (json['changes'] as Map<String, dynamic>?)?['revenueChangePercent'] as int?,
      profitChangePercent: (json['changes'] as Map<String, dynamic>?)?['profitChangePercent'] as int?,
    );
  }
}

class ProductProfit {
  const ProductProfit({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.unitsReturned,
    required this.grossRevenue,
    required this.productCost,
    required this.profit,
    required this.profitMarginPct,
  });

  final String productId;
  final String productName;
  final int unitsSold;
  final int unitsReturned;
  final int grossRevenue;
  final int productCost;
  final int profit;
  final double profitMarginPct;

  factory ProductProfit.fromJson(Map<String, dynamic> json) =>
      ProductProfit(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        unitsSold: json['unitsSold'] as int,
        unitsReturned: json['unitsReturned'] as int,
        grossRevenue: json['grossRevenue'] as int,
        productCost: json['productCost'] as int,
        profit: json['profit'] as int,
        profitMarginPct: (json['profitMarginPct'] as num).toDouble(),
      );
}

class TrendDataPoint {
  const TrendDataPoint({
    required this.label,
    required this.date,
    required this.grossRevenue,
    required this.realProfit,
    required this.orderCount,
  });

  final String label;
  final String date;
  final int grossRevenue;
  final int realProfit;
  final int orderCount;

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) =>
      TrendDataPoint(
        label: json['label'] as String,
        date: json['date'] as String,
        grossRevenue: json['grossRevenue'] as int,
        realProfit: json['realProfit'] as int,
        orderCount: json['orderCount'] as int,
      );
}

class ProfitTrend {
  const ProfitTrend({
    required this.periodLabel,
    required this.granularity,
    required this.dataPoints,
  });

  final String periodLabel;
  final String granularity;
  final List<TrendDataPoint> dataPoints;

  factory ProfitTrend.fromJson(Map<String, dynamic> json) => ProfitTrend(
        periodLabel: (json['period'] as Map<String, dynamic>)['label']
            as String,
        granularity: json['granularity'] as String,
        dataPoints: (json['dataPoints'] as List)
            .map((e) => TrendDataPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
