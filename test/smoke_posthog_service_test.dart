import 'package:flutter_test/flutter_test.dart';
import 'package:dido/core/observability/posthog_service.dart';

void main() {
  group('PostHogService (disabled)', () {
    test('capture does not throw when not initialized', () {
      expect(
        () => PostHogService.capture('test_event'),
        returnsNormally,
      );
    });

    test('identify does not throw when not initialized', () async {
      await expectLater(
        PostHogService.identify('user-id'),
        completes,
      );
    });

    test('reset does not throw when not initialized', () async {
      await expectLater(
        PostHogService.reset(),
        completes,
      );
    });
  });
}
