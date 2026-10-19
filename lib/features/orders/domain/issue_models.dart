/// Domain types for the order-issue (Lost / Damaged) flow.
library;

/// Issue type — what went wrong with the delivery.
enum IssueType {
  notReceived('NOT_RECEIVED', 'Colis non reçu'),
  damaged('DAMAGED', 'Colis endommagé'),
  wrongAddress('WRONG_ADDRESS', 'Mauvaise adresse');

  const IssueType(this.wire, this.label);
  final String wire;
  final String label;

  static IssueType fromWire(String wire) =>
      IssueType.values.firstWhere((e) => e.wire == wire);
}

/// Resolution — how the seller will make it right.
enum IssueResolution {
  resend('RESEND', 'Renvoyer la commande'),
  refund('REFUND', 'Rembourser la cliente'),
  storeCredit('STORE_CREDIT', 'Crédit boutique');

  const IssueResolution(this.wire, this.label);
  final String wire;
  final String label;

  static IssueResolution fromWire(String wire) =>
      IssueResolution.values.firstWhere((e) => e.wire == wire);
}

class Issue {
  const Issue({
    required this.id,
    required this.orderId,
    required this.issueType,
    required this.resolution,
    required this.createdAt,
    this.resolvedAt,
    this.notes,
  });

  final String id;
  final String orderId;
  final IssueType issueType;
  final IssueResolution resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? notes;

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        issueType: IssueType.fromWire(json['issueType'] as String),
        resolution: IssueResolution.fromWire(json['resolution'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
        notes: json['notes'] as String?,
      );
}

class StockRestoreLine {
  const StockRestoreLine({
    required this.variantId,
    required this.productName,
    required this.quantityRestored,
    required this.newOnHand,
  });

  final String variantId;
  final String productName;
  final int quantityRestored;
  final int newOnHand;

  factory StockRestoreLine.fromJson(Map<String, dynamic> json) =>
      StockRestoreLine(
        variantId: json['variantId'] as String,
        productName: json['productName'] as String,
        quantityRestored: (json['quantityRestored'] as num).toInt(),
        newOnHand: (json['newOnHand'] as num).toInt(),
      );
}

class CreateIssueResult {
  const CreateIssueResult({
    required this.issue,
    required this.stockRestored,
    required this.orderStatus,
  });

  final Issue issue;
  final List<StockRestoreLine> stockRestored;
  final String orderStatus;

  factory CreateIssueResult.fromJson(Map<String, dynamic> json) =>
      CreateIssueResult(
        issue: Issue.fromJson(json['issue'] as Map<String, dynamic>),
        stockRestored: (json['stockRestored'] as List<dynamic>? ?? const [])
            .map((e) => StockRestoreLine.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        orderStatus: (json['order'] as Map<String, dynamic>)['status'] as String,
      );
}

/// Mutable draft carried between the type-pick screen and the
/// resolution screen via Navigator constructor args.
class IssueDraft {
  const IssueDraft({
    required this.orderId,
    required this.orderNumber,
    required this.expectedStockRestore,
    this.issueType,
    this.resolution,
    this.notes,
  });

  final String orderId;
  final String? orderNumber;
  final IssueType? issueType;
  final IssueResolution? resolution;
  final String? notes;

  /// Computed client-side from the order's items so the resolution
  /// screen can show "these items will be restored" BEFORE the seller
  /// confirms. Backend re-computes authoritatively at submit time.
  final List<ExpectedRestoreLine> expectedStockRestore;

  IssueDraft copyWith({
    IssueType? issueType,
    IssueResolution? resolution,
    String? notes,
  }) =>
      IssueDraft(
        orderId: orderId,
        orderNumber: orderNumber,
        expectedStockRestore: expectedStockRestore,
        issueType: issueType ?? this.issueType,
        resolution: resolution ?? this.resolution,
        notes: notes ?? this.notes,
      );
}

/// Client-side preview of which items will be restored. Mirrors the
/// service's per-item rules (skip backorder, skip bundle, subtract
/// returnedQuantity). Used only for the resolution-screen banner;
/// the server's authoritative `stockRestored` overrides this in the
/// success snackbar/log.
class ExpectedRestoreLine {
  const ExpectedRestoreLine({
    required this.productName,
    required this.quantity,
  });
  final String productName;
  final int quantity;
}
