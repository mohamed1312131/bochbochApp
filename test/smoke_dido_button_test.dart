import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dido/shared/widgets/dido_button.dart';

void main() {
  group('DidoButton', () {
    testWidgets('primary renders label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DidoButton.primary(
            label: 'Test',
            onPressed: () {},
          ),
        ),
      ));
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('primary calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DidoButton.primary(
            label: 'Tap me',
            onPressed: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.byType(DidoButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('loading state shows spinner not label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DidoButton.primary(
            label: 'Submit',
            loading: true,
            onPressed: () {},
          ),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('loading state ignores tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DidoButton.primary(
            label: 'Submit',
            loading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.byType(DidoButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('disabled (enabled=false) ignores tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DidoButton.primary(
            label: 'Disabled',
            enabled: false,
            onPressed: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.byType(DidoButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('null onPressed disables tap', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DidoButton.primary(
            label: 'Null',
            onPressed: null,
          ),
        ),
      ));
      await tester.tap(find.byType(DidoButton));
      await tester.pump();
    });
  });
}
