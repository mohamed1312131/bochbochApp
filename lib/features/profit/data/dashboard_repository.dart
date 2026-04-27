import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  Future<DashboardData> getDashboard() async {
    try {
      final dio = (await DioClient.getInstance()).dio;
      final response = await dio.get(ApiEndpoints.dashboard);
      return DashboardData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
