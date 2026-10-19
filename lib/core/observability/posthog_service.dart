import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../config/feature_flags.dart';

/// PostHog wrapper with an explicit consent gate (C8).
///
/// Identifying users (and capturing per-user events) without consent is a
/// privacy violation under EU GDPR and Tunisian data-protection law. The
/// previous implementation called `identify` on every login regardless of
/// consent. We now require:
///   1. PostHog is enabled at build time (via dart_defines).
///   2. The SDK initialised successfully.
///   3. The user has explicitly consented via [setAnalyticsConsent].
///
/// Anonymous capture (no `identify`) is allowed when consent is unknown so
/// we still get crash-free / install funnel signal — the SDK never sees a
/// user identifier until the user opts in. Set [requireConsentForCapture]
/// to true to disable anonymous capture too.
class PostHogService {
  PostHogService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _consentKey = 'analytics_consent';

  /// Set true if your privacy policy requires consent for ANY capture
  /// (not just identify). Default false: anonymous events flow.
  static const bool requireConsentForCapture = false;

  static bool _initialized = false;
  static bool _consentGranted = false;

  /// Call once on app start, before runApp.
  static Future<void> initialize() async {
    if (!FeatureFlags.posthogEnabled || FeatureFlags.posthogApiKey.isEmpty) {
      debugPrint('[posthog] disabled or no API key — skipping init');
      return;
    }
    final config = PostHogConfig(FeatureFlags.posthogApiKey)
      ..host = FeatureFlags.posthogHost
      ..captureApplicationLifecycleEvents = false
      ..debug = kDebugMode;
    await Posthog().setup(config);
    _initialized = true;

    // Hydrate consent from secure storage so a granted consent survives
    // app restarts. Read fails (rare keychain errors) default to false.
    try {
      _consentGranted =
          (await _storage.read(key: _consentKey)) == 'true';
    } catch (_) {
      _consentGranted = false;
    }
    debugPrint('[posthog] initialized (consent=$_consentGranted)');
  }

  /// Persist the user's analytics-consent choice. Pass true after the
  /// user accepts an in-app consent prompt; pass false to revoke.
  /// Revoking also resets the SDK identity to drop any prior link.
  static Future<void> setAnalyticsConsent(bool granted) async {
    _consentGranted = granted;
    await _storage.write(
      key: _consentKey,
      value: granted ? 'true' : 'false',
    );
    if (!granted && _initialized) {
      await Posthog().reset();
    }
  }

  /// Whether identify/per-user capture is allowed right now.
  static bool get hasAnalyticsConsent => _consentGranted;

  /// Identify the logged-in user. Call after successful login/signup.
  /// NEVER passes PII as distinctId or properties.
  ///
  /// No-op when consent has not been granted (C8). The screens still call
  /// this safely; the gate lives here so call sites don't need to know.
  static Future<void> identify(String userId) async {
    if (!_initialized) return;
    if (!_consentGranted) {
      debugPrint('[posthog] identify($userId) skipped — consent not granted');
      return;
    }
    await Posthog().identify(userId: userId);
  }

  /// Reset identity on logout. Prevents events bleeding between users.
  static Future<void> reset() async {
    if (!_initialized) return;
    await Posthog().reset();
  }

  /// Fire a UX event. Fire-and-forget — errors are swallowed, never thrown.
  /// Anonymous events are allowed by default (see [requireConsentForCapture]).
  static void capture(
    String eventName, {
    Map<String, Object>? properties,
  }) {
    if (!_initialized) return;
    if (requireConsentForCapture && !_consentGranted) return;
    try {
      Posthog().capture(
        eventName: eventName,
        properties: properties,
      );
    } catch (e) {
      debugPrint('[posthog] capture error: $e');
    }
  }
}
