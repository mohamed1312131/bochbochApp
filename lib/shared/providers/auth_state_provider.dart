import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/observability/posthog_service.dart';

const _accessTokenKey = 'access_token';
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.accessToken,
  });

  final AuthStatus status;
  final String? accessToken;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, String? accessToken}) => AuthState(
        status: status ?? this.status,
        accessToken: accessToken ?? this.accessToken,
      );
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier()
      : super(const AuthState(status: AuthStatus.unknown)) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    state = AuthState(
      status: token != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      accessToken: token,
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    state = AuthState(
      status: AuthStatus.authenticated,
      accessToken: token,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await PostHogService.reset();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}