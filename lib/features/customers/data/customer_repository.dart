import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../../../shared/models/paginated_response.dart';
import '../domain/customer_models.dart';

class CustomerRepository {
  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  Future<PaginatedResponse<CustomerLean>> getCustomers({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        ApiEndpoints.customers,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CustomerLean.fromJson(json),
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<CustomerDetail> getCustomer(String id) async {
    try {
      final dio = await _getDio();
      final response =
          await dio.get('${ApiEndpoints.customers}/$id');
      return CustomerDetail.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}