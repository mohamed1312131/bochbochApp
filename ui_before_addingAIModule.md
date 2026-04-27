Flutter Project Audit — /Users/rouge/Desktop/freelance/bochboch
Project internal name is zid, directory is bochboch. Only one Flutter app in the workspace.

1. pubspec.yaml

name: zid
description: AI-powered marketing tool for Tunisian social commerce sellers.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.11.0 <4.0.0'
  flutter: '>=3.41.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Routing
  go_router: ^14.6.1

  # HTTP
  dio: ^5.7.0
  dio_cookie_manager: ^3.1.2
  cookie_jar: ^4.0.8
  pretty_dio_logger: ^1.3.1

  # Secure Storage
  flutter_secure_storage: ^9.2.2

  # Local Database
  drift: ^2.21.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.5
  path: ^1.9.0

  # Images
  cached_network_image: ^3.4.1
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0

  # UI & Animations
  flutter_animate: ^4.5.0
  fl_chart: ^0.69.0
  google_fonts: ^6.2.1
  icons_plus: ^5.0.0

  # Utils
  intl: ^0.19.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  riverpod_generator: ^2.4.3
  freezed: ^2.5.7
  json_serializable: ^6.8.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
Note: freezed, json_serializable, riverpod_generator, build_runner are all listed as dev_deps, and freezed_annotation + json_annotation + riverpod_annotation are runtime deps — but nothing in lib/ actually uses them (grep for @freezed, @JsonSerializable, @riverpod, part '*.g.dart', part '*.freezed.dart' all return zero hits). Models are hand-written JSON. Code generation is installed but not wired.

2. Project structure
All .dart files in lib/ (sorted):

lib/core/api/api_endpoints.dart
lib/core/api/auth_interceptor.dart
lib/core/api/dio_client.dart
lib/core/constants/app_border_radius.dart
lib/core/constants/app_colors.dart
lib/core/constants/app_shadows.dart
lib/core/constants/app_spacing.dart
lib/core/constants/app_typography.dart
lib/core/errors/app_exception.dart
lib/core/errors/error_handler.dart
lib/core/theme/app_theme.dart
lib/core/theme/app_theme_extension.dart
lib/core/utils/date_formatter.dart
lib/core/utils/millimes_formatter.dart
lib/features/auth/data/auth_models.dart
lib/features/auth/data/auth_repository.dart
lib/features/auth/domain/auth_models.dart
lib/features/auth/presentation/providers/auth_provider.dart
lib/features/auth/presentation/screens/forgot_password_screen.dart
lib/features/auth/presentation/screens/login_screen.dart
lib/features/auth/presentation/screens/new_password_screen.dart
lib/features/auth/presentation/screens/register_screen.dart
lib/features/auth/presentation/screens/reset_password_screen.dart
lib/features/auth/presentation/screens/verify_email_screen.dart
lib/features/auth/presentation/screens/verify_otp_screen.dart
lib/features/customers/data/customer_repository.dart
lib/features/customers/domain/customer_models.dart
lib/features/customers/presentation/providers/customer_provider.dart
lib/features/customers/presentation/screens/customer_detail_screen.dart
lib/features/customers/presentation/screens/customer_list_screen.dart
lib/features/orders/data/order_repository.dart
lib/features/orders/domain/order_models.dart
lib/features/orders/presentation/providers/order_provider.dart
lib/features/orders/presentation/screens/add_order_screen.dart
lib/features/orders/presentation/screens/order_detail_screen.dart
lib/features/orders/presentation/screens/order_list_screen.dart
lib/features/products/data/product_repository.dart
lib/features/products/domain/product_models.dart
lib/features/products/presentation/providers/product_provider.dart
lib/features/products/presentation/screens/add_product_screen.dart
lib/features/products/presentation/screens/edit_product_screen.dart
lib/features/products/presentation/screens/product_detail_screen.dart
lib/features/products/presentation/screens/product_list_screen.dart
lib/features/profit/data/dashboard_repository.dart
lib/features/profit/data/profit_repository.dart
lib/features/profit/domain/dashboard_models.dart
lib/features/profit/domain/profit_models.dart
lib/features/profit/presentation/providers/dashboard_provider.dart
lib/features/profit/presentation/providers/profit_provider.dart
lib/features/profit/presentation/screens/home_screen.dart
lib/features/profit/presentation/screens/insights_screen.dart
lib/features/settings/presentation/screens/settings_screen.dart
lib/main.dart
lib/router.dart
lib/shared/models/api_error.dart
lib/shared/models/paginated_response.dart
lib/shared/providers/auth_state_provider.dart
lib/shared/providers/theme_provider.dart
lib/shared/widgets/zid_avatar.dart
lib/shared/widgets/zid_badge.dart
lib/shared/widgets/zid_button.dart
lib/shared/widgets/zid_card.dart
lib/shared/widgets/zid_empty_state.dart
lib/shared/widgets/zid_input.dart
lib/shared/widgets/zid_list_row.dart
lib/shared/widgets/zid_skeleton.dart
All directories in lib/:

