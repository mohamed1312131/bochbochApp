/// Feature flags loaded at build time via --dart-define.
/// AI features are deferred to v2 per spec. Hidden by default.
/// To enable for development: flutter run --dart-define=AI_ENABLED=true
class FeatureFlags {
  const FeatureFlags._();
  static const bool aiEnabled =
      bool.fromEnvironment('AI_ENABLED', defaultValue: false);

  /// Gates the Google Sign-In button. The native GoogleSignIn iOS SDK
  /// throws an uncatchable NSException (SIGABRT) when the app is missing
  /// CFBundleURLTypes / GIDClientID, so we hide the button until the
  /// platform setup is done:
  ///   - iOS: CFBundleURLTypes with REVERSED_CLIENT_ID in Info.plist
  ///   - Android: google-services.json in android/app/ and SHA-1
  ///     fingerprint registered with the Google Cloud OAuth client
  /// Enable with: flutter run --dart-define=GOOGLE_SIGNIN_ENABLED=true
  static const bool googleSigninEnabled =
      bool.fromEnvironment('GOOGLE_SIGNIN_ENABLED', defaultValue: false);

  /// Sentry crash reporting — passed via --dart-define-from-file=dart_defines/dev.json.
  /// Init only fires when sentryEnabled is true AND DSN is set AND
  /// (kReleaseMode == true OR sentryForceEnable == true). See sentry_bootstrap.dart.
  static const bool sentryEnabled =
      bool.fromEnvironment('SENTRY_ENABLED', defaultValue: false);

  static const String sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static const String sentryEnv =
      String.fromEnvironment('SENTRY_ENV', defaultValue: 'development');

  static const String sentryRelease =
      String.fromEnvironment('SENTRY_RELEASE', defaultValue: 'dido-flutter@unknown');

  static const bool sentryForceEnable =
      bool.fromEnvironment('SENTRY_FORCE_ENABLE', defaultValue: false);

  /// PostHog analytics. Disabled by default; turned on in dart_defines/dev.json.
  static const bool posthogEnabled =
      bool.fromEnvironment('POSTHOG_ENABLED', defaultValue: false);

  static const String posthogApiKey =
      String.fromEnvironment('POSTHOG_API_KEY', defaultValue: '');

  static const String posthogHost =
      String.fromEnvironment('POSTHOG_HOST',
          defaultValue: 'https://eu.i.posthog.com');
}
