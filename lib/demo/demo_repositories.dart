import 'package:image_picker/image_picker.dart';

import '../features/boutiques/data/boutique_repository.dart';
import '../features/boutiques/domain/boutique_models.dart';
import '../features/boutiques/domain/boutique_patch_input.dart';
import '../features/customers/data/customer_repository.dart';
import '../features/customers/domain/customer_address_models.dart';
import '../features/customers/domain/customer_models.dart';
import '../features/customers/domain/customer_note_models.dart';
import '../features/goals/data/goal_repository.dart';
import '../features/goals/domain/goal_models.dart';
import '../features/goals/domain/goal_progress_models.dart';
import '../features/orders/data/order_repository.dart';
import '../features/orders/domain/bulk_action_models.dart';
import '../features/orders/domain/exchange_models.dart';
import '../features/orders/domain/issue_models.dart';
import '../features/orders/domain/order_models.dart';
import '../features/orders/domain/partial_fulfill_models.dart';
import '../features/orders/domain/rto_models.dart';
import '../features/products/data/product_repository.dart';
import '../features/products/domain/product_models.dart';
import '../features/profit/data/dashboard_repository.dart';
import '../features/profit/data/profit_repository.dart';
import '../features/profit/domain/dashboard_models.dart';
import '../features/profit/domain/profit_models.dart';
import '../shared/models/paginated_response.dart';
import 'demo_store.dart';

const _latency = Duration(milliseconds: 140);

Future<void> _wait() => Future<void>.delayed(_latency);

class DemoProductRepository extends ProductRepository {
  DemoProductRepository(this.store);
  final DemoStore store;

  Product _full(Map<String, dynamic> json) => Product.fromJson(json);

  ProductLean _lean(Map<String, dynamic> json) {
    final product = _full(json);
    return ProductLean(
      id: product.id,
      name: product.name,
      category: product.category,
      baseCostPrice: product.baseCostPrice,
      baseSellPrice: product.baseSellPrice,
      totalStock: product.totalStock,
      hasLowStock: product.variants.any((variant) => variant.isLowStock),
      isActive: product.isActive,
      isMultiVariant: product.isMultiVariant,
      createdAt: product.createdAt,
      primaryImageUrl: product.primaryImageUrl,
    );
  }

  @override
  Future<PaginatedResponse<ProductLean>> getProducts({
    String? cursor,
    int limit = 20,
    String? name,
    String? category,
    bool? isActive,
  }) async {
    await _wait();
    var values = store.products.values.map(_lean).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (name != null && name.trim().isNotEmpty) {
      final query = name.toLowerCase();
      values = values
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    }
    if (category != null && category.isNotEmpty) {
      values = values.where((p) => p.category == category).toList();
    }
    if (isActive != null) {
      values = values.where((p) => p.isActive == isActive).toList();
    }
    return PaginatedResponse(
      data: values.take(limit).toList(),
      hasMore: values.length > limit,
      total: values.length,
    );
  }

  @override
  Future<Product> getProduct(String id) async {
    await _wait();
    final json = store.products[id];
    if (json == null) throw StateError('Produit introuvable');
    return _full(json);
  }

