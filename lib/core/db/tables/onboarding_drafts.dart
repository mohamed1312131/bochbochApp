import 'package:drift/drift.dart';

@DataClassName('OnboardingDraftRow')
class OnboardingDrafts extends Table {
  // Singleton row pattern — one draft per user per device.
  // userId is the primary key so we never accumulate stale drafts.
  TextColumn get userId => text()();

  // Step 1 fields (boutique setup)
  TextColumn get boutiqueName => text().nullable()();
  TextColumn get boutiqueCategory => text().nullable()();
  TextColumn get boutiqueCity => text().nullable()();
  TextColumn get boutiqueLogoUrl => text().nullable()();
  TextColumn get boutiqueBrandColor => text().nullable()();

  // Step 2 fields (first goal)
  TextColumn get goalKind => text().nullable()();      // TRACKED | SELF_REPORT
  TextColumn get goalType => text().nullable()();      // REVENUE|PROFIT|ORDERS|NEW_CUSTOMERS (nullable for self-report)
  TextColumn get goalLabel => text().nullable()();     // free-text for self-report
  IntColumn  get goalTargetValue => integer().nullable()();

  // Progress tracking
  IntColumn   get currentStep => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
