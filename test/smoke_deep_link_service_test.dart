import 'package:flutter_test/flutter_test.dart';
import 'package:dido/core/deep_links/deep_link_service.dart';

void main() {
  group('mapUriToRoute', () {
    test('dido://payment/return?paymentId=xxx → /payment/return', () {
      expect(
        mapUriToRoute(Uri.parse('dido://payment/return?paymentId=abc-123')),
        '/payment/return?paymentId=abc-123',
      );
    });

    test('dido://payment/cancel?paymentId=xxx → /payment/cancel', () {
      expect(
        mapUriToRoute(Uri.parse('dido://payment/cancel?paymentId=abc-123')),
        '/payment/cancel?paymentId=abc-123',
      );
    });

    test('unknown scheme → null', () {
      expect(mapUriToRoute(Uri.parse('https://example.com/foo')), isNull);
    });

    test('unknown host → null', () {
      expect(mapUriToRoute(Uri.parse('dido://unknown/foo')), isNull);
    });

    test('unknown payment subpath → null', () {
      expect(mapUriToRoute(Uri.parse('dido://payment/unknown')), isNull);
    });

    test('missing paymentId still maps but with empty param', () {
      expect(
        mapUriToRoute(Uri.parse('dido://payment/return')),
        '/payment/return?paymentId=',
      );
    });

    test('payment host with no path → null', () {
      expect(mapUriToRoute(Uri.parse('dido://payment')), isNull);
    });
  });
}