  @override
  Future<Product> createProduct({
    required String name,
    required int baseCostPrice,
    required int baseSellPrice,
    required int initialStock,
    String? description,
    String? category,
    String? categoryId,
    int? lowStockThreshold,
    bool? backorderEnabled,
    bool? isBundle,
    List<Map<String, dynamic>>? variants,
  }) async {
    await _wait();
    final id = 'prod_demo_${store.nextId()}';
    final now = DateTime.now().toIso8601String();
    final variantRows = variants != null && variants.isNotEmpty
        ? variants.asMap().entries.map((entry) {
            final row = entry.value;
            final attrs = (row['attributes'] as List<dynamic>? ?? const [])
                .map(
                  (a) => <String, dynamic>{
                    'name': (a as Map<String, dynamic>)['name'] ?? 'Option',
                    'value': a['value'] ?? '',
                    'type': a['type'] ?? 'TEXT',
                  },
                )
                .toList();
            final stock = row['initialStock'] as int? ?? 0;
            return <String, dynamic>{
              'id': 'var_${id}_${entry.key + 1}',
              'sku': row['sku'] as String? ?? 'DIDO-${store.nextId()}',
              'stockQuantity': stock,
              'availableQuantity': stock,
              'committedQuantity': 0,
              'backorderedQuantity': 0,
              'lowStockThreshold':
                  row['lowStockThreshold'] as int? ?? lowStockThreshold ?? 3,
              'backorderEnabled':
                  row['backorderEnabled'] as bool? ?? backorderEnabled ?? false,
              'effectiveCostPrice':
                  row['costPriceOverride'] as int? ?? baseCostPrice,
              'effectiveSellPrice':
                  row['sellPriceOverride'] as int? ?? baseSellPrice,
              'costPriceOverride': row['costPriceOverride'],
              'sellPriceOverride': row['sellPriceOverride'],
              'imageId': null,
              'isActive': true,
              'updatedAt': now,
              'attributes': attrs,
            };
          }).toList()
        : <Map<String, dynamic>>[
            {
              'id': 'var_${id}_std',
              'sku': 'DIDO-${store.nextId()}',
              'stockQuantity': initialStock,
              'availableQuantity': initialStock,
              'committedQuantity': 0,
              'backorderedQuantity': 0,
              'lowStockThreshold': lowStockThreshold ?? 3,
              'backorderEnabled': backorderEnabled ?? false,
              'effectiveCostPrice': baseCostPrice,
              'effectiveSellPrice': baseSellPrice,
              'costPriceOverride': null,
              'sellPriceOverride': null,
              'imageId': null,
              'isActive': true,
              'updatedAt': now,
              'attributes': <Map<String, dynamic>>[],
            },
          ];
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'categoryId': categoryId,
      'isBundle': isBundle ?? false,
      'baseCostPrice': baseCostPrice,
      'baseSellPrice': baseSellPrice,
      'isActive': true,
      'isMultiVariant':
          variantRows.length > 1 ||
          ((variantRows.first['attributes'] as List).isNotEmpty),
      'images': <Map<String, dynamic>>[],
      'variants': variantRows,
      'createdAt': now,
      'updatedAt': now,
    };
    store.products[id] = json;
    return _full(json);
  }

  @override
  Future<Product> updateProduct(
    String id, {
    String? name,
    String? description,
    String? category,
    String? categoryId,
    int? baseCostPrice,
    int? baseSellPrice,
    bool? isActive,
    int? lowStockThreshold,
    bool? backorderEnabled,
  }) async {
    await _wait();
    final json = store.products[id];
    if (json == null) throw StateError('Produit introuvable');
    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (category != null) json['category'] = category;
    if (categoryId != null) json['categoryId'] = categoryId;
    if (baseCostPrice != null) json['baseCostPrice'] = baseCostPrice;
    if (baseSellPrice != null) json['baseSellPrice'] = baseSellPrice;
    if (isActive != null) json['isActive'] = isActive;
    for (final raw in json['variants'] as List<dynamic>) {
      final variant = raw as Map<String, dynamic>;
      if (baseCostPrice != null && variant['costPriceOverride'] == null) {
        variant['effectiveCostPrice'] = baseCostPrice;
      }
      if (baseSellPrice != null && variant['sellPriceOverride'] == null) {
        variant['effectiveSellPrice'] = baseSellPrice;
      }
      if (lowStockThreshold != null) {
        variant['lowStockThreshold'] = lowStockThreshold;
      }
      if (backorderEnabled != null) {
        variant['backorderEnabled'] = backorderEnabled;
      }
    }
    json['updatedAt'] = DateTime.now().toIso8601String();
    return _full(json);
  }

  @override
  Future<void> updateStock(
    String id, {
    required int quantity,
    required String variantUpdatedAt,
  }) async {
    await _wait();
    final variants = store.products[id]?['variants'] as List<dynamic>?;
    if (variants == null || variants.isEmpty) return;
    final variant = variants.first as Map<String, dynamic>;
    variant['stockQuantity'] = quantity;
    variant['availableQuantity'] = quantity;
    variant['updatedAt'] = DateTime.now().toIso8601String();
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _wait();
    store.products.remove(id);
  }

  @override
  Future<Map<String, String>> uploadImage(String filePath) async {
    await _wait();
    return {
      'url': 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=',
      'cloudinaryPublicId': 'demo_${store.nextId()}',
    };
  }

  @override
  Future<void> attachImage(
    String productId, {
    required String cloudinaryPublicId,
    required String url,
    bool isPrimary = true,
    String? altText,
  }) async {
    final product = store.products[productId];
    if (product == null) return;
    (product['images'] as List<dynamic>).add({
      'id': 'image_${store.nextId()}',
      'url': url,
      'cloudinaryPublicId': cloudinaryPublicId,
      'isPrimary': isPrimary,
      'displayOrder': 0,
      'altText': altText,
    });
  }
}

