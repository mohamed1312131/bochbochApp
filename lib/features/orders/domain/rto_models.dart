/// Domain types for the Return-to-Origin (RTO) flow.
library;

/// Why the package is being returned. Stored on Order.rtoReason.
enum RtoReason {
  refused('REFUSED', 'Client a refusé'),
  unreachable('UNREACHABLE', 'Client injoignable'),
  addressError('ADDRESS_ERROR', 'Adresse incorrecte'),
  other('OTHER', 'Autre');

  const RtoReason(this.wire, this.label);
  final String wire;
  final String label;

  static RtoReason fromWire(String wire) =>
      RtoReason.values.firstWhere(
        (e) => e.wire == wire,
        orElse: () => RtoReason.other,
      );
}

/// Two valid target statuses for POST /orders/:id/rto. The
/// re-attempt path (RTO_IN_TRANSIT → SHIPPED) goes through the
/// regular PATCH /:id/status endpoint, not this one.
enum RtoTargetStatus {
  inTransit('RTO_IN_TRANSIT'),
  received('RTO_RECEIVED');

  const RtoTargetStatus(this.wire);
  final String wire;
}

class RtoStockRestoreLine {
  const RtoStockRestoreLine({
    required this.variantId,
    required this.productName,
    required this.quantityRestored,
    required this.newOnHand,
  });

  final String variantId;
  final String productName;
  final int quantityRestored;
  final int newOnHand;

  factory RtoStockRestoreLine.fromJson(Map<String, dynamic> json) =>
      RtoStockRestoreLine(
        variantId: json['variantId'] as String,
        productName: json['productName'] as String,
        quantityRestored: (json['quantityRestored'] as num).toInt(),
        newOnHand: (json['newOnHand'] as num).toInt(),
      );
}

class RtoCustomerEffect {
  const RtoCustomerEffect({
    required this.id,
    required this.codRefusalCount,
    required this.codEnabled,
    required this.autoDisabledNow,
  });

  final String id;
  final int codRefusalCount;
  final bool codEnabled;
  final bool autoDisabledNow;

  factory RtoCustomerEffect.fromJson(Map<String, dynamic> json) =>
      RtoCustomerEffect(
        id: json['id'] as String,
        codRefusalCount: (json['codRefusalCount'] as num).toInt(),
        codEnabled: json['codEnabled'] as bool,
        autoDisabledNow: json['autoDisabledNow'] as bool,
      );
}

class MarkRtoResult {
  const MarkRtoResult({
    required this.orderId,
    required this.orderStatus,
    required this.rtoReason,
    required this.rtoReceivedAt,
    required this.stockRestored,
    required this.customer,
  });

  final String orderId;
  final String orderStatus;
  final String rtoReason;
  final DateTime? rtoReceivedAt;
  final List<RtoStockRestoreLine> stockRestored;
  final RtoCustomerEffect? customer;

  factory MarkRtoResult.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>;
    return MarkRtoResult(
      orderId: order['id'] as String,
      orderStatus: order['status'] as String,
      rtoReason: order['rtoReason'] as String,
      rtoReceivedAt: order['rtoReceivedAt'] != null
          ? DateTime.parse(order['rtoReceivedAt'] as String)
          : null,
      stockRestored: (json['stockRestored'] as List<dynamic>? ?? const [])
          .map((e) => RtoStockRestoreLine.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      customer: json['customer'] != null
          ? RtoCustomerEffect.fromJson(
              json['customer'] as Map<String, dynamic>)
          : null,
    );
  }
}
