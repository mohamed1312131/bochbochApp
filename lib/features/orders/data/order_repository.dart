import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/models/paginated_response.dart';
import '../domain/order_models.dart';

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
}