class DemoOrderRepository extends OrderRepository {
  DemoOrderRepository(this.store);
  final DemoStore store;

  Order _full(Map<String, dynamic> json) => Order.fromJson(json);

  OrderLean _lean(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>;
    final customerDetail = store.customers[customer['id'] as String];
    return OrderLean(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      customerName: customer['name'] as String,
      customerPhone: customer['phone'] as String,
      itemCount: (json['items'] as List).fold<int>(
        0,
        (sum, item) =>
            sum + ((item as Map<String, dynamic>)['quantity'] as int),
      ),
      grossRevenue: json['grossRevenue'] as int,
      discountAmount: json['discountAmount'] as int,
      netRevenue: json['netRevenue'] as int,
      shippingCost: json['shippingCost'] as int,
      adSpend: json['adSpend'] as int,
      orderProfit: json['orderProfit'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customerTags: (customerDetail?['tags'] as List<dynamic>? ?? const [])
          .cast<String>(),
      customerIsBlocked: customerDetail?['isBlocked'] as bool? ?? false,
      customerCodEnabled: customerDetail?['codEnabled'] as bool? ?? true,
      hasActiveReturn:
          json['status'] == 'RTO_IN_TRANSIT' ||
          json['status'] == 'RTO_RECEIVED',
      hasActiveExchange: (store.exchanges[json['id']] ?? const []).isNotEmpty,
    );
  }

  @override
  Future<PaginatedResponse<OrderLean>> getOrders({
    String? cursor,
    int limit = 20,
    String? status,
    String? from,
    String? to,
  }) async {
    await _wait();
    var rows =
        store.orders.values
            .where((order) => status == null || order['status'] == status)
            .map(_lean)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return PaginatedResponse(
      data: rows.take(limit).toList(),
      hasMore: rows.length > limit,
      total: rows.length,
    );
  }

  @override
  Future<Order> getOrder(String id) async {
    await _wait();
    final json = store.orders[id];
    if (json == null) throw StateError('Commande introuvable');
    return _full(json);
  }

  @override
  Future<Order> createOrder({
    required String customerName,
    required String customerPhone,
    required List<OrderItemInput> items,
    int shippingCost = 0,
    int discountAmount = 0,
    int adSpend = 0,
    String? notes,
    String? customerAddress,
    String? customerCity,
    String? customerGovernorate,
  }) async {
    await _wait();
    final customer = store.customers.values
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (row) => row?['phone'] == customerPhone,
          orElse: () => null,
        );
    final customerId =
        customer?['id'] as String? ?? 'cust_demo_${store.nextId()}';
    final now = DateTime.now();
    if (customer == null) {
      store.customers[customerId] = {
        'id': customerId,
        'name': customerName,
        'phone': customerPhone,
        'address': customerAddress,
        'city': customerCity,
        'governorate': customerGovernorate,
        'notes': null,
        'tags': <String>['Nouveau'],
        'segment': 'Nouveau',
        'defaultDiscountAmount': 0,
        'defaultDiscountExpiresAt': null,
        'isBlocked': false,
        'blockReason': null,
        'blockedAt': null,
        'requirePrepayment': false,
        'birthday': null,
        'preferredContactChannel': 'WHATSAPP',
        'codEnabled': true,
        'codRefusalCount': 0,
        'riskLevel': 'GREEN',
        'riskReason': null,
        'riskUpdatedAt': now.toIso8601String(),
        'rfmSegment': 'NEW',
        'rfmUpdatedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'stats': {
          'totalOrders': 1,
          'totalSpent': 0,
          'avgOrderValue': 0,
          'daysSinceLastOrder': 0,
          'hasHighReturnRate': false,
          'codAccepted': 0,
          'codTotal': 0,
        },
        'lastProducts': <Map<String, dynamic>>[],
        'totalOrders': 1,
        'totalSpent': 0,
        'lastOrderDate': now.toIso8601String(),
        'hasHighReturnRate': false,
      };
    }
    var gross = 0;
    var cost = 0;
    final orderItems = <Map<String, dynamic>>[];
    for (final input in items) {
      final product = store.products[input.productId];
      final unitCost =
          product?['baseCostPrice'] as int? ?? input.unitPrice ~/ 2;
      gross += input.unitPrice * input.quantity;
      cost += unitCost * input.quantity;
      orderItems.add({
        'id': 'item_${store.nextId()}',
        'productName': input.productName,
        'quantity': input.quantity,
        'unitPrice': input.unitPrice,
        'unitCost': unitCost,
        'subtotal': input.unitPrice * input.quantity,
        'returnedQuantity': 0,
        'isBackorder': false,
        'fulfillmentStatus': 'PENDING',
        'estimatedRestockDate': null,
        'variantId': input.variantId,
        'variantAttributes': <String, dynamic>{},
        'primaryImageUrl':
            product == null || (product['images'] as List).isEmpty
            ? null
            : ((product['images'] as List).first
                  as Map<String, dynamic>)['url'],
      });
    }
    final net = gross - discountAmount;
    final profit = net - cost - shippingCost - adSpend;
    final seq = store.nextId();
    final id = 'ord_$seq';
    final customerMap = store.customers[customerId]!;
    final json = <String, dynamic>{
      'id': id,
      'orderNumber': '#$seq',
      'status': 'PENDING',
      'customer': {
        'id': customerId,
        'name': customerMap['name'],
        'phone': customerMap['phone'],
        'address': customerMap['address'],
        'city': customerMap['city'],
        'governorate': customerMap['governorate'],
      },
      'items': orderItems,
      'grossRevenue': gross,
      'discountAmount': discountAmount,
      'netRevenue': net,
      'totalCost': cost,
      'shippingCost': shippingCost,
      'adSpend': adSpend,
      'orderProfit': profit,
      'realProfit': profit,
      'profitBreakdown': {
        'salePrice': gross,
        'productCost': cost,
        'shippingCost': shippingCost,
        'discountApplied': discountAmount,
        'exchangeCost': 0,
        'netProfit': profit,
        'marginPercent': gross == 0 ? 0.0 : profit * 100 / gross,
      },
      'notes': notes,
      'adCampaignId': null,
      'rtoReason': null,
      'rtoReceivedAt': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    store.orders[id] = json;
    return _full(json);
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    await _wait();
    final order = store.orders[id];
    if (order == null) return;
    order['status'] = status;
    order['updatedAt'] = DateTime.now().toIso8601String();
  }

