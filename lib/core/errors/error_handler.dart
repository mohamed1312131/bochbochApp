import 'package:dio/dio.dart';
import 'app_exception.dart';
import '../../shared/models/api_error.dart';

abstract final class ErrorHandler {
  static AppException handle(Object error) {
    if (error is DioException) return _handleDio(error);
    if (error is AppException) return error;
    return const UnknownException();
  }

  static AppException _handleDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final data = e.response?.data;

        String message = 'Something went wrong';
        String? code;
        Map<String, dynamic>? metadata;

        if (data is Map<String, dynamic>) {
          final apiError = ApiError.fromJson(data);
          message = apiError.message;
          code = apiError.code;
          metadata = apiError.metadata;
        }

        // AI endpoints return structured codes — preserve them.
        final isAiEndpoint = e.requestOptions.path.contains('/ai/');
        if (isAiEndpoint && code != null) {
          return AiException.fromApiError(
            code: code,
            message: message,
            metadata: metadata,
          );
        }

        // Standard HTTP status mapping for non-AI endpoints.
        if (statusCode == 401) return UnauthorizedException(message);
        if (statusCode == 404) return NotFoundException(message);
        if (statusCode == 422) {
          return ValidationException(message: message, errors: const {});
        }
        return ServerException(statusCode: statusCode, message: message);

      default:
        return const UnknownException();
    }
  }
}
