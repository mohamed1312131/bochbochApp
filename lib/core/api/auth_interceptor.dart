import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthRoute = options.path.contains('/auth/');
    if (!isAuthRoute) {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthRoute = err.requestOptions.path.contains('/auth/');

    if (err.response?.statusCode == 401 &&
        !isAuthRoute &&
        !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.read(key: _refreshTokenKey);
        if (refreshToken == null) {
          _isRefreshing = false;
          await _clearTokens();
          return handler.next(err);
        }

        // Send refresh token in body (mobile pattern)
        final refreshResponse = await _dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken =
            refreshResponse.data['accessToken'] as String;
        final newRefreshToken =
            refreshResponse.data['refreshToken'] as String?;

        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        if (newRefreshToken != null) {
          await _storage.write(
              key: _refreshTokenKey, value: newRefreshToken);
        }

        // Retry original request
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(opts);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (e, stackTrace) {
        _isRefreshing = false;
        // Skip the expected case: server told us the refresh token is gone
        // (401 from /auth/refresh). That's just an expired session, not a
        // bug. Anything else is interesting — network failure, 5xx, etc.
        final isExpectedExpiry = e is DioException &&
            e.response?.statusCode == 401 &&
            (e.requestOptions.path.contains(ApiEndpoints.refresh));
        if (!isExpectedExpiry) {
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
            withScope: (scope) {
              scope.setTag('subsystem', 'auth-refresh');
            },
          );
        }
        await _clearTokens();
        return handler.next(err);
      }
    }
    handler.next(err);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}