  @override
  Future<void> deleteOrder(String id) async {
    await _wait();
    store.orders.remove(id);
  }

  @override
  Future<List<Exchange>> listExchanges(String orderId) async {
    await _wait();
    return (store.exchanges[orderId] ?? const [])
        .map(Exchange.fromJson)
        .toList();
  }

  @override
  Future<CreateExchangeResult> createExchange({
    required String orderId,
    String? originalVariantId,
    required String newProductId,
    required String newVariantId,
    int? returnShippingCost,
    int? redeliveryCost,
    int? priceDifference,
    String? notes,
  }) async {
    await _wait();
    final product = store.products[newProductId]!;
    final json = <String, dynamic>{
      'id': 'exchange_${store.nextId()}',
      'orderId': orderId,
      'originalVariantId': originalVariantId,
      'newProductId': newProductId,
      'newVariantId': newVariantId,
      'newProductName': product['name'],
      'newVariantAttributes': <String, String>{},
      'newUnitPrice': product['baseSellPrice'],
      'returnShippingCost': returnShippingCost,
      'redeliveryCost': redeliveryCost,
      'priceDifference': priceDifference,
      'notes': notes,
      'createdAt': DateTime.now().toIso8601String(),
    };
    store.exchanges.putIfAbsent(orderId, () => []).add(json);
    await updateStatus(orderId, 'EXCHANGE_IN_PROGRESS');
    return CreateExchangeResult(
      exchange: Exchange.fromJson(json),
      stockWarning: false,
      orderStatus: 'EXCHANGE_IN_PROGRESS',
    );
  }

  @override
  Future<List<Issue>> listIssues(String orderId) async {
    await _wait();
    return (store.issues[orderId] ?? const []).map(Issue.fromJson).toList();
  }

