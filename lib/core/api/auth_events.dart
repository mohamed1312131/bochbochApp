import 'dart:async';

/// Lightweight pub/sub for auth lifecycle events that need to cross the
/// network layer ↔ state layer boundary without an explicit Riverpod ref.
///
/// `AuthInterceptor` lives below the Riverpod tree and can't read providers
/// directly. When its refresh path gives up (refresh token revoked / 401
/// from /auth/refresh / 5xx / network error), it calls
/// [emitTerminalLogout] so `AuthStateNotifier` can transition the global
/// state and the router can boot the user back to /auth/login.
///
/// One broadcast stream — multiple subscribers OK. Survives provider
/// rebuilds.
abstract final class AuthEvents {
  static final StreamController<void> _logoutController =
      StreamController<void>.broadcast();

  /// Subscribe to receive a tick whenever the network layer concludes
  /// the session is unrecoverable.
  static Stream<void> get onTerminalLogout => _logoutController.stream;

  /// Called by [AuthInterceptor] after `_clearTokens()`.
  static void emitTerminalLogout() {
    if (!_logoutController.isClosed) {
      _logoutController.add(null);
    }
  }
}