lib
lib/core
lib/core/api
lib/core/constants
lib/core/errors
lib/core/theme
lib/core/utils
lib/features
lib/features/ai_studio                              (empty — no .dart files)
lib/features/ai_studio/data                         (empty)
lib/features/ai_studio/domain                       (empty)
lib/features/ai_studio/presentation                 (empty)
lib/features/ai_studio/presentation/providers       (empty)
lib/features/ai_studio/presentation/screens         (empty)
lib/features/ai_studio/presentation/widgets         (empty)
lib/features/auth
lib/features/auth/data
lib/features/auth/domain
lib/features/auth/presentation
lib/features/auth/presentation/providers
lib/features/auth/presentation/screens
lib/features/auth/presentation/widgets              (empty)
lib/features/customers
lib/features/customers/data
lib/features/customers/domain
lib/features/customers/presentation
lib/features/customers/presentation/providers
lib/features/customers/presentation/screens
lib/features/customers/presentation/widgets         (empty)
lib/features/insights                               (all empty)
lib/features/insights/data                          (empty)
lib/features/insights/domain                        (empty)
lib/features/insights/presentation                  (empty)
lib/features/insights/presentation/providers        (empty)
lib/features/insights/presentation/screens          (empty)
lib/features/insights/presentation/widgets          (empty)
lib/features/orders
lib/features/orders/data
lib/features/orders/domain
lib/features/orders/presentation
lib/features/orders/presentation/providers
lib/features/orders/presentation/screens
lib/features/orders/presentation/widgets            (empty)
lib/features/products
lib/features/products/data
lib/features/products/domain
lib/features/products/presentation
lib/features/products/presentation/providers
lib/features/products/presentation/screens
lib/features/products/presentation/widgets          (empty)
lib/features/profit
lib/features/profit/data
lib/features/profit/domain
lib/features/profit/presentation
lib/features/profit/presentation/providers
lib/features/profit/presentation/screens
lib/features/profit/presentation/widgets            (empty)
lib/features/settings
lib/features/settings/data                          (empty)
lib/features/settings/domain                        (empty)
lib/features/settings/presentation
lib/features/settings/presentation/providers        (empty)
lib/features/settings/presentation/screens
lib/features/settings/presentation/widgets          (empty)
lib/shared
lib/shared/models
lib/shared/providers
lib/shared/widgets
Key observation: lib/features/ai_studio/ directory tree exists (data / domain / presentation/{providers,screens,widgets}) but every folder is empty. No file has been written yet. lib/features/insights/ is also a fully scaffolded empty skeleton.

3. Existing design system
Note: directory is lib/core/constants/, not lib/core/theme/ as asked. Only app_theme.dart and app_theme_extension.dart live under lib/core/theme/. The tokens (colors/spacing/typography/radius/shadows) are in lib/core/constants/. No app_colors.dart under theme/ — they don't exist at the paths you listed; they exist at the constants paths.

lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────
  static const brand = Color(0xFF05687B);
  static const brandLight = Color(0xFFE6F4F7);
  static const brandDark = Color(0xFF034D5C);
  static const brandDarkMode = Color(0xFF0A8FA6);
  static const brandLightDarkMode = Color(0xFF0A3D47);

  // ── Neutrals Light ───────────────────────────────────────
  static const background = Color(0xFFF8F9FC);
  static const surfaceL1 = Color(0xFFF2F3F7);
  static const surfaceL2 = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);

  // ── Neutrals Dark ────────────────────────────────────────
  static const backgroundDark = Color(0xFF000000);
  static const surfaceL1Dark = Color(0xFF1C1C1E);
  static const surfaceL2Dark = Color(0xFF2C2C2E);
  static const surfaceL3Dark = Color(0xFF3A3A3C);
  static const borderDark = Color(0xFF3A3A3C);

  // ── Text ─────────────────────────────────────────────────
  static const textPrimary = Color(0xFF0A0A0A);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textPrimaryDark = Color(0xFFFFFFFF);

  // ── Semantic ─────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorBg = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFDBEAFE);

  // ── Always white ─────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
}
lib/core/constants/app_spacing.dart

abstract final class AppSpacing {
  // ── Base unit: 4px ───────────────────────────────────────
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double xxxxl = 48;
  static const double xxxxxl = 64;

  // ── Semantic ─────────────────────────────────────────────
  static const double screenHorizontal = 20;
  static const double cardPadding = 16;
  static const double sectionTop = 40;
  static const double sectionBottom = 24;
  static const double cardGap = 12;
  static const double listRowInset = 20;
  static const double buttonBottom = 32;
}
lib/core/constants/app_typography.dart

