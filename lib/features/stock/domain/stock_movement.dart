import 'stock_enums.dart';

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.type,
    required this.qtyDelta,
    required this.qtyBefore,
    required this.qtyAfter,
    required this.unitCostAtTime,
    required this.referenceType,
    required this.createdAt,
    this.reasonCode,
    this.referenceId,
    this.referenceLabel,
    this.actorUserId,
    this.photoUrl,
    this.notes,
    this.idempotencyKey,
  });

  final String id;
  final String productId;
  final String variantId;
  final StockMovementType type;
  final StockAdjustmentReason? reasonCode;
  final int qtyDelta;
  final int qtyBefore;
  final int qtyAfter;
  final int unitCostAtTime;
  final StockReferenceType referenceType;
  final String? referenceId;
  final String? referenceLabel;
  final String? actorUserId;
  final String? photoUrl;
  final String? notes;
  final String? idempotencyKey;
  final DateTime createdAt;

  String displaySubtitle() {
    if (referenceLabel != null) return referenceLabel!;
    if (notes != null && notes!.isNotEmpty) return notes!;
    return '';
  }

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] as String,
      productId: json['productId'] as String,
      variantId: json['variantId'] as String,
      type: StockMovementType.fromApi(json['type'] as String),
      reasonCode: json['reasonCode'] != null
          ? StockAdjustmentReason.fromApi(json['reasonCode'] as String)
          : null,
      qtyDelta: json['qtyDelta'] as int,
      qtyBefore: json['qtyBefore'] as int,
      qtyAfter: json['qtyAfter'] as int,
      unitCostAtTime: json['unitCostAtTime'] as int,
      referenceType:
          StockReferenceType.fromApi(json['referenceType'] as String),
      referenceId: json['referenceId'] as String?,
      referenceLabel: json['referenceLabel'] as String?,
      actorUserId: json['actorUserId'] as String?,
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      idempotencyKey: json['idempotencyKey'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'variantId': variantId,
        'type': type.apiValue,
        if (reasonCode != null) 'reasonCode': reasonCode!.apiValue,
        'qtyDelta': qtyDelta,
        'qtyBefore': qtyBefore,
        'qtyAfter': qtyAfter,
        'unitCostAtTime': unitCostAtTime,
        'referenceType': referenceType.apiValue,
        if (referenceId != null) 'referenceId': referenceId,
        if (referenceLabel != null) 'referenceLabel': referenceLabel,
        if (actorUserId != null) 'actorUserId': actorUserId,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (notes != null) 'notes': notes,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
