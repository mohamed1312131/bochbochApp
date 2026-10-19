import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/feature_flags.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

class DioClient {
  static DioClient? _instance;
  // Memoize the in-flight init Future (H13 fix). Two parallel
  // `getInstance()` callers used to both observe `_instance == null`,
  // both construct a `DioClient._()`, both run `_init` — leaving one
  // orphaned Dio with stale interceptors. Memoizing the Future itself
  // gives all callers the SAME init result.
  static Future<DioClient>? _initFuture;

  late final Dio _dio;
  late final PersistCookieJar _cookieJar;

  DioClient._();

  static Future<DioClient> getInstance() {
    if (_instance != null) return Future.value(_instance!);
    return _initFuture ??= _createAndInit();
  }

  static Future<DioClient> _createAndInit() async {
    final client = DioClient._();
    await client._init();
    _instance = client;
    return client;
  }

  Future<void> _init() async {
    // Persist cookies across sessions (refresh token cookie)
    final appDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${appDir.path}/.cookies/'),
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    _dio.interceptors.addAll([
      CookieManager(_cookieJar),
      AuthInterceptor(storage, _dio),
    ]);

    // Sentry interceptor goes LAST so it sees the final outbound request
    // (auth header attached) and the final inbound response. We only
    // capture 5xx — 4xx are user-facing errors handled by the app.
    if (FeatureFlags.sentryEnabled && FeatureFlags.sentryDsn.isNotEmpty) {
      // Tracing is gated off globally via tracesSampleRate=0 in the
      // bootstrap, so addSentry only needs the failure-capture config.
      _dio.addSentry(
        captureFailedRequests: true,
        failedRequestStatusCodes: [SentryStatusCode.range(500, 599)],
      );
    }
  }

  Dio get dio => _dio;
  PersistCookieJar get cookieJar => _cookieJar;

  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }
}