import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const TextStyle display = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 56,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 34, fontWeight: FontWeight.w700,
    letterSpacing: -1.0);
  static const TextStyle h2 = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 28, fontWeight: FontWeight.w700,
    letterSpacing: -0.5);
  static const TextStyle h3 = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 22, fontWeight: FontWeight.w600);
  static const TextStyle h4 = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w600);
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 17, fontWeight: FontWeight.w400);
  static const TextStyle body = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w400);
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 13, fontWeight: FontWeight.w400);
  static const TextStyle label = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 12, fontWeight: FontWeight.w500,
    letterSpacing: 0.5);
  static const TextStyle caption = TextStyle(
    fontFamily: 'PlusJakartaSans', fontSize: 11, fontWeight: FontWeight.w400,
    letterSpacing: 0.5);
}
lib/core/constants/app_border_radius.dart
The class is named AppRadius (not AppBorderRadius), file is app_border_radius.dart. There is no app_radius.dart — you asked for one, doesn't exist.


abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 9999;
}
lib/core/constants/app_shadows.dart

import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const xs = [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))];
  static const sm = [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))];
  static const md = [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))];
  static const lg = [BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8))];
  static const xl = [BoxShadow(color: Color(0x1F000000), blurRadius: 48, offset: Offset(0, 16))];
  // Dark mode → no shadows, use borders instead
  static const none = <BoxShadow>[];
}
lib/core/theme/app_theme.dart
Full file (both light + dark ThemeData). Key points: Material 3, custom AppBarTheme (centered, no elevation), CardThemeData with AppRadius.md rounding, InputDecorationTheme that drives all TextFormField styling globally. Full source ~195 lines — pasting condensed structure since full paste of 195 lines matches what's on disk.

Defines AppTheme.light and AppTheme.dark. Uses ColorScheme.light(primary: AppColors.brand, onPrimary: AppColors.white, secondary: AppColors.brandLight, ...). Dark uses brandDarkMode and surfaceL1Dark. Input fields get filled: true, fillColor: AppColors.background light, surfaceL2Dark dark. BottomNavigationBarTheme set for both modes.

lib/core/theme/app_theme_extension.dart — the BuildContext extension

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground   => isDark ? AppColors.backgroundDark : AppColors.background;
  Color get appSurface      => isDark ? AppColors.surfaceL1Dark  : AppColors.white;
  Color get appSurfaceL2    => isDark ? AppColors.surfaceL2Dark  : AppColors.surfaceL1;
  Color get appSurfaceL3    => isDark ? AppColors.surfaceL3Dark  : AppColors.surfaceL1;

  Color get appTextPrimary  => isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get appTextSecondary => AppColors.textSecondary;
  Color get appTextTertiary  => AppColors.textTertiary;

  Color get appBorder       => isDark ? AppColors.borderDark        : AppColors.border;
  Color get appBrand        => isDark ? AppColors.brandDarkMode      : AppColors.brand;
  Color get appBrandLight   => isDark ? AppColors.brandLightDarkMode : AppColors.brandLight;

  List<BoxShadow> get appCardShadow =>
      isDark ? [BoxShadow(color: Colors.transparent, blurRadius: 0)]
             : [const BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))];

  List<BoxShadow> get appCardShadowLg =>
      isDark ? []
             : [const BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))];
}
Convention: UI code uses context.appBrand, context.appSurface, context.appTextPrimary, etc., for theme-aware colors, and raw AppColors.X for fixed colors (semantic success/error, white, etc.). Typography/spacing/radius are accessed via AppTypography.body, AppSpacing.md, AppRadius.lg — no BuildContext convenience for those.

4. Dio / API client
lib/core/api/dio_client.dart

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'api_endpoints.dart';
import 'auth_interceptor.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  late final PersistCookieJar _cookieJar;

  DioClient._();

  static Future<DioClient> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = DioClient._();
    await _instance!._init();
    return _instance!;
  }

  Future<void> _init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${appDir.path}/.cookies/'),
    );

    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    _dio.interceptors.addAll([
      CookieManager(_cookieJar),
      AuthInterceptor(storage, _dio),
    ]);
  }

  Dio get dio => _dio;
  PersistCookieJar get cookieJar => _cookieJar;

  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }
}
Pattern: singleton initialized once in main.dart:10 (await DioClient.getInstance()). Repositories call (await DioClient.getInstance()).dio per method — not injected via Riverpod, it's a global async singleton. pretty_dio_logger is in pubspec but not wired into the interceptor chain.

