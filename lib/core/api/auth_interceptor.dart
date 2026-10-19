import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'api_endpoints.dart';
import 'auth_events.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;

  /// Completer pattern (H1 fix). When a 401 fires, the FIRST request
  /// installs a Completer here and runs the refresh. Subsequent 401s
  /// observe the in-flight Completer, await its result, then retry
  /// with the freshly-rotated access token. Previous boolean-flag
  /// implementation skipped the entire branch on concurrent 401s and
  /// propagated the original 401 — users saw spurious failures while a
  /// refresh was in flight.
  Completer<String?>? _refreshCompleter;

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

    if (err.response?.statusCode != 401 || isAuthRoute) {
      return handler.next(err);
    }

    String? newAccessToken;

    if (_refreshCompleter != null) {
      // A refresh is already in flight — wait for it instead of starting
      // a parallel one.
      try {
        newAccessToken = await _refreshCompleter!.future;
      } catch (_) {
        // The in-flight refresh failed; this request fails too.
        return handler.next(err);
      }
    } else {
      _refreshCompleter = Completer<String?>();
      try {
        newAccessToken = await _doRefresh();
        _refreshCompleter!.complete(newAccessToken);
      } catch (e, stackTrace) {
        // Skip Sentry for the expected case (refresh token expired).
        final isExpectedExpiry = e is DioException &&
            e.response?.statusCode == 401 &&
            e.requestOptions.path.contains(ApiEndpoints.refresh);
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
        // Notify AuthStateNotifier so the router boots the user out
        // immediately rather than waiting for the next manual auth check
        // (H21 fix).
        AuthEvents.emitTerminalLogout();
        _refreshCompleter!.completeError(e);
        return handler.next(err);
      } finally {
        _refreshCompleter = null;
      }
    }

    if (newAccessToken == null) {
      return handler.next(err);
    }

    // Retry the original request with the rotated access token.
    final opts = err.requestOptions;
    opts.headers['Authorization'] = 'Bearer $newAccessToken';
    try {
      final retryResponse = await _dio.fetch(opts);
      return handler.resolve(retryResponse);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      await _clearTokens();
      AuthEvents.emitTerminalLogout();
      return null;
    }

    final refreshResponse = await _dio.post(
      ApiEndpoints.refresh,
      data: {'refreshToken': refreshToken},
    );

    final newAccessToken = refreshResponse.data['accessToken'] as String;
    final newRefreshToken =
        refreshResponse.data['refreshToken'] as String?;

    await _storage.write(key: _accessTokenKey, value: newAccessToken);
    if (newRefreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
    }
    return newAccessToken;
  }

  Future<void> _clearTokens() async {
    // Keep this list in sync with AuthRepository.logout() and
    // AuthStateNotifier._allAuthKeys (no shared constant — see comment
    // in auth_state_provider.dart).
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: 'current_user_id'),
      _storage.delete(key: 'user_full_name'),
      _storage.delete(key: 'user_email'),
      _storage.delete(key: 'user_subscription_tier'),
      _storage.delete(key: 'onboarding_user_id'),
    ]);
  }
}
