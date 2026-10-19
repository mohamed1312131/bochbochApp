/// Domain types for the Partial Fulfillment flow (Feature 7).
library;

import 'order_models.dart';

/// Per-item fulfillment status. Mirrors backend
/// ITEM_FULFILLMENT_STATUSES.
enum FulfillmentStatus {
  pending('PENDING', 'En attente'),
  shipped('SHIPPED', 'Expédié'),
  backordered('BACKORDERED', 'En rupture');

  const FulfillmentStatus(this.wire, this.label);
  final String wire;
  final String label;

  static FulfillmentStatus fromWire(String wire) =>
      FulfillmentStatus.values.firstWhere(
        (e) => e.wire == wire,
        orElse: () => FulfillmentStatus.pending,
      );
}

/// Action sent on POST /orders/:id/partial-fulfill.
///  - SHIP_NOW: persist the split and flip order to PARTIALLY_SHIPPED.
///  - WAIT: pure read; returns the would-be-split without writes.
enum PartialFulfillAction {
  shipNow('SHIP_NOW'),
  wait('WAIT');

  const PartialFulfillAction(this.wire);
  final String wire;
}

/// Minimum customer info returned alongside the partial-fulfill result
/// so the confirmation screen can render the contact card without an
/// extra fetch.
class PartialFulfillCustomer {
  const PartialFulfillCustomer({
    required this.id,
    required this.name,
    required this.preferredContactChannel,
    this.phone,
  });

  final String id;
  final String name;
  final String? phone;
  final String preferredContactChannel;

  factory PartialFulfillCustomer.fromJson(Map<String, dynamic> json) =>
      PartialFulfillCustomer(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        preferredContactChannel:
            json['preferredContactChannel'] as String? ?? 'WHATSAPP',
      );
}

/// Order summary returned alongside the partial-fulfill result.
class PartialFulfillOrderRef {
  const PartialFulfillOrderRef({
    required this.id,
    required this.status,
    this.orderNumber,
  });

  final String id;
  final String status;
  final String? orderNumber;

  factory PartialFulfillOrderRef.fromJson(Map<String, dynamic> json) =>
      PartialFulfillOrderRef(
        id: json['id'] as String,
        status: json['status'] as String,
        orderNumber: json['orderNumber'] as String?,
      );
}

/// Response of POST /orders/:id/partial-fulfill.
class PartialFulfillResult {
  const PartialFulfillResult({
    required this.shippedItems,
    required this.backorderedItems,
    required this.order,
    this.customer,
  });

  final List<OrderItem> shippedItems;
  final List<OrderItem> backorderedItems;
  final PartialFulfillOrderRef order;
  final PartialFulfillCustomer? customer;

  /// Whether SHIP_NOW already happened — i.e. items carry a non-PENDING
  /// fulfillmentStatus. Used by the UI to flip from "preview" to
  /// "confirmation" mode.
  bool get isPersisted => order.status == 'PARTIALLY_SHIPPED';

  factory PartialFulfillResult.fromJson(Map<String, dynamic> json) =>
      PartialFulfillResult(
        shippedItems: (json['shippedItems'] as List<dynamic>? ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        backorderedItems:
            (json['backorderedItems'] as List<dynamic>? ?? const [])
                .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList(growable: false),
        order: PartialFulfillOrderRef.fromJson(
            json['order'] as Map<String, dynamic>),
        customer: json['customer'] != null
            ? PartialFulfillCustomer.fromJson(
                json['customer'] as Map<String, dynamic>)
            : null,
      );
}
