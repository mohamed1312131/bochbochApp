import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/auth_events.dart';
import '../../core/api/dio_client.dart';
import '../../core/observability/posthog_service.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Keys cleared on every logout path. Mirror with AuthRepository.logout()
/// and AuthInterceptor._clearTokens — there is no good way to share this
/// across layers without inverting the dependency graph (shared/ would
/// have to know about features/), so the price of duplication is a
/// keep-this-list-in-sync comment.
const _allAuthKeys = <String>[
  _accessTokenKey,
  _refreshTokenKey,
  'current_user_id',
  'user_full_name',
  'user_email',
  'user_subscription_tier',
  'onboarding_user_id',
];

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
    // H21: when AuthInterceptor's refresh path gives up (refresh token
    // expired / 5xx / network), the interceptor wipes local state but
    // never told the rest of the app the user is logged out — UI kept
    // showing /home until the next manual auth check. Subscribe to the
    // terminal-logout signal so the state flips immediately.
    _interceptorLogoutSub = AuthEvents.onTerminalLogout.listen((_) {
      if (mounted && state.status != AuthStatus.unauthenticated) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  StreamSubscription<void>? _interceptorLogoutSub;

  @override
  void dispose() {
    _interceptorLogoutSub?.cancel();
    super.dispose();
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

  /// Full logout: clears every auth-related secure-storage key, clears
  /// the persistent cookie jar (drops the refresh-token cookie), resets
  /// PostHog identity, and transitions to unauthenticated.
  ///
  /// C7 fix — the previous implementation only deleted the access token,
  /// so the refresh-token cookie + PII keys (email, full_name, tier,
  /// onboarding_user_id) survived "Déconnexion" and were available to
  /// the next user of the device.
  Future<void> logout() async {
    await Future.wait([
      for (final key in _allAuthKeys) _storage.delete(key: key),
    ]);
    try {
      await (await DioClient.getInstance()).clearCookies();
    } catch (_) {
      // Cookie jar may not be initialised in tests; non-fatal.
    }
    await PostHogService.reset();
    if (mounted) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}
