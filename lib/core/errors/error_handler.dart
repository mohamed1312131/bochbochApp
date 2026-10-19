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
        Map<String, List<String>> validationErrors = const {};

        if (data is Map<String, dynamic>) {
          final apiError = ApiError.fromJson(data);
          message = apiError.message;
          code = apiError.code;
          metadata = apiError.metadata;
          if (apiError.errors != null) {
            validationErrors = apiError.errors!;
          }
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

        // Standard HTTP status mapping for non-AI endpoints. The
        // backend `code` field (e.g. `INVALID_CREDENTIALS`,
        // `ACCOUNT_LOCKED`) is now passed through so callers can
        // branch on stable identifiers (H2 fix). Field-level errors
        // from 422 responses are forwarded via ValidationException.errors
        // (H3 fix — previously dropped to const {}).
        if (statusCode == 401) return UnauthorizedException(message, code);
        if (statusCode == 404) return NotFoundException(message, code);
        if (statusCode == 422) {
          return ValidationException(
            message: message,
            errors: validationErrors,
            code: code,
          );
        }
        return ServerException(
          statusCode: statusCode,
          message: message,
          code: code,
        );

      default:
        return const UnknownException();
    }
  }
}