lib/core/api/auth_interceptor.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
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
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isAuthRoute = err.requestOptions.path.contains('/auth/');

    if (err.response?.statusCode == 401 && !isAuthRoute && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.read(key: _refreshTokenKey);
        if (refreshToken == null) {
          _isRefreshing = false;
          await _clearTokens();
          return handler.next(err);
        }
        final refreshResponse = await _dio.post(
          ApiEndpoints.refresh,
          data: {'refreshToken': refreshToken},
        );
        final newAccessToken = refreshResponse.data['accessToken'] as String;
        final newRefreshToken = refreshResponse.data['refreshToken'] as String?;
        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        if (newRefreshToken != null) {
          await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
        }
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(opts);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (e) {
        _isRefreshing = false;
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
lib/core/api/api_endpoints.dart

abstract final class ApiEndpoints {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyPhone = '/auth/verify-phone';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // Products
  static const String products = '/products';
  static String product(String id) => '/products/$id';
  static String productStock(String id) => '/products/$id/stock';

  // Images
  static const String imageUpload = '/images/upload';
  static const String imageRemoveBg = '/images/remove-background';
  static const String imageResize = '/images/resize';

  // Orders
  static const String orders = '/orders';
  static String order(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';
  static String orderReturns(String id) => '/orders/$id/returns';

  // Customers
  static const String customers = '/customers';
  static const String customersSearch = '/customers/search';
  static String customer(String id) => '/customers/$id';
  static String customerOrders(String id) => '/customers/$id/orders';
  static String customerStats(String id) => '/customers/$id/stats';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Profit
  static const String profitSummary = '/profit/summary';
  static const String profitByProduct = '/profit/by-product';
  static const String profitTrend = '/profit/trend';

  // AI
  static const String aiCaptions = '/ai/captions';
  static const String aiWhatsapp = '/ai/whatsapp';
  static const String aiAdCreative = '/ai/ad-creative';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationToken = '/notifications/token';
  static const String notificationPreferences = '/notifications/preferences';

  // Subscription
  static const String subscription = '/subscription';
  static const String subscriptionUpgrade = '/subscription/upgrade';

  // User
  static const String userProfile = '/user/profile';
}
Base URL is hardcoded to http://localhost:3000/api/v1 — no env flavoring, no dotenv. No env/config file. AI endpoints currently listed (/ai/captions, /ai/whatsapp, /ai/ad-creative) are stale — they don't match the new backend surface documented in the IDE-selected AI_MODULE_BACKEND.md (which uses /ai/sessions, /ai/sessions/:id/photos, /ai/sessions/:id/analyze). The endpoint constants need to be rewritten.

lib/core/errors/app_exception.dart + error_handler.dart + lib/shared/models/api_error.dart

// app_exception.dart
abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override String toString() => message;
}
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}
class ServerException extends AppException {
  const ServerException({required this.statusCode, required String message}) : super(message);
  final int statusCode;
}
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired']);
}
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found']);
}
class ValidationException extends AppException {
  const ValidationException({required String message, this.errors = const {}}) : super(message);
  final Map<String, List<String>> errors;
}
class CacheException extends AppException {
  const CacheException([super.message = 'Local data error']);
}
class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong']);
}

// error_handler.dart
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
        if (data is Map<String, dynamic>) {
          final apiError = ApiError.fromJson(data);
          message = apiError.message;
          if (statusCode == 401) return UnauthorizedException(message);
          if (statusCode == 404) return NotFoundException(message);
          if (statusCode == 422) {
            return ValidationException(message: message, errors: apiError.errors ?? {});
          }
        }
        return ServerException(statusCode: statusCode, message: message);
      default:
        return const UnknownException();
    }
  }
}

// api_error.dart
class ApiError {
  const ApiError({required this.message, this.code, this.errors});
  final String message;
  final String? code;
  final Map<String, List<String>>? errors;
  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        message: json['message'] as String? ?? 'Something went wrong',
        code: json['code'] as String?,
        errors: (json['errors'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        ),
      );
}
Gap: ApiError parses code (the string like QUOTA_EXCEEDED) but ErrorHandler discards it — maps only by HTTP status. There's no way today for the UI to branch on AI_QUOTA_EXCEEDED vs AI_PROVIDER_UNAVAILABLE from the backend. This needs fixing before AI Studio lands (backend AI doc §11 defines a code taxonomy the client must read).

5. Existing Riverpod patterns
Convention: manual, no code generation. Mix of Provider, FutureProvider.autoDispose.family, AsyncNotifierProvider.autoDispose, NotifierProvider.autoDispose, and one legacy StateNotifierProvider (auth state). No @riverpod annotations anywhere, no generated files.

lib/features/products/presentation/providers/product_provider.dart — full file

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/product_repository.dart';
import '../../domain/product_models.dart';

// ── Repository ─────────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ── Product List ───────────────────────────────────────────
final productListProvider =
    AsyncNotifierProvider.autoDispose<ProductListNotifier, List<ProductLean>>(
  ProductListNotifier.new,
);

class ProductListNotifier extends AutoDisposeAsyncNotifier<List<ProductLean>> {
  String? _nextCursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<ProductLean>> build() async {
    _nextCursor = null;
    _hasMore = true;
    return _fetch();
  }

