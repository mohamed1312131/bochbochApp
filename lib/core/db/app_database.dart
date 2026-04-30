import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/onboarding_drafts.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [OnboardingDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  Future<OnboardingDraftRow?> getDraftForUser(String userId) {
    return (select(onboardingDrafts)..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<void> upsertDraft(OnboardingDraftsCompanion draft) {
    return into(onboardingDrafts).insertOnConflictUpdate(draft);
  }

  Future<void> deleteDraftForUser(String userId) {
    return (delete(onboardingDrafts)..where((t) => t.userId.equals(userId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dido_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
