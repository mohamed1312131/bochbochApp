import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/observability/posthog_service.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/google_signin_service.dart';
import '../../domain/auth_models.dart';

const _onboardingUserIdKey = 'onboarding_user_id';
const _onboardingStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

enum LoginStatus { idle, loading, success, error }

class LoginState {
  const LoginState({
    this.status = LoginStatus.idle,
    this.error,
    this.user,
  });

  final LoginStatus status;
  final String? error;
  final AuthUser? user;

  LoginState copyWith({
    LoginStatus? status,
    String? error,
    AuthUser? user,
  }) =>
      LoginState(
        status: status ?? this.status,
        error: error,
        user: user ?? this.user,
      );
}

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier(this._repository, this._ref) : super(const LoginState());

  final AuthRepository _repository;
  final Ref _ref;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: LoginStatus.loading, error: null);
    try {
      final response = await _repository.login(
        email: email,
        password: password,
      );
      await _ref
          .read(authStateProvider.notifier)
          .saveToken(response.accessToken);
      await _onboardingStorage.write(
        key: _onboardingUserIdKey,
        value: response.user.id,
      );
      await PostHogService.identify(response.user.id);
      state = state.copyWith(
        status: LoginStatus.success,
        user: response.user,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: LoginStatus.error,
        error: e.message,
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: LoginStatus.loading, error: null);
    try {
      final idToken = await GoogleSignInService().signIn();
      if (idToken == null) {
        // User cancelled the picker.
        state = const LoginState();
        return;
      }
      final response = await _repository.loginWithGoogle(idToken: idToken);
      await _ref
          .read(authStateProvider.notifier)
          .saveToken(response.accessToken);
      await _onboardingStorage.write(
        key: _onboardingUserIdKey,
        value: response.user.id,
      );
      await PostHogService.identify(response.user.id);
      state = state.copyWith(
        status: LoginStatus.success,
        user: response.user,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: LoginStatus.error,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: LoginStatus.error,
        error: 'Google sign-in failed. Please try again.',
      );
    }
  }

  void reset() => state = const LoginState();
}

final loginProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref.read(authRepositoryProvider), ref);
});

enum RegisterStatus { idle, loading, success, error }

class RegisterState {
  const RegisterState({
    this.status = RegisterStatus.idle,
    this.error,
    this.userId,
    this.email,
  });

  final RegisterStatus status;
  final String? error;
  final String? userId;
  final String? email;

  RegisterState copyWith({
    RegisterStatus? status,
    String? error,
    String? userId,
    String? email,
  }) =>
      RegisterState(
        status: status ?? this.status,
        error: error,
        userId: userId ?? this.userId,
        email: email ?? this.email,
      );
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  RegisterNotifier(this._repository)
      : super(const RegisterState());

  final AuthRepository _repository;

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: RegisterStatus.loading, error: null);
    try {
      final result = await _repository.register2(
        fullName: fullName,
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: RegisterStatus.success,
        userId: result.userId,
        email: result.email,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        status: RegisterStatus.error,
        error: e.message,
      );
    }
  }

  void reset() => state = const RegisterState();
}

final registerProvider =
    StateNotifierProvider.autoDispose<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref.read(authRepositoryProvider));
});