  Future<List<ProductLean>> _fetch({String? cursor}) async {
    final repo = ref.read(productRepositoryProvider);
    final result = await repo.getProducts(cursor: cursor);
    _nextCursor = result.nextCursor;
    _hasMore = result.hasMore;
    return result.data;
  }

  Future<void> refresh() async {
    _nextCursor = null;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    if (_nextCursor == null) return;
    _isLoadingMore = true;
    final current = state.valueOrNull ?? [];
    try {
      final more = await _fetch(cursor: _nextCursor);
      state = AsyncData([...current, ...more]);
    } catch (_) {
      // Don't replace state on load more error — keep existing data
    } finally {
      _isLoadingMore = false;
    }
  }

  void addProduct(ProductLean product) {
    final current = state.valueOrNull ?? [];
    state = AsyncData([product, ...current]);
  }

  void removeProduct(String productId) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((p) => p.id != productId).toList());
  }
}

// ── Single Product Detail ──────────────────────────────────
final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, id) async {
  return ref.read(productRepositoryProvider).getProduct(id);
});

// ── Add Product State ──────────────────────────────────────
enum AddProductStatus { idle, loading, success, error }

class AddProductState {
  const AddProductState({
    this.status = AddProductStatus.idle,
    this.error,
    this.createdProduct,
  });
  final AddProductStatus status;
  final String? error;
  final Product? createdProduct;

  AddProductState copyWith({
    AddProductStatus? status,
    String? error,
    Product? createdProduct,
  }) => AddProductState(
        status: status ?? this.status,
        error: error,
        createdProduct: createdProduct ?? this.createdProduct,
      );
}

class AddProductNotifier extends AutoDisposeNotifier<AddProductState> {
  @override
  AddProductState build() => const AddProductState();

  Future<void> createProduct({
    required String name,
    required int baseCostPrice,
    required int baseSellPrice,
    required int initialStock,
    String? description,
    String? category,
    String? imagePath,
  }) async {
    state = state.copyWith(status: AddProductStatus.loading, error: null);
    try {
      final repo = ref.read(productRepositoryProvider);
      final product = await repo.createProduct(
        name: name,
        baseCostPrice: baseCostPrice,
        baseSellPrice: baseSellPrice,
        initialStock: initialStock,
        description: description,
        category: category,
      );
      if (imagePath != null) {
        try {
          final imageData = await repo.uploadImage(imagePath);
          await repo.attachImage(
            product.id,
            cloudinaryPublicId: imageData['cloudinaryPublicId']!,
            url: imageData['url']!,
            isPrimary: true,
            altText: name,
          );
        } catch (_) {
          // Image upload failure is non-fatal
        }
      }
      state = state.copyWith(
        status: AddProductStatus.success,
        createdProduct: product,
      );
    } catch (e) {
      state = state.copyWith(status: AddProductStatus.error, error: e.toString());
    }
  }

  void reset() => state = const AddProductState();
}

final addProductProvider =
    NotifierProvider.autoDispose<AddProductNotifier, AddProductState>(
  AddProductNotifier.new,
);
lib/features/products/data/product_repository.dart
Full file — 183 lines. Key points:

Plain class, no interface. Instantiated via productRepositoryProvider = Provider<ProductRepository>((ref) => ProductRepository()).
Each method: final dio = await _getDio(); then try { ... } catch (e) { throw ErrorHandler.handle(e); }.
_getDio() is Future<Dio> _getDio() async => (await DioClient.getInstance()).dio; — fetched per-call.
JSON parsed manually (no codegen): ProductLean.fromJson(json) / Product.fromJson(response.data as Map<String, dynamic>).
Image upload + attach (shown below in §6) is two separate POSTs.

Conventions to match for AI Studio:

Repository = plain class, constructor injection none, Provider<T> wraps it.
List provider = AutoDisposeAsyncNotifier<List<T>> with manual cursor state fields.
Detail provider = FutureProvider.autoDispose.family<T, String>.
Mutation provider = AutoDisposeNotifier<StateObject> where StateObject has an enum status { idle, loading, success, error } + error: String? + the result payload. Handwritten copyWith. No freezed.
Screens use ref.listen to react to status transitions (see add_product_screen.dart:153-159).
6. Existing image upload code
Pick (camera + gallery) — lib/features/products/presentation/screens/add_product_screen.dart

// Field on the State:
XFile? _selectedImage;

