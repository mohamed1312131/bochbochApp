import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dido/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:dido/features/onboarding/presentation/screens/onboarding_screen.dart';

class _FakeOnboardingNotifier
    extends AutoDisposeAsyncNotifier<OnboardingState>
    implements OnboardingNotifier {
  bool didSubmitStep1 = false;
  bool didSubmitStep2 = false;
  bool didSkipStep2 = false;
  bool step1ShouldSucceed = true;
  bool step2ShouldSucceed = true;

  @override
  Future<OnboardingState> build() async => const OnboardingState();

  void _set(OnboardingState s) => state = AsyncData(s);
  OnboardingState get _s => state.valueOrNull ?? const OnboardingState();

  @override
  void setBoutiqueName(String v) => _set(_s.copyWith(boutiqueName: v));
  @override
  void setBoutiqueCategory(String v) => _set(_s.copyWith(boutiqueCategory: v));
  @override
  void setBoutiqueCity(String v) => _set(_s.copyWith(boutiqueCity: v));
  @override
  void setBrandColor(String? v) => _set(_s.copyWith(brandColor: v));
  @override
  void setGoalKind(String v) => _set(_s.copyWith(goalKind: v));
  @override
  void setGoalType(String v) => _set(_s.copyWith(goalType: v));
  @override
  void setGoalTargetValue(int? v) => _set(_s.copyWith(goalTargetValue: v));
  @override
  void setGoalLabel(String? v) => _set(_s.copyWith(goalLabel: v));

  @override
  Future<void> uploadLogo(_) async {}
  @override
  Future<void> saveDraft() async {}

  @override
  Future<bool> submitStep1() async {
    didSubmitStep1 = true;
    if (step1ShouldSucceed) {
      _set(_s.copyWith(currentStep: 1));
    }
    return step1ShouldSucceed;
  }

  @override
  Future<bool> submitStep2({bool skip = false}) async {
    if (skip) {
      didSkipStep2 = true;
    } else {
      didSubmitStep2 = true;
    }
    return step2ShouldSucceed;
  }

  // The fake doesn't need real db/repo wiring. The screen reads via the
  // provider and only calls method getters — interface-stubbed above.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container({_FakeOnboardingNotifier? fake}) {
  return ProviderContainer(
    overrides: [
      onboardingNotifierProvider.overrideWith(() => fake ?? _FakeOnboardingNotifier()),
    ],
  );
}

Widget _wrap(Widget child, {ProviderContainer? container}) {
  final c = container ?? _container();
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('home')),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('a) renders Step 1 title', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox()));
      await tester.pumpAndSettle();
      expect(find.text('Configurons ta boutique'), findsOneWidget);
    });

    testWidgets('b) Suivant disabled when fields empty — tap stays on Step 1',
        (tester) async {
      final fake = _FakeOnboardingNotifier();
      final c = _container(fake: fake);
      await tester.pumpWidget(_wrap(const SizedBox(), container: c));
      await tester.pumpAndSettle();
      // Try tapping the Suivant button while disabled.
      final suivant = find.text('Suivant');
      expect(suivant, findsOneWidget);
      await tester.tap(suivant);
      await tester.pumpAndSettle();
      expect(fake.didSubmitStep1, isFalse);
      expect(find.text('Configurons ta boutique'), findsOneWidget);
    });

    testWidgets('c) Step 1 advances to Step 2 when fields filled',
        (tester) async {
      final fake = _FakeOnboardingNotifier();
      final c = _container(fake: fake);
      await tester.pumpWidget(_wrap(const SizedBox(), container: c));
      await tester.pumpAndSettle();

      // Pre-fill state directly to avoid dropdown widget-test flakiness.
      fake._set(const OnboardingState(
        boutiqueName: 'Ma Boutique',
        boutiqueCategory: 'Vêtements',
        boutiqueCity: 'Tunis',
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Suivant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(fake.didSubmitStep1, isTrue);
      expect(find.text('Quel est ton objectif ce mois-ci ?'), findsOneWidget);
    });

    testWidgets('d) Step 2 "Plus tard" calls skip submit', (tester) async {
      final fake = _FakeOnboardingNotifier();
      final c = _container(fake: fake);
      await tester.pumpWidget(_wrap(const SizedBox(), container: c));
      await tester.pumpAndSettle();
      // Jump straight to step 2 via state.
      fake._set(const OnboardingState(
        currentStep: 1,
        boutiqueName: 'Ma Boutique',
        boutiqueCategory: 'Vêtements',
        boutiqueCity: 'Tunis',
      ));
      await tester.pumpAndSettle();
      // PageView is controlled by the state's page controller, which the
      // screen-side tracks via submitStep1 → animateToPage. Force navigate
      // by tapping Suivant (fake setStep1 returns true).
      await tester.ensureVisible(find.text('Suivant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Verify we're on Step 2.
      expect(find.text('Quel est ton objectif ce mois-ci ?'), findsOneWidget);
      await tester.ensureVisible(find.text('Plus tard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      expect(fake.didSkipStep2, isTrue);
    });

    testWidgets('e) goal kind toggle switches UI', (tester) async {
      final fake = _FakeOnboardingNotifier();
      final c = _container(fake: fake);
      await tester.pumpWidget(_wrap(const SizedBox(), container: c));
      await tester.pumpAndSettle();
      fake._set(const OnboardingState(
        boutiqueName: 'Ma Boutique',
        boutiqueCategory: 'Vêtements',
        boutiqueCity: 'Tunis',
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Suivant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Default is TRACKED.
      expect(find.text('Type de mesure'), findsOneWidget);
      expect(find.text('Décris ton objectif'), findsNothing);

      await tester.tap(find.text('Objectif personnel'));
      await tester.pumpAndSettle();

      expect(find.text('Décris ton objectif'), findsOneWidget);
      expect(find.text('Type de mesure'), findsNothing);
    });
  });
}