  @override
  Future<CreateIssueResult> createIssue({
    required String orderId,
    required IssueType issueType,
    required IssueResolution resolution,
    String? notes,
  }) async {
    await _wait();
    final json = <String, dynamic>{
      'id': 'issue_${store.nextId()}',
      'orderId': orderId,
      'issueType': issueType.wire,
      'resolution': resolution.wire,
      'notes': notes,
      'createdAt': DateTime.now().toIso8601String(),
      'resolvedAt': DateTime.now().toIso8601String(),
    };
    store.issues.putIfAbsent(orderId, () => []).add(json);
    return CreateIssueResult(
      issue: Issue.fromJson(json),
      stockRestored: const [],
      orderStatus: store.orders[orderId]?['status'] as String? ?? 'DELIVERED',
    );
  }

  @override
  Future<MarkRtoResult> markRto({
    required String orderId,
    required RtoReason reason,
    required RtoTargetStatus status,
  }) async {
    await _wait();
    final order = store.orders[orderId]!;
    order['status'] = status.wire;
    order['rtoReason'] = reason.wire;
    if (status == RtoTargetStatus.received) {
      order['rtoReceivedAt'] = DateTime.now().toIso8601String();
    }
    return MarkRtoResult(
      orderId: orderId,
      orderStatus: status.wire,
      rtoReason: reason.wire,
      rtoReceivedAt: status == RtoTargetStatus.received ? DateTime.now() : null,
      stockRestored: const [],
      customer: null,
    );
  }

  BulkActionResult _bulk(List<String> ids, String status) {
    for (final id in ids) {
      final order = store.orders[id];
      if (order != null) order['status'] = status;
    }
    return BulkActionResult(
      updated: ids.length,
      results: ids.map((id) => BulkActionRow(orderId: id, ok: true)).toList(),
    );
  }

  @override
  Future<BulkActionResult> bulkUpdateStatus({
    required List<String> orderIds,
    required String newStatus,
  }) async {
    await _wait();
    return _bulk(orderIds, newStatus);
  }

  @override
  Future<BulkActionResult> bulkCancel({required List<String> orderIds}) async {
    await _wait();
    return _bulk(orderIds, 'CANCELLED');
  }

  @override
  Future<PartialFulfillResult> partialFulfill({
    required String orderId,
    required PartialFulfillAction action,
    DateTime? estimatedRestockDate,
  }) async {
    await _wait();
    final order = _full(store.orders[orderId]!);
    final shipped = order.items.isEmpty ? <OrderItem>[] : [order.items.first];
    final backordered = order.items.skip(1).toList();
    final nextStatus = action == PartialFulfillAction.shipNow
        ? 'PARTIALLY_SHIPPED'
        : order.status;
    if (action == PartialFulfillAction.shipNow) {
      store.orders[orderId]!['status'] = nextStatus;
    }
    return PartialFulfillResult(
      shippedItems: shipped,
      backorderedItems: backordered,
      order: PartialFulfillOrderRef(
        id: orderId,
        status: nextStatus,
        orderNumber: order.orderNumber,
      ),
      customer: PartialFulfillCustomer(
        id: order.customer.id,
        name: order.customer.name,
        phone: order.customer.phone,
        preferredContactChannel: 'WHATSAPP',
      ),
    );
  }
}

class DemoCustomerRepository extends CustomerRepository {
  DemoCustomerRepository(this.store);
  final DemoStore store;

  CustomerDetail _detail(Map<String, dynamic> json) =>
      CustomerDetail.fromJson(json);

  CustomerLean _lean(Map<String, dynamic> json) => CustomerLean.fromJson(json);

