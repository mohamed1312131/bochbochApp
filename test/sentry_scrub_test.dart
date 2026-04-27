// Verifies the Sentry beforeSend / beforeBreadcrumb scrubbing logic
// without hitting the real Sentry SDK. Run with:
//   flutter test test/sentry_scrub_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:dido/core/observability/sentry_bootstrap.dart';

void main() {
  group('beforeSend — header allow-list', () {
    test('keeps user-agent, accept, accept-language, x-request-id', () {
      final ev = SentryEvent(
        request: SentryRequest(
          url: 'http://api/products',
          headers: {
            'user-agent': 'curl/8',
            'accept': 'application/json',
            'accept-language': 'fr-TN',
            'x-request-id': 'r-1',
          },
        ),
      );
      final out = scrubEventForTest(ev)!;
      expect(out.request!.headers['user-agent'], 'curl/8');
      expect(out.request!.headers['accept'], 'application/json');
      expect(out.request!.headers['accept-language'], 'fr-TN');
      expect(out.request!.headers['x-request-id'], 'r-1');
    });

    test('drops authorization, cookie, and unknown headers', () {
      final ev = SentryEvent(
        request: SentryRequest(
          url: 'http://api/products',
          headers: {
            'authorization': 'Bearer leak',
            'cookie': 'sid=leak',
            'x-secret-token': 'leak',
            'user-agent': 'ok',
          },
        ),
      );
      final out = scrubEventForTest(ev)!;
      expect(out.request!.headers.containsKey('authorization'), false);
      expect(out.request!.headers.containsKey('cookie'), false);
      expect(out.request!.headers.containsKey('x-secret-token'), false);
      expect(out.request!.headers['user-agent'], 'ok');
    });

    test('case-insensitive: Authorization (caps) is dropped', () {
      final ev = SentryEvent(
        request: SentryRequest(
          url: 'http://api/products',
          headers: {'AUTHORIZATION': 'leak', 'User-Agent': 'ok'},
        ),
      );
      final out = scrubEventForTest(ev)!;
      expect(out.request!.headers.containsKey('AUTHORIZATION'), false);
      expect(out.request!.headers['User-Agent'], 'ok');
    });
  });

  group('beforeSend — cookies', () {
    test('cookies field is dropped to null', () {
      final ev = SentryEvent(
        request: SentryRequest(
          url: 'http://api/products',
          cookies: 'sid=leak',
        ),
      );
      final out = scrubEventForTest(ev)!;
      expect(out.request!.cookies, null);
    });
  });

  group('beforeSend — request.data on /auth/* paths', () {
    test('drops the entire body for /auth/login', () {
      final ev = SentryEvent(
        request: SentryRequest(
          url: 'http://api/api/v1/auth/login',
          data: {'email': 'u@x.com', 'password': 'plaintext'},
        ),
      );
      final out = scrubEventForTest(ev)!;
      expect(out.request!.data, null);
    });

    test('drops the entire body for /auth/verify-otp', () {
      final ev = SentryEvent(
        request: SentryRequest(
          url: 'http://api/api/v1/auth/verify-otp',
          data: {'userId': 'abc', 'otp': '123456'},
        ),
      );
      final out = scrubEventForTest(ev)!;
      expect(out.request!.data, null);
    });
  });

  group('beforeSend — request.data on non-auth paths', () {
    test('recursively replaces sensitive keys with [Filtered]', () {
      final ev = SentryEvent(
        request: SentryRequest(
          url: 'http://api/api/v1/products',
          data: {
            'name': 'shoe',
            'password': 'plain',
            'nested': {
              'email': 'u@x.com',
              'phone': '+216',
              'inner': {'otp': '111111', 'refreshToken': 'r'},
            },
          },
        ),
      );
      final out = scrubEventForTest(ev)!;
      final d = out.request!.data as Map;
      expect(d['name'], 'shoe');
      expect(d['password'], '[Filtered]');
      expect((d['nested'] as Map)['email'], '[Filtered]');
      expect((d['nested'] as Map)['phone'], '[Filtered]');
      expect(((d['nested'] as Map)['inner'] as Map)['otp'], '[Filtered]');
      expect(((d['nested'] as Map)['inner'] as Map)['refreshToken'],
          '[Filtered]');
    });

    test('walks into lists', () {
      final ev = SentryEvent(
        request: SentryRequest(
          url: 'http://api/api/v1/products',
          data: {
            'items': [
              {'password': 'p1', 'name': 'x'},
              {'password': 'p2'},
            ],
          },
        ),
      );
      final out = scrubEventForTest(ev)!;
      final items = (out.request!.data as Map)['items'] as List;
      expect(items[0]['password'], '[Filtered]');
      expect(items[0]['name'], 'x');
      expect(items[1]['password'], '[Filtered]');
    });
  });

  group('beforeBreadcrumb — navigation extra is dropped', () {
    test('removes data.extra on navigation breadcrumb', () {
      final crumb = Breadcrumb(
        category: 'navigation',
        data: {
          'from': '/auth/forgot-password',
          'to': '/auth/verify-otp',
          'extra': {'email': 'u@x.com', 'otp': '123456'},
        },
      );
      final out = scrubBreadcrumbForTest(crumb)!;
      expect(out.data!.containsKey('extra'), false);
      expect(out.data!['from'], '/auth/forgot-password');
      expect(out.data!['to'], '/auth/verify-otp');
    });

    test('non-navigation breadcrumbs untouched', () {
      final crumb = Breadcrumb(
        category: 'http',
        data: {'extra': 'keep-me'},
      );
      final out = scrubBreadcrumbForTest(crumb)!;
      expect(out.data!['extra'], 'keep-me');
    });
  });
}
