/// Domain types for the order-exchange flow.
///
/// Three layers:
///   - [Exchange]                — server row, returned by GET/POST endpoints
///   - [ExchangeDraft]           — mutable client-side state collected
///                                 across the 3-screen flow
///   - [CreateExchangeResult]    — POST response wrapper
library;

class Exchange {
  const Exchange({
    required this.id,
    required this.orderId,
    required this.originalVariantId,
    required this.newProductId,
    required this.newVariantId,
    required this.newProductName,
    required this.newVariantAttributes,
    required this.newUnitPrice,
    required this.returnShippingCost,
    required this.redeliveryCost,
    required this.priceDifference,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String? originalVariantId;
  final String newProductId;
  final String newVariantId;
  final String newProductName;
  final Map<String, String> newVariantAttributes;
  final int newUnitPrice;
  final int? returnShippingCost;
  final int? redeliveryCost;
  final int? priceDifference;
  final String? notes;
  final DateTime createdAt;

  factory Exchange.fromJson(Map<String, dynamic> json) {
    final attrsRaw = json['newVariantAttributes'] as Map<String, dynamic>? ?? const {};
    return Exchange(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      originalVariantId: json['originalVariantId'] as String?,
      newProductId: json['newProductId'] as String,
      newVariantId: json['newVariantId'] as String,
      newProductName: json['newProductName'] as String,
      newVariantAttributes: attrsRaw.map((k, v) => MapEntry(k, v.toString())),
      newUnitPrice: (json['newUnitPrice'] as num).toInt(),
      returnShippingCost: (json['returnShippingCost'] as num?)?.toInt(),
      redeliveryCost: (json['redeliveryCost'] as num?)?.toInt(),
      priceDifference: (json['priceDifference'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Snapshot of a swap target used during the picker → costs → confirm flow.
class ExchangeTargetVariant {
  const ExchangeTargetVariant({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.attributes,
    required this.sellPrice,
    required this.onHandQuantity,
  });

  final String productId;
  final String variantId;
  final String productName;
  final Map<String, String> attributes;
  final int sellPrice;
  final int onHandQuantity;

  String get attributesLabel =>
      attributes.values.where((v) => v.isNotEmpty).join(' · ');
}

/// Snapshot of the original (returning) item — for read-only display on
/// the picker and confirmation screens. Display-only in v1: the
/// `variantId` of the original is not exposed by GET /orders/:id, so
/// we omit it and submit `originalVariantId: null`. Add the field
/// here (and bubble it up from the API) when the backend response
/// surfaces variantId on items.
class ExchangeOriginalSnapshot {
  const ExchangeOriginalSnapshot({
    required this.productName,
    required this.attributes,
    required this.unitPrice,
  });

  final String productName;
  final Map<String, String> attributes;
  final int unitPrice;

  String get attributesLabel =>
      attributes.values.where((v) => v.isNotEmpty).join(' · ');
}

/// Mutable draft built across the 3-screen flow. Pass through Riverpod
/// state, NOT through navigator arguments — the screens share the same
/// notifier.
class ExchangeDraft {
  const ExchangeDraft({
    required this.orderId,
    required this.orderNumber,
    this.original,
    this.target,
    this.returnShippingCost,
    this.redeliveryCost,
    this.priceDifference,
    this.notes,
  });

  final String orderId;
  final String? orderNumber;
  final ExchangeOriginalSnapshot? original;
  final ExchangeTargetVariant? target;
  final int? returnShippingCost;
  final int? redeliveryCost;
  final int? priceDifference;
  final String? notes;

  bool get hasCosts =>
      (returnShippingCost ?? 0) != 0 ||
      (redeliveryCost ?? 0) != 0 ||
      (priceDifference ?? 0) != 0;

  ExchangeDraft copyWith({
    ExchangeOriginalSnapshot? original,
    ExchangeTargetVariant? target,
    int? returnShippingCost,
    int? redeliveryCost,
    int? priceDifference,
    String? notes,
  }) =>
      ExchangeDraft(
        orderId: orderId,
        orderNumber: orderNumber,
        original: original ?? this.original,
        target: target ?? this.target,
        returnShippingCost: returnShippingCost ?? this.returnShippingCost,
        redeliveryCost: redeliveryCost ?? this.redeliveryCost,
        priceDifference: priceDifference ?? this.priceDifference,
        notes: notes ?? this.notes,
      );

  /// Used by the "Passer" (skip costs) action — wipes any cost
  /// values without altering the picked target. Kept distinct from
  /// [copyWith] because copyWith's `?? this` semantics make it
  /// impossible to clear a previously-set cost back to null.
  ExchangeDraft clearCosts() => ExchangeDraft(
        orderId: orderId,
        orderNumber: orderNumber,
        original: original,
        target: target,
        returnShippingCost: null,
        redeliveryCost: null,
        priceDifference: null,
        notes: null,
      );
}

class CreateExchangeResult {
  const CreateExchangeResult({
    required this.exchange,
    required this.stockWarning,
    required this.orderStatus,
  });

  final Exchange exchange;
  final bool stockWarning;
  final String orderStatus;

  factory CreateExchangeResult.fromJson(Map<String, dynamic> json) =>
      CreateExchangeResult(
        exchange: Exchange.fromJson(json['exchange'] as Map<String, dynamic>),
        stockWarning: json['stockWarning'] as bool,
        orderStatus: (json['order'] as Map<String, dynamic>)['status'] as String,
      );
}