  @override
  Future<PaginatedResponse<CustomerLean>> getCustomers({
    String? cursor,
    int limit = 20,
  }) async {
    await _wait();
    final rows = store.customers.values.map(_lean).toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return PaginatedResponse(
      data: rows.take(limit).toList(),
      hasMore: rows.length > limit,
      total: rows.length,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    await _wait();
    final q = query.toLowerCase();
    return store.customers.values
        .where(
          (c) =>
              (c['name'] as String).toLowerCase().contains(q) ||
              (c['phone'] as String).contains(query),
        )
        .map((c) => {'id': c['id'], 'name': c['name'], 'phone': c['phone']})
        .toList();
  }

  @override
  Future<CustomerDetail> getCustomer(String id) async {
    await _wait();
    final json = store.customers[id];
    if (json == null) throw StateError('Cliente introuvable');
    return _detail(json);
  }

  @override
  Future<CustomerDetail> updateCustomer(
    String id,
    CustomerUpdateInput input,
  ) async {
    await _wait();
    final row = store.customers[id]!;
    row.addAll(input.toJson());
    return _detail(row);
  }

  @override
  Future<CustomerDetail> updateToggles(
    String id, {
    bool? isBlocked,
    String? blockReason,
    bool? requirePrepayment,
    bool? codEnabled,
  }) async {
    await _wait();
    final row = store.customers[id]!;
    if (isBlocked != null) {
      row['isBlocked'] = isBlocked;
      row['blockedAt'] = isBlocked ? DateTime.now().toIso8601String() : null;
      if (!isBlocked) row['blockReason'] = null;
    }
    if (blockReason != null) row['blockReason'] = blockReason;
    if (requirePrepayment != null) row['requirePrepayment'] = requirePrepayment;
    if (codEnabled != null) row['codEnabled'] = codEnabled;
    return _detail(row);
  }

  @override
  Future<CustomerDetail> updateProfile(
    String id, {
    DateTime? birthday,
    bool clearBirthday = false,
    ContactChannel? preferredContactChannel,
    List<String>? tags,
  }) async {
    await _wait();
    final row = store.customers[id]!;
    if (clearBirthday) row['birthday'] = null;
    if (birthday != null) row['birthday'] = birthday.toIso8601String();
    if (preferredContactChannel != null) {
      row['preferredContactChannel'] = preferredContactChannel.wire;
    }
    if (tags != null) row['tags'] = tags;
    return _detail(row);
  }

  @override
  Future<CustomerDetail> updateRisk(
    String id, {
    required RiskLevel riskLevel,
    String? riskReason,
    bool clearReason = false,
  }) async {
    await _wait();
    final row = store.customers[id]!;
    row['riskLevel'] = riskLevel.wire;
    row['riskReason'] = clearReason ? null : riskReason ?? row['riskReason'];
    row['riskUpdatedAt'] = DateTime.now().toIso8601String();
    return _detail(row);
  }

  @override
  Future<List<CustomerNote>> listNotes(String customerId) async {
    await _wait();
    return (store.notes[customerId] ?? const [])
        .map(CustomerNote.fromJson)
        .toList();
  }

  @override
  Future<CustomerNote> createNote({
    required String customerId,
    required String content,
    bool isPinned = false,
  }) async {
    await _wait();
    final now = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': 'note_${store.nextId()}',
      'customerId': customerId,
      'content': content,
      'isPinned': isPinned,
      'createdAt': now,
      'updatedAt': now,
    };
    store.notes.putIfAbsent(customerId, () => []).add(row);
    return CustomerNote.fromJson(row);
  }

  @override
  Future<CustomerNote> updateNote({
    required String customerId,
    required String noteId,
    String? content,
    bool? isPinned,
  }) async {
    await _wait();
    final row = store.notes[customerId]!.firstWhere((n) => n['id'] == noteId);
    if (content != null) row['content'] = content;
    if (isPinned != null) row['isPinned'] = isPinned;
    row['updatedAt'] = DateTime.now().toIso8601String();
    return CustomerNote.fromJson(row);
  }

  @override
  Future<void> deleteNote({
    required String customerId,
    required String noteId,
  }) async {
    await _wait();
    store.notes[customerId]?.removeWhere((n) => n['id'] == noteId);
  }

  @override
  Future<List<CustomerAddress>> listAddresses(String customerId) async {
    await _wait();
    return (store.addresses[customerId] ?? const [])
        .map(CustomerAddress.fromJson)
        .toList();
  }

