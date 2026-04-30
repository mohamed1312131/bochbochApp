import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../config/feature_flags.dart';

class PostHogService {
  PostHogService._();

  static bool _initialized = false;

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
    debugPrint('[posthog] initialized');
  }

  /// Identify the logged-in user. Call after successful login/signup.
  /// NEVER pass PII as distinctId or properties.
  static Future<void> identify(String userId) async {
    if (!_initialized) return;
    await Posthog().identify(userId: userId);
  }

  /// Reset identity on logout. Prevents events bleeding between users.
  static Future<void> reset() async {
    if (!_initialized) return;
    await Posthog().reset();
  }

  /// Fire a UX event. Fire-and-forget — errors are swallowed, never thrown.
  static void capture(
    String eventName, {
    Map<String, Object>? properties,
  }) {
    if (!_initialized) return;
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
