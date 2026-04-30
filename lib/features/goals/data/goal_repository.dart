import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../domain/goal_models.dart';
import '../domain/goal_progress_models.dart';

class GoalRepository {
  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  /// POST /goals
  Future<void> createGoal(CreateGoalInput input) async {
    try {
      final dio = await _getDio();
      await dio.post('/goals', data: input.toJsonNonNull());
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// GET /goals — returns the user's active goal-with-progress, or null
  /// if none exists. 404 is treated as "no active goal".
  Future<GoalWithProgress?> getActiveGoal() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/goals');
      if (response.data == null) return null;
      return GoalWithProgress.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