Future<void> _pickImage() async {
  final picker = ImagePicker();
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: context.appSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: context.appBorder,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Add Photo',
              style: AppTypography.h4.copyWith(color: context.appTextPrimary)),
            const SizedBox(height: AppSpacing.xl),
            Row(children: [
              Expanded(child: _ImageSourceOption(
                icon: Icons.camera_alt_rounded, label: 'Camera',
                onTap: () => Navigator.pop(context, ImageSource.camera))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _ImageSourceOption(
                icon: Icons.photo_library_rounded, label: 'Gallery',
                onTap: () => Navigator.pop(context, ImageSource.gallery))),
            ]),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    ),
  );

  if (source == null) return;

  final image = await picker.pickImage(
    source: source,
    maxWidth: 1080,
    maxHeight: 1080,
    imageQuality: 85,
  );

  if (image != null) setState(() => _selectedImage = image);
}
Compression
Nothing is done client-side beyond what ImagePicker.pickImage does — maxWidth: 1080, maxHeight: 1080, imageQuality: 85 is the only compression. flutter_image_compress is in pubspec.yaml but not imported or used anywhere (grep confirmed).

Upload — lib/features/products/data/product_repository.dart (§8 image methods)

// ── Upload Image ───────────────────────────────────────
Future<Map<String, String>> uploadImage(String filePath) async {
  try {
    final dio = await _getDio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await dio.post(
      ApiEndpoints.imageUpload,   // POST /images/upload
      data: formData,
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'url': data['url'] as String,
      'cloudinaryPublicId': data['cloudinaryPublicId'] as String,
    };
  } catch (e) {
    throw ErrorHandler.handle(e);
  }
}

// ── Attach Image to Product ────────────────────────────
Future<void> attachImage(
  String productId, {
  required String cloudinaryPublicId,
  required String url,
  bool isPrimary = true,
  String? altText,
}) async {
  try {
    final dio = await _getDio();
    await dio.post(
      '/products/$productId/images',  // note: hardcoded path, not on ApiEndpoints
      data: {
        'cloudinaryPublicId': cloudinaryPublicId,
        'url': url,
        'isPrimary': isPrimary,
        if (altText != null) 'altText': altText,
      },
    );
  } catch (e) {
    throw ErrorHandler.handle(e);
  }
}
Client-side MIME / size validation
None. No file-type check, no byte-size check, no content-hash computation, no dedup. Upload is "pick → post MultipartFile." The backend AI flow requires SHA-256 hashing for dedup and MIME/size gates on the client — none of that exists today.

Usage flow — add_product_screen.dart:130-146 and product_provider.dart:130-148
Image upload happens after the product is created: product POST → image POST → attach POST. If any of the 3 fails, the earlier ones are not rolled back. Image failure is swallowed (catch (_) {}) so the product still "saves."

7. Routing — lib/router.dart
Full file (324 lines). The relevant structure:


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isUnknown = authState.status == AuthStatus.unknown;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      if (isUnknown) return null;
      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // Auth (flat — NOT in shell)
      GoRoute(path: '/auth/login',    name: 'login',            builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', name: 'register',         builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/verify-email',    name: 'verify-email',    builder: (_, __) => const VerifyEmailScreen()),
      GoRoute(path: '/auth/forgot-password', name: 'forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/auth/verify-otp', name: 'verify-otp',
        builder: (context, state) => VerifyOtpScreen(email: state.extra as String? ?? '')),
      GoRoute(path: '/auth/new-password', name: 'new-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return NewPasswordScreen(email: extra['email'] ?? '', otp: extra['otp'] ?? '');
        }),

      GoRoute(path: '/settings', name: 'settings', builder: (_, __) => const SettingsScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(path: '/home', name: 'home', builder: (_, __) => const HomeScreen()),

          GoRoute(path: '/products', name: 'products',
            builder: (_, __) => const ProductListScreen(),
            routes: [
              GoRoute(path: 'add', name: 'add-product',
                builder: (_, __) => const AddProductScreen()),
              GoRoute(path: ':id', name: 'product-detail',
                builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
                routes: [
                  GoRoute(path: 'edit', name: 'edit-product',
                    builder: (context, state) => EditProductScreen(product: state.extra as Product)),
                ]),
            ]),

          GoRoute(path: '/orders', name: 'orders',
            builder: (_, __) => const OrderListScreen(),
            routes: [
              GoRoute(path: 'add', name: 'add-order', builder: (_, __) => const AddOrderScreen()),
              GoRoute(path: ':id', name: 'order-detail',
                builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
            ]),

          GoRoute(
            path: '/ai-studio',
            name: 'ai-studio',
            builder: (_, __) => const _PlaceholderScreen('AI Studio'),  // ← current placeholder
          ),

          GoRoute(path: '/customers', name: 'customers',
            builder: (_, __) => const CustomerListScreen(),
            routes: [
              GoRoute(path: ':id', name: 'customer-detail',
                builder: (_, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!)),
            ]),
        ],
      ),
    ],
  );
});
Followed by _MainShell with a custom _ZidBottomNav bottom bar: 5 items (Home, Orders, AI-Studio FAB in the middle, Products, Clients). The center FAB GestureDetector calls context.go('/ai-studio') — router.dart:239. No ShellRoute keys, no StatefulShellRoute — navigation is stateless (tapping a tab rebuilds the branch).

