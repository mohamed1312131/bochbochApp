import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Pure URI → internal-route mapper. Public so it can be unit-tested
/// without an AppLinks/GoRouter instance.
String? mapUriToRoute(Uri uri) {
  if (uri.scheme != 'dido') return null;
  switch (uri.host) {
    case 'payment':
      if (uri.pathSegments.isEmpty) return null;
      final paymentId = uri.queryParameters['paymentId'] ?? '';
      switch (uri.pathSegments.first) {
        case 'return':
          return '/payment/return?paymentId=$paymentId';
        case 'cancel':
          return '/payment/cancel?paymentId=$paymentId';
      }
      return null;
    default:
      return null;
  }
}

class DeepLinkService {
  DeepLinkService({required this.router, AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks();

  final GoRouter router;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  /// Call once on app start — handles cold-start initial link AND
  /// warm-state stream of incoming links.
  Future<void> initialize() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService: getInitialLink failed: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object err) {
        debugPrint('DeepLinkService: uriLinkStream error: $err');
      },
    );
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handleUri(Uri uri) {
    final route = mapUriToRoute(uri);
    if (route != null) {
      router.go(route);
    } else {
      debugPrint('DeepLinkService: unhandled uri $uri');
    }
  }
}
