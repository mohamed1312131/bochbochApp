import 'stock_enums.dart';

// ── Stock state per variant ────────────────────────────────────
class StockState {
  const StockState({
    required this.variantId,
    required this.onHand,
    required this.available,
    required this.committed,
    required this.backordered,
    required this.committedOrders,
    this.backorderEnabled = false,
    this.currentAvgCostMillimes,
  });

  final String variantId;
  final int onHand;
  final int available;
  final int committed;
  final int backordered;
  final List<CommittedOrderRef> committedOrders;
  final bool backorderEnabled;
  final int? currentAvgCostMillimes;

  factory StockState.fromJson(Map<String, dynamic> json) => StockState(
        variantId: json['variantId'] as String,
        onHand: json['onHand'] as int,
        available: json['available'] as int,
        committed: json['committed'] as int,
        backordered: json['backordered'] as int,
        committedOrders: (json['committedOrders'] as List<dynamic>? ?? [])
            .map((e) =>
                CommittedOrderRef.fromJson(e as Map<String, dynamic>))
            .toList(),
        backorderEnabled: json['backorderEnabled'] as bool? ?? false,
        currentAvgCostMillimes: json['currentAvgCostMillimes'] as int?,
      );
}

class CommittedOrderRef {
  const CommittedOrderRef({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.qty,
  });

  final String orderId;
  final String orderNumber;
  final String customerName;
  final int qty;

  factory CommittedOrderRef.fromJson(Map<String, dynamic> json) =>
      CommittedOrderRef(
        orderId: json['orderId'] as String,
        orderNumber: json['orderNumber'] as String,
        customerName: json['customerName'] as String,
        qty: json['qty'] as int,
      );
}

// ── Bundle / Kit ───────────────────────────────────────────────
class StockBundle {
  const StockBundle({
    required this.bundleProductId,
    required this.components,
    required this.computedAvailability,
  });

  final String bundleProductId;
  final List<BundleComponent> components;
  final int computedAvailability;
}

class BundleComponent {
  const BundleComponent({
    required this.componentVariantId,
    required this.componentProductName,
    required this.componentSku,
    required this.qtyPerBundle,
    required this.componentCost,
    this.componentThumbnailUrl,
  });

  final String componentVariantId;
  final String componentProductName;
  final String componentSku;
  final int qtyPerBundle;
  final int componentCost;
  final String? componentThumbnailUrl;
}

// ── Category ───────────────────────────────────────────────────
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.productCount,
  });

  final String id;
  final String name;
  final int productCount;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        productCount: json['productCount'] as int? ?? 0,
      );
}

// ── Boutique-level stock settings ──────────────────────────────
class BoutiqueStockSettings {
  const BoutiqueStockSettings({
    required this.defaultLowStockThreshold,
    required this.dormantDays,
    required this.defaultBackorderEnabled,
    required this.pushNotifLowStock,
    required this.pushNotifRupture,
    required this.pushNotifRestockConfirmed,
  });

  final int defaultLowStockThreshold;
  final int dormantDays;
  final bool defaultBackorderEnabled;
  final bool pushNotifLowStock;
  final bool pushNotifRupture;
  final bool pushNotifRestockConfirmed;

  BoutiqueStockSettings copyWith({
    int? defaultLowStockThreshold,
    int? dormantDays,
    bool? defaultBackorderEnabled,
    bool? pushNotifLowStock,
    bool? pushNotifRupture,
    bool? pushNotifRestockConfirmed,
  }) =>
      BoutiqueStockSettings(
        defaultLowStockThreshold:
            defaultLowStockThreshold ?? this.defaultLowStockThreshold,
        dormantDays: dormantDays ?? this.dormantDays,
        defaultBackorderEnabled:
            defaultBackorderEnabled ?? this.defaultBackorderEnabled,
        pushNotifLowStock: pushNotifLowStock ?? this.pushNotifLowStock,
        pushNotifRupture: pushNotifRupture ?? this.pushNotifRupture,
        pushNotifRestockConfirmed:
            pushNotifRestockConfirmed ?? this.pushNotifRestockConfirmed,
      );

  factory BoutiqueStockSettings.fromJson(Map<String, dynamic> json) =>
      BoutiqueStockSettings(
        defaultLowStockThreshold: json['defaultLowStockThreshold'] as int,
        dormantDays: json['dormantDays'] as int,
        defaultBackorderEnabled: json['defaultBackorderEnabled'] as bool,
        pushNotifLowStock: json['pushNotifLowStock'] as bool,
        pushNotifRupture: json['pushNotifRupture'] as bool,
        pushNotifRestockConfirmed:
            json['pushNotifRestockConfirmed'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'defaultLowStockThreshold': defaultLowStockThreshold,
        'dormantDays': dormantDays,
        'defaultBackorderEnabled': defaultBackorderEnabled,
        'pushNotifLowStock': pushNotifLowStock,
        'pushNotifRupture': pushNotifRupture,
        'pushNotifRestockConfirmed': pushNotifRestockConfirmed,
      };
}

// ── Stock value report ─────────────────────────────────────────
class StockValueReport {
  const StockValueReport({
    required this.totalValue,
    required this.totalUnits,
    required this.totalProducts,
    required this.topByValue,
  });

