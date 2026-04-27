/// Sentry init for Flutter, mirroring backend's bootstrap pattern.
///
/// Production gate: only inits when SENTRY_ENABLED=true AND SENTRY_DSN
/// is non-empty AND (kReleaseMode OR SENTRY_FORCE_ENABLE=true). Otherwise
/// runs the app bare and prints an auditable skip log if a DSN is set
/// but the gate refused (so a developer who accidentally has the prod DSN
/// in their dart_defines sees why events aren't shipping).
///
/// All scrubbing/filtering is centralized in [_beforeSend] and
/// [_beforeBreadcrumb] so future contributors have one place to look.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/feature_flags.dart';

const _scrubKeys = <String>{
  'password',
  'otp',
  'idtoken',
  'accesstoken',
  'refreshtoken',
  'phone',
  'email',
  'authorization',
  'cookie',
};

const _allowedHeaders = <String>{
  'user-agent',
  'accept',
  'accept-language',
  'x-request-id',
};

final _authPathPattern = RegExp(r'/auth/');

Future<void> initSentryAndRunApp(Widget Function() appBuilder) async {
  final dsn = FeatureFlags.sentryDsn;
  final enabled = FeatureFlags.sentryEnabled;
  final force = FeatureFlags.sentryForceEnable;
  final willInit = enabled && dsn.isNotEmpty && (kReleaseMode || force);

  if (dsn.isNotEmpty && !willInit) {
    debugPrint(
      '[sentry] skipping init — DSN set but kReleaseMode=$kReleaseMode '
      'and SENTRY_FORCE_ENABLE=$force. Sentry will not capture events.',
    );
  }

  if (!willInit) {
    runApp(appBuilder());
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = FeatureFlags.sentryEnv;
      options.release = FeatureFlags.sentryRelease;
      options.tracesSampleRate = 0.0;
      options.sampleRate = 1.0;
      // attachScreenshot / attachViewHierarchy default to false in v9; we
      // do not enable them — both could leak PII.
      options.sendDefaultPii = false;
      options.beforeSend = _beforeSend;
      options.beforeBreadcrumb = _beforeBreadcrumb;
    },
    appRunner: () => runApp(appBuilder()),
  );

  debugPrint(
    '[sentry] initialized env=${FeatureFlags.sentryEnv} '
    'release=${FeatureFlags.sentryRelease} forced=$force',
  );
}

/// Visible for testing — exercised by a verification harness.
@visibleForTesting
SentryEvent? scrubEventForTest(SentryEvent event) =>
    _beforeSend(event, Hint());

@visibleForTesting
Breadcrumb? scrubBreadcrumbForTest(Breadcrumb breadcrumb) =>
    _beforeBreadcrumb(breadcrumb, Hint());

SentryEvent? _beforeSend(SentryEvent event, Hint hint) {
  // We do NOT filter by exception class here; the Flutter side captures
  // far fewer expected errors than the backend, and any uncaught
  // exception surfacing here is by definition interesting.
  final request = event.request;
  if (request != null) {
    final url = request.url ?? '';
    final isAuthPath = _authPathPattern.hasMatch(url);

    final scrubbedHeaders = _filterHeaders(request.headers);
    final scrubbedData = isAuthPath ? null : _scrubDeep(request.data);

    // Build a fresh SentryRequest so that null values actually clear
    // cookies/data — `copyWith` uses `??` and won't propagate nulls.
    final newRequest = SentryRequest(
      url: request.url,
      method: request.method,
      queryString: request.queryString,
      fragment: request.fragment,
      apiTarget: request.apiTarget,
      data: scrubbedData,
      headers: scrubbedHeaders,
      env: request.env,
      // cookies intentionally omitted → null
    );
    // ignore: deprecated_member_use
    event = event.copyWith(request: newRequest);
  }

  // Scrub any response payload sentry_dio attached on captured failures.
  final responseCtx = event.contexts['response'];
  if (responseCtx is Map<String, dynamic>) {
    final url = (event.request?.url) ?? '';
    final isAuthPath = _authPathPattern.hasMatch(url);
    final newResponse = Map<String, dynamic>.from(responseCtx);
    if (isAuthPath) {
      newResponse.remove('data');
      newResponse.remove('body');
    } else {
      if (newResponse.containsKey('data')) {
        newResponse['data'] = _scrubDeep(newResponse['data']);
      }
      if (newResponse.containsKey('body')) {
        newResponse['body'] = _scrubDeep(newResponse['body']);
      }
    }
    event.contexts['response'] = newResponse;
  }

  return event;
}

Breadcrumb? _beforeBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
  if (breadcrumb == null) return null;
  if (breadcrumb.category != 'navigation') return breadcrumb;
  final data = breadcrumb.data;
  if (data == null || !data.containsKey('extra')) return breadcrumb;
  final newData = Map<String, dynamic>.from(data)..remove('extra');
  // ignore: deprecated_member_use
  return breadcrumb.copyWith(data: newData);
}

Map<String, String> _filterHeaders(Map<String, String> headers) {
  final out = <String, String>{};
  headers.forEach((k, v) {
    if (_allowedHeaders.contains(k.toLowerCase())) out[k] = v;
  });
  return out;
}

Object? _scrubDeep(Object? value) {
  if (value is Map) {
    final out = <String, Object?>{};
    value.forEach((k, v) {
      final keyStr = k.toString();
      if (_scrubKeys.contains(keyStr.toLowerCase())) {
        out[keyStr] = '[Filtered]';
      } else {
        out[keyStr] = _scrubDeep(v);
      }
    });
    return out;
  }
  if (value is List) return value.map(_scrubDeep).toList();
  return value;
}