  @override
  Future<CustomerAddress> createAddress({
    required String customerId,
    required String addressLine,
    required String city,
    required String governorate,
    String? label,
    String? deliveryNotes,
    bool isDefault = false,
  }) async {
    await _wait();
    final now = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': 'addr_${store.nextId()}',
      'customerId': customerId,
      'label': label,
      'addressLine': addressLine,
      'city': city,
      'governorate': governorate,
      'deliveryNotes': deliveryNotes,
      'isDefault': isDefault,
      'createdAt': now,
      'updatedAt': now,
    };
    if (isDefault) {
      for (final old in store.addresses[customerId] ?? const []) {
        old['isDefault'] = false;
      }
    }
    store.addresses.putIfAbsent(customerId, () => []).add(row);
    return CustomerAddress.fromJson(row);
  }

  @override
  Future<CustomerAddress> updateAddress({
    required String customerId,
    required String addressId,
    String? label,
    bool clearLabel = false,
    String? addressLine,
    String? city,
    String? governorate,
    String? deliveryNotes,
    bool clearDeliveryNotes = false,
  }) async {
    await _wait();
    final row = store.addresses[customerId]!.firstWhere(
      (a) => a['id'] == addressId,
    );
    if (clearLabel) row['label'] = null;
    if (label != null) row['label'] = label;
    if (addressLine != null) row['addressLine'] = addressLine;
    if (city != null) row['city'] = city;
    if (governorate != null) row['governorate'] = governorate;
    if (clearDeliveryNotes) row['deliveryNotes'] = null;
    if (deliveryNotes != null) row['deliveryNotes'] = deliveryNotes;
    row['updatedAt'] = DateTime.now().toIso8601String();
    return CustomerAddress.fromJson(row);
  }

  @override
  Future<void> deleteAddress({
    required String customerId,
    required String addressId,
  }) async {
    await _wait();
    store.addresses[customerId]?.removeWhere((a) => a['id'] == addressId);
  }

  @override
  Future<CustomerAddress> setDefaultAddress({
    required String customerId,
    required String addressId,
  }) async {
    await _wait();
    final rows = store.addresses[customerId]!;
    for (final row in rows) {
      row['isDefault'] = row['id'] == addressId;
    }
    return CustomerAddress.fromJson(
      rows.firstWhere((a) => a['id'] == addressId),
    );
  }
}

class DemoBoutiqueRepository extends BoutiqueRepository {
  DemoBoutiqueRepository(this.store);
  final DemoStore store;

  @override
  Future<Boutique> getCurrent() async {
    await _wait();
    return Boutique.fromJson(store.boutique);
  }

  @override
  Future<List<Boutique>> list() async => [await getCurrent()];

  @override
  Future<Boutique> update(BoutiquePatchInput patch) async {
    await _wait();
    store.boutique.addAll(patch.toJsonNonNull());
    store.boutique['updatedAt'] = DateTime.now().toIso8601String();
    return Boutique.fromJson(store.boutique);
  }

  @override
  Future<String> uploadLogo(XFile file) async {
    await _wait();
    const url = 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=';
    store.boutique['logoUrl'] = url;
    return url;
  }
}

class DemoGoalRepository extends GoalRepository {
  DemoGoalRepository(this.store);
  final DemoStore store;

  @override
  Future<GoalWithProgress?> getActiveGoal() async {
    await _wait();
    final row = store.activeGoal;
    return row == null ? null : GoalWithProgress.fromJson(row);
  }

  @override
  Future<void> createGoal(CreateGoalInput input) async {
    await _wait();
    final now = DateTime.now();
    store.activeGoal = {
      'id': 'goal_${store.nextId()}',
      'kind': input.kind,
      'goalType': input.goalType,
      'label': input.label ?? 'Mon objectif',
      'targetValue': input.targetValue,
      'currentValue': 0,
      'progressPercent': 0.0,
      'daysRemaining': 30,
      'dailyPaceRequired': input.targetValue == null
          ? null
          : input.targetValue! ~/ 30,
      'status': 'ACTIVE',
      'periodStart': now.toIso8601String(),
      'periodEnd': now.add(const Duration(days: 30)).toIso8601String(),
    };
  }
}

class DemoDashboardRepository extends DashboardRepository {
  DemoDashboardRepository(this.store);
  final DemoStore store;

