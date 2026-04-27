import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'current_user_id';

  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final dio = await _getDio();
      await dio.post(
        ApiEndpoints.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<RegisterResult> register2({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      return RegisterResult(
        userId: user['id'] as String,
        email: email,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final loginResponse = LoginResponse.fromJson(data);

      // Store both tokens
      await _storage.write(
          key: _accessTokenKey, value: loginResponse.accessToken);
      if (loginResponse.refreshToken != null) {
        await _storage.write(
            key: _refreshTokenKey, value: loginResponse.refreshToken!);
      }
      await _storage.write(key: _userKey, value: loginResponse.user.id);
      await _storage.write(key: 'user_full_name', value: loginResponse.user.fullName);
      await _storage.write(key: 'user_email', value: loginResponse.user.email);
      await _storage.write(key: 'user_subscription_tier', value: loginResponse.user.subscriptionTier);

      return loginResponse;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<LoginResponse> loginWithGoogle({required String idToken}) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.loginGoogle,
        data: {'idToken': idToken},
      );
      final data = response.data as Map<String, dynamic>;
      final loginResponse = LoginResponse.fromJson(data);

      await _storage.write(
          key: _accessTokenKey, value: loginResponse.accessToken);
      if (loginResponse.refreshToken != null) {
        await _storage.write(
            key: _refreshTokenKey, value: loginResponse.refreshToken!);
      }
      await _storage.write(key: _userKey, value: loginResponse.user.id);
      await _storage.write(
          key: 'user_full_name', value: loginResponse.user.fullName);
      await _storage.write(key: 'user_email', value: loginResponse.user.email);
      await _storage.write(
          key: 'user_subscription_tier',
          value: loginResponse.user.subscriptionTier);

      return loginResponse;
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> verifyEmail({
    required String userId,
    required String otp,
  }) async {
    try {
      final dio = await _getDio();
      await dio.post(
        ApiEndpoints.verifyEmail,
        data: {'userId': userId, 'otp': otp},
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      final dio = await _getDio();
      await dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final dio = await _getDio();
      await dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> logout() async {
    try {
      final dio = await _getDio();
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      await dio.post(
        ApiEndpoints.logout,
        data: refreshToken != null
            ? {'refreshToken': refreshToken}
            : null,
      );
    } catch (_) {
      // Best effort
    } finally {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userKey);
      await _storage.delete(key: 'user_full_name');
      await _storage.delete(key: 'user_email');
      await _storage.delete(key: 'user_subscription_tier');
      await (await DioClient.getInstance()).clearCookies();
    }
  }
}