Route patterns to match: state.pathParameters['id'] for path params, state.extra for typed/map payloads.

8. Existing error/result types
No Result<T> / Either / sealed-class pattern anywhere. sealed class, Either, Result< all grep to zero matches.
Exception hierarchy: the AppException family shown in §4 above.
UI surfacing: ad-hoc ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)) inline in each screen. Also inline red-bg error containers in forms (see add_product_screen.dart:540-557). There is no shared showError(context, ...) / showSnack(...) helper. There is no toast package. There is no shared error dialog.
9. Freezed / code generation
freezed: ^2.5.7, json_serializable: ^6.8.0, riverpod_generator: ^2.4.3, build_runner: ^2.4.13, freezed_annotation: ^2.4.4, json_annotation: ^4.9.0, riverpod_annotation: ^2.3.5 all listed in pubspec.
Zero files use them. No @freezed, no @JsonSerializable, no @riverpod, no part '*.g.dart', no part '*.freezed.dart'.
No build.yaml exists at the project root.
Every model is hand-rolled: regular class, const constructor, factory X.fromJson(Map<String, dynamic> json) that casts each field manually. See product_models.dart for the pattern.
Codegen command not used in practice; standard would be dart run build_runner build --delete-conflicting-outputs or watch, but there's nothing to generate right now.
10. PostHog / analytics
Not installed. No posthog_flutter / posthog in pubspec. Grep for posthog|PostHog|Posthog returns zero matches. No analytics wiring of any kind (no Firebase Analytics, no Amplitude, nothing).

11. Localization
Not set up.

flutter_localizations is not in pubspec.
No l10n.yaml at project root.
No lib/l10n/ directory, no .arb files.
Grep for AppLocalizations / flutter_localizations returns zero matches.
All user-facing strings are hardcoded in English in the Dart source, e.g. 'Add Product', 'Cost Price *', 'Required', 'Must be > cost', 'Add Product Photo', 'Tap to choose from camera or gallery', bottom nav labels 'Home' / 'Orders' / 'Products' / 'Clients'. No French, no Arabic, despite the app targeting Tunisian sellers.
12. Platform-specific config
ios/Runner/Info.plist — full

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CADisableMinimumFrameDurationOnPhone</key><true/>
  <key>CFBundleDevelopmentRegion</key><string>$(DEVELOPMENT_LANGUAGE)</string>
  <key>CFBundleDisplayName</key><string>Bochboch</string>
  <key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>bochboch</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$(FLUTTER_BUILD_NAME)</string>
  <key>CFBundleSignature</key><string>????</string>
  <key>CFBundleVersion</key><string>$(FLUTTER_BUILD_NUMBER)</string>
  <key>LSRequiresIPhoneOS</key><true/>
  <key>UIApplicationSceneManifest</key>
  <dict>
    <key>UIApplicationSupportsMultipleScenes</key><false/>
    <key>UISceneConfigurations</key>
    <dict>
      <key>UIWindowSceneSessionRoleApplication</key>
      <array>
        <dict>
          <key>UISceneClassName</key><string>UIWindowScene</string>
          <key>UISceneConfigurationName</key><string>flutter</string>
          <key>UISceneDelegateClassName</key><string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
          <key>UISceneStoryboardFile</key><string>Main</string>
        </dict>
      </array>
    </dict>
  </dict>
  <key>UIApplicationSupportsIndirectInputEvents</key><true/>
  <key>UILaunchStoryboardName</key><string>LaunchScreen</string>
  <key>UIMainStoryboardFile</key><string>Main</string>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
  <key>UISupportedInterfaceOrientations~ipad</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