  @override
  Future<DashboardData> getDashboard() async {
    await _wait();
    final today = DateTime.now();
    final todayOrders = store.orders.values.where((row) {
      final date = DateTime.parse(row['createdAt'] as String);
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).toList();
    final revenue = todayOrders.fold<int>(
      0,
      (sum, row) => sum + row['netRevenue'] as int,
    );
    final profit = todayOrders.fold<int>(
      0,
      (sum, row) => sum + row['realProfit'] as int,
    );
    final low = store.products.values.where((row) {
      final variant = (row['variants'] as List).first as Map<String, dynamic>;
      return (variant['availableQuantity'] as int) <=
          (variant['lowStockThreshold'] as int);
    }).toList();
    return DashboardData(
      today: DashboardToday(
        grossRevenue: revenue,
        realProfit: profit,
        orderCount: todayOrders.length,
        profitMarginPct: revenue == 0 ? 0 : profit * 100 / revenue,
      ),
      alerts: DashboardAlerts(
        lowStockProducts: low.map((row) {
          final variant =
              (row['variants'] as List).first as Map<String, dynamic>;
          return LowStockProduct(
            productId: row['id'] as String,
            productName: row['name'] as String,
            variantId: variant['id'] as String,
            variantSku: variant['sku'] as String,
            stockQuantity: variant['availableQuantity'] as int,
            threshold: variant['lowStockThreshold'] as int,
          );
        }).toList(),
        lowStockCount: low.length,
      ),
      insights: const [
        'Les accessoires génèrent votre meilleure marge cette semaine.',
        '2 produits nécessitent un réapprovisionnement rapide.',
        'Votre panier moyen progresse par rapport à la semaine dernière.',
      ],
    );
  }
}

class DemoProfitRepository extends ProfitRepository {
  DemoProfitRepository(this.store);
  final DemoStore store;

  Iterable<Map<String, dynamic>> get _activeOrders =>
      store.orders.values.where((row) => row['status'] != 'CANCELLED');

  @override
  Future<ProfitSummary> getSummary({String period = 'month'}) async {
    await _wait();
    final rows = _activeOrders.toList();
    final gross = rows.fold<int>(
      0,
      (sum, row) => sum + row['grossRevenue'] as int,
    );
    final discount = rows.fold<int>(
      0,
      (sum, row) => sum + row['discountAmount'] as int,
    );
    final costs = rows.fold<int>(
      0,
      (sum, row) => sum + row['totalCost'] as int,
    );
    final shipping = rows.fold<int>(
      0,
      (sum, row) => sum + row['shippingCost'] as int,
    );
    final ads = rows.fold<int>(0, (sum, row) => sum + row['adSpend'] as int);
    final profit = rows.fold<int>(
      0,
      (sum, row) => sum + row['realProfit'] as int,
    );
    return ProfitSummary(
      grossRevenue: gross,
      totalDiscount: discount,
      netRevenue: gross - discount,
      productCost: costs,
      shippingCost: shipping,
      adSpend: ads,
      totalRefunds: 0,
      realProfit: profit,
      profitMarginPct: gross == 0 ? 0 : profit * 100 / gross,
      orderCount: rows.length,
      returnCount: rows
          .where((r) => (r['status'] as String).startsWith('RTO'))
          .length,
      periodLabel: period == 'week' ? 'Cette semaine' : 'Ce mois',
      insights: const [
        'La marge réelle est en hausse de 12%.',
        'Le Sac cuir noir reste votre produit le plus rentable.',
      ],
      prevNetRevenue: (gross * .84).round(),
      prevRealProfit: (profit * .82).round(),
      prevOrderCount: rows.length - 1,
      revenueChangePercent: 16,
      profitChangePercent: 18,
    );
  }

  @override
  Future<List<ProductProfit>> getByProduct({String period = 'month'}) async {
    await _wait();
    return store.products.values.take(5).map((row) {
      final sold = 3 + (row['name'] as String).length % 8;
      final revenue = (row['baseSellPrice'] as int) * sold;
      final cost = (row['baseCostPrice'] as int) * sold;
      final profit = revenue - cost;
      return ProductProfit(
        productId: row['id'] as String,
        productName: row['name'] as String,
        unitsSold: sold,
        unitsReturned: 0,
        grossRevenue: revenue,
        productCost: cost,
        profit: profit,
        profitMarginPct: profit * 100 / revenue,
      );
    }).toList();
  }

  @override
  Future<ProfitTrend> getTrend({String period = 'month'}) async {
    await _wait();
    final now = DateTime.now();
    final points = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final revenue = 340000 + index * 72000 + (index.isEven ? 85000 : 0);
      return TrendDataPoint(
        label: '${day.day}/${day.month}',
        date: day.toIso8601String(),
        grossRevenue: revenue,
        realProfit: (revenue * .42).round(),
        orderCount: 3 + index,
      );
    });
    return ProfitTrend(
      periodLabel: period == 'week' ? 'Cette semaine' : 'Ce mois',
      granularity: 'day',
      dataPoints: points,
    );
  }
}
