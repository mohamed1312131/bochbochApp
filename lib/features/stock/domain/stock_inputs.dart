import 'stock_enums.dart';

class RestockInput {
  const RestockInput({
    required this.variantId,
    required this.quantity,
    required this.unitCost,
    required this.idempotencyKey,
    this.supplierName,
    this.notes,
  });

  final String variantId;
  final int quantity;
  final int unitCost;
  final String idempotencyKey;
  final String? supplierName;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'quantity': quantity,
        'unitCost': unitCost,
        if (supplierName != null) 'supplierName': supplierName,
        if (notes != null) 'notes': notes,
      };
}

class AdjustmentInput {
  const AdjustmentInput({
    required this.variantId,
    required this.newOnHandQuantity,
    required this.reason,
    required this.idempotencyKey,
    this.notes,
    this.photoUrl,
  });

  final String variantId;

  /// Absolute target on-hand after the adjustment, not a delta.
  /// The sheet computes this from `currentState.onHand + signedDelta`
  /// so the wire contract matches the backend (single source of truth
  /// for the final state, no server-side delta arithmetic on stale data).
  final int newOnHandQuantity;
  final StockAdjustmentReason reason;
  final String idempotencyKey;
  final String? notes;
  final String? photoUrl;

  Map<String, dynamic> toJson() => {
        'newOnHandQuantity': newOnHandQuantity,
        'reasonCode': reason.apiValue,
        if (notes != null) 'notes': notes,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'idempotencyKey': idempotencyKey,
      };
}

class CategoryInput {
  const CategoryInput({required this.name});
  final String name;
  Map<String, dynamic> toJson() => {'name': name};
}