</dict>
</plist>
⚠ No NSCameraUsageDescription, no NSPhotoLibraryUsageDescription, no NSMicrophoneUsageDescription. image_picker will crash on iOS as soon as a non-debug user tries to open the camera or gallery. The camera purpose string MUST be added before AI Studio ships (and arguably the existing add-product flow is already broken on iOS without it — not sure if anyone's tested it on a real device).

android/app/src/main/AndroidManifest.xml — full

<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="bochboch"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data android:name="io.flutter.embedding.android.NormalTheme"
                       android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
⚠ No <uses-permission> lines at all. image_picker on modern Android (API 33+) doesn't strictly require READ_EXTERNAL_STORAGE thanks to the system photo picker, but CAMERA and INTERNET are conventionally declared. INTERNET is auto-added by the Flutter tool in debug, but not in release — you'll want to add it explicitly.

android/app/build.gradle.kts
The project uses Kotlin DSL (build.gradle.kts), not build.gradle. Relevant lines (file has no explicit numeric minSdk/targetSdk — inherits from Flutter tool):


android {
    namespace = "com.bochboch.bochboch"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bochboch.bochboch"
        minSdk = flutter.minSdkVersion      // ← no hardcoded value
        targetSdk = flutter.targetSdkVersion // ← no hardcoded value
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    buildTypes {
        release { signingConfig = signingConfigs.getByName("debug") }
    }
}
minSdkVersion and targetSdkVersion are not overridden — they use whatever the Flutter SDK defaults to (current Flutter >=3.41.0 defaults to minSdk = 21 / targetSdk = 34, but your collaborator should verify by running flutter doctor --verbose or checking the resolved flutter.minSdkVersion if they care about a specific floor).

13. Anything I should know
Architectural oddities & active gaps:

ai_studio directory is pre-scaffolded but empty. lib/features/ai_studio/{data,domain,presentation/{providers,screens,widgets}} all exist as empty directories. The /ai-studio GoRoute exists and points at _PlaceholderScreen('AI Studio') — the bottom-nav center FAB already routes there. This is the entry point to replace.

The ApiEndpoints.ai* constants are stale. api_endpoints.dart:45-48 lists /ai/captions, /ai/whatsapp, /ai/ad-creative — but per the IDE-selected backend doc the actual surface is /ai/sessions, /ai/sessions/:id/photos, /ai/sessions/:id/analyze, etc. These constants were written before the new AI backend module shipped. The collaborator should not reuse them.

ErrorHandler drops the code field. error_handler.dart:23-40 maps HTTP status to exception type but ignores apiError.code. The backend AI doc defines specific codes (QUOTA_EXCEEDED, COST_CEILING_EXCEEDED, AI_PROVIDER_UNAVAILABLE, AI_PROVIDER_ERROR, AI_PARSE_ERROR, STORAGE_UPLOAD_FAILED) that the UI needs to distinguish. A new AiException with a code field (or extending ServerException with it) will be needed before the quality-gate error UI can work correctly.

Base URL hardcoded to http://localhost:3000/api/v1, no flavoring. On a physical Android device this fails (needs http://10.0.2.2:3000 for emulator or the machine's LAN IP for device). No --dart-define or .env wiring. If the collaborator tests on-device, this will bite.

pretty_dio_logger in pubspec but not in the interceptor list. Unused dependency.

flutter_image_compress in pubspec but unused. The quality-gate feature will need it (or a real compression approach) — it's already available.

All 8 zid_* shared widget files are literal stubs — each is a single line // TODO. zid_button.dart, zid_input.dart, zid_card.dart, zid_avatar.dart, zid_badge.dart, zid_empty_state.dart, zid_list_row.dart, zid_skeleton.dart. Feature screens build their own buttons / cards / inputs inline, leaning on AppTheme defaults. The collaborator should not assume a ZidButton exists — they'll either build inline (current convention) or actually flesh these stubs out.

insights/ feature skeleton is entirely empty, mirror of ai_studio. Ignore.

Mixed state-management style: the auth layer uses the legacy StateNotifierProvider + StateNotifier/State pattern (auth_state_provider.dart:9-12), but everything else uses the modern AsyncNotifierProvider / NotifierProvider API. Use the modern pattern for new code.

The DioClient is a plain global async singleton, not a Riverpod provider. Repositories call (await DioClient.getInstance()).dio per method. This works but means the Dio instance isn't overridable in tests via ProviderScope(overrides: ...). If the collaborator wants a testable seam for AI Studio, they'd have to either inject Dio into each repository constructor or introduce a dioProvider — but that'd diverge from the existing convention.

Image upload is a 2-step pattern (upload → attach), both to backend. Backend handles Cloudinary; no direct-to-Cloudinary from the client. Matches the AI backend flow (POST /ai/sessions/:id/photos is multipart-upload-via-backend, not signed-URL-to-Cloudinary). Consistent.

AddProductNotifier.createProduct swallows image failures silently (product_provider.dart:136-148) — catch (_) {}. If the AI Studio author copies this pattern, they'll lose error visibility on photo uploads, which is dangerous given the backend AI flow has meaningful per-photo failure modes (quality gate, MIME reject, dedup collision). Don't copy the swallow.

Only TODO comment of substance: verify_email_screen.dart:254 — // TODO: resend OTP endpoint when backend adds it. Nothing photo- or AI-related.

No test coverage. flutter_test is in dev_deps but the test/ directory presumably contains only the default widget test (not inspected, but consistent with the absence of any testing patterns in lib/). Don't expect CI guardrails.

google_fonts is in pubspec but unused in source (the font is loaded from assets/fonts/PlusJakartaSans-*.ttf declared in pubspec's fonts: section, not via GoogleFonts.* runtime fetch). Dead dep, probably.

icons_plus in pubspec but unused in source. Zero import 'package:icons_plus' matches.

drift is in pubspec but there's no database.dart, no .g.dart drift files, no drift schema classes. Fully unused today.

That's the whole picture.