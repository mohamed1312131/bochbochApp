import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/models/paginated_response.dart';
import '../domain/bulk_action_models.dart';
import '../domain/exchange_models.dart';
import '../domain/issue_models.dart';
import '../domain/order_models.dart';
import '../domain/partial_fulfill_models.dart';
import '../domain/rto_models.dart';

class OrderRepository {
  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  // ── List ───────────────────────────────────────────────
  Future<PaginatedResponse<OrderLean>> getOrders({
    String? cursor,
    int limit = 20,
    String? status,
    String? from,
    String? to,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
          if (status != null) 'status': status,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
        },
      );
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => OrderLean.fromJson(json),
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Detail ─────────────────────────────────────────────
  Future<Order> getOrder(String id) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(ApiEndpoints.order(id));
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Create ─────────────────────────────────────────────
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
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.orders,
        data: {
          'customer': {
            'name': customerName,
            'phone': customerPhone,
            if (customerAddress != null) 'address': customerAddress,
            if (customerCity != null) 'city': customerCity,
            if (customerGovernorate != null)
              'governorate': customerGovernorate,
          },
          'items': items.map((i) => i.toJson()).toList(),
          'shippingCost': shippingCost,
          'discountAmount': discountAmount,
          'adSpend': adSpend,
          if (notes != null) 'notes': notes,
        },
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Update Status ──────────────────────────────────────
  Future<void> updateStatus(String id, String status) async {
    try {
      final dio = await _getDio();
      await dio.patch(
        ApiEndpoints.orderStatus(id),
        data: {'status': status},
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Delete ─────────────────────────────────────────────
  Future<void> deleteOrder(String id) async {
    try {
      final dio = await _getDio();
      await dio.delete(ApiEndpoints.order(id));
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Exchanges ──────────────────────────────────────────
  Future<List<Exchange>> listExchanges(String orderId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(ApiEndpoints.orderExchanges(orderId));
      final body = response.data as Map<String, dynamic>;
      final raw = body['exchanges'] as List<dynamic>? ?? const [];
      return raw
          .map((e) => Exchange.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Issues (Lost / Damaged) ────────────────────────────
  Future<List<Issue>> listIssues(String orderId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(ApiEndpoints.orderIssues(orderId));
      final body = response.data as Map<String, dynamic>;
      final raw = body['issues'] as List<dynamic>? ?? const [];
      return raw
          .map((e) => Issue.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CreateIssueResult> createIssue({
    required String orderId,
    required IssueType issueType,
    required IssueResolution resolution,
    String? notes,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.orderIssues(orderId),
        data: {
          'issueType': issueType.wire,
          'resolution': resolution.wire,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return CreateIssueResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── RTO ────────────────────────────────────────────────
  Future<MarkRtoResult> markRto({
    required String orderId,
    required RtoReason reason,
    required RtoTargetStatus status,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.orderRto(orderId),
        data: {
          'reason': reason.wire,
          'status': status.wire,
        },
      );
      return MarkRtoResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Bulk Actions (Feature 13) ──────────────────────────
  Future<BulkActionResult> bulkUpdateStatus({
    required List<String> orderIds,
    required String newStatus,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.ordersBulkStatus,
        data: {
          'orderIds': orderIds,
          'newStatus': newStatus,
        },
      );
      return BulkActionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<BulkActionResult> bulkCancel({
    required List<String> orderIds,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.ordersBulkCancel,
        data: {'orderIds': orderIds},
      );
      return BulkActionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Partial Fulfillment ────────────────────────────────
  Future<PartialFulfillResult> partialFulfill({
    required String orderId,
    required PartialFulfillAction action,
    DateTime? estimatedRestockDate,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.orderPartialFulfill(orderId),
        data: {
          'action': action.wire,
          if (estimatedRestockDate != null)
            'estimatedRestockDate':
                _formatIsoDate(estimatedRestockDate),
        },
      );
      return PartialFulfillResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  String _formatIsoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

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
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.orderExchanges(orderId),
        data: {
          if (originalVariantId != null) 'originalVariantId': originalVariantId,
          'newProductId': newProductId,
          'newVariantId': newVariantId,
          if (returnShippingCost != null)
            'returnShippingCost': returnShippingCost,
          if (redeliveryCost != null) 'redeliveryCost': redeliveryCost,
          if (priceDifference != null) 'priceDifference': priceDifference,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return CreateExchangeResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}