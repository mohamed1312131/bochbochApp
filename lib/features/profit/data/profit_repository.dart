import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../domain/profit_models.dart';

class ProfitRepository {
  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  Future<ProfitSummary> getSummary({String period = 'month'}) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        '/profit/summary',
        queryParameters: {'period': period},
      );
      return ProfitSummary.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<ProductProfit>> getByProduct(
      {String period = 'month'}) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        '/profit/by-product',
        queryParameters: {'period': period},
      );
      final data = response.data as Map<String, dynamic>;
      return (data['products'] as List)
          .map((e) =>
              ProductProfit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<ProfitTrend> getTrend({String period = 'month'}) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        '/profit/trend',
        queryParameters: {'period': period},
      );
      return ProfitTrend.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
