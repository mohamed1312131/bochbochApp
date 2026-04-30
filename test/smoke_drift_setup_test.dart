import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dido/core/db/app_database.dart';

void main() {
  group('AppDatabase smoke', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('upsert and read draft', () async {
      await db.upsertDraft(OnboardingDraftsCompanion.insert(
        userId: 'test-user-1',
        currentStep: const Value(1),
        updatedAt: DateTime.now(),
      ));

      final draft = await db.getDraftForUser('test-user-1');
      expect(draft, isNotNull);
      expect(draft!.userId, 'test-user-1');
      expect(draft.currentStep, 1);
    });

    test('upsert overwrites existing draft', () async {
      await db.upsertDraft(OnboardingDraftsCompanion.insert(
        userId: 'test-user-2',
        currentStep: const Value(1),
        updatedAt: DateTime.now(),
      ));
      await db.upsertDraft(OnboardingDraftsCompanion.insert(
        userId: 'test-user-2',
        boutiqueName: const Value('Test Boutique'),
        currentStep: const Value(2),
        updatedAt: DateTime.now(),
      ));

      final draft = await db.getDraftForUser('test-user-2');
      expect(draft!.boutiqueName, 'Test Boutique');
      expect(draft.currentStep, 2);
    });

    test('delete removes draft', () async {
      await db.upsertDraft(OnboardingDraftsCompanion.insert(
        userId: 'test-user-3',
        currentStep: const Value(1),
        updatedAt: DateTime.now(),
      ));
      await db.deleteDraftForUser('test-user-3');

      final draft = await db.getDraftForUser('test-user-3');
      expect(draft, isNull);
    });
  });
}