  final int totalValue;
  final int totalUnits;
  final int totalProducts;
  final List<StockValueLineItem> topByValue;
}

class StockValueLineItem {
  const StockValueLineItem({
    required this.productId,
    required this.productName,
    required this.units,
    required this.value,
    this.thumbnailUrl,
    this.thumbnailColor,
  });

  final String productId;
  final String productName;
  final int units;
  final int value;
  final String? thumbnailUrl;
  final int? thumbnailColor;
}

// ── Dead stock ─────────────────────────────────────────────────
class DeadStockEntry {
  const DeadStockEntry({
    required this.productId,
    required this.productName,
    required this.units,
    required this.daysSinceLastSale,
    required this.value,
    this.category,
    this.thumbnailUrl,
    this.thumbnailColor,
  });

  final String productId;
  final String productName;
  final int units;
  final int daysSinceLastSale;
  final int value;
  final String? category;
  final String? thumbnailUrl;
  final int? thumbnailColor;
}

// ── Shrinkage / Off-sale outflow ───────────────────────────────
class ShrinkageBreakdown {
  const ShrinkageBreakdown({
    required this.byReason,
    required this.byProduct,
    required this.totalAmount,
    required this.totalUnits,
  });

  final List<StockBreakdownByReason> byReason;
  final List<StockBreakdownByProduct> byProduct;
  final int totalAmount;
  final int totalUnits;
}

class OffSaleOutflowBreakdown {
  const OffSaleOutflowBreakdown({
    required this.byReason,
    required this.byProduct,
    required this.totalAmount,
    required this.totalUnits,
  });

  final List<StockBreakdownByReason> byReason;
  final List<StockBreakdownByProduct> byProduct;
  final int totalAmount;
  final int totalUnits;
}

class StockBreakdownByReason {
  const StockBreakdownByReason({
    required this.reasonLabel,
    required this.units,
    required this.amount,
  });

  final String reasonLabel;
  final int units;
  final int amount;
}

class StockBreakdownByProduct {
  const StockBreakdownByProduct({
    required this.productId,
    required this.productName,
    required this.reasonLabel,
    required this.units,
    required this.amount,
    this.thumbnailUrl,
    this.thumbnailColor,
  });

  final String productId;
  final String productName;
  final String reasonLabel;
  final int units;
  final int amount;
  final String? thumbnailUrl;
  final int? thumbnailColor;
}

// ── Best sellers / Slow movers ─────────────────────────────────
class BestSellerEntry {
  const BestSellerEntry({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.revenue,
    this.thumbnailUrl,
    this.thumbnailColor,
  });

  final String productId;
  final String productName;
  final int unitsSold;
  final int revenue;
  final String? thumbnailUrl;
  final int? thumbnailColor;
}

class SlowMoverEntry {
  const SlowMoverEntry({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.unitsRemaining,
    this.thumbnailUrl,
    this.thumbnailColor,
  });

  final String productId;
  final String productName;
  final int unitsSold;
  final int unitsRemaining;
  final String? thumbnailUrl;
  final int? thumbnailColor;
}

// ── Low-stock variant ──────────────────────────────────────────
class LowStockEntry {
  const LowStockEntry({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantLabel,
    required this.sku,
    required this.currentAvailable,
    required this.threshold,
    this.thumbnailUrl,
    this.thumbnailColor,
    this.currentWacMillimes,
  });

  final String productId;
  final String productName;
  final String variantId;
  final String variantLabel;
  final String sku;
  final int currentAvailable;
  final int threshold;
  final String? thumbnailUrl;
  final int? thumbnailColor;

  /// Weighted-average cost in millimes — used by the Restocker sheet
  /// to compute the post-restock WAC. Null when the variant has no
  /// recorded cost (rare; treat as 0).
  final int? currentWacMillimes;
}

// ── Filter for movements query ─────────────────────────────────
class StockHistoryFilter {
  const StockHistoryFilter({
    this.types,
    this.reasons,
    this.fromDate,
    this.toDate,
  });

  final List<StockMovementType>? types;
  final List<StockAdjustmentReason>? reasons;
  final DateTime? fromDate;
  final DateTime? toDate;

  StockHistoryFilter copyWith({
    List<StockMovementType>? types,
    List<StockAdjustmentReason>? reasons,
    DateTime? fromDate,
    DateTime? toDate,
  }) =>
      StockHistoryFilter(
        types: types ?? this.types,
        reasons: reasons ?? this.reasons,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
      );

  bool get isEmpty =>
      (types == null || types!.isEmpty) &&
      (reasons == null || reasons!.isEmpty) &&
      fromDate == null &&
      toDate == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StockHistoryFilter) return false;
    return _listEq(types, other.types) &&
        _listEq(reasons, other.reasons) &&
        fromDate == other.fromDate &&
        toDate == other.toDate;
  }

  @override
  int get hashCode => Object.hash(
        types == null ? null : Object.hashAll(types!),
        reasons == null ? null : Object.hashAll(reasons!),
        fromDate,
        toDate,
      );

  static bool _listEq<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
