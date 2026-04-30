import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/observability/posthog_service.dart';
import '../../boutiques/data/boutique_repository.dart';
import '../../boutiques/domain/boutique_patch_input.dart';
import '../../boutiques/presentation/boutique_providers.dart';
import '../../goals/data/goal_repository.dart';
import '../../goals/domain/goal_models.dart';
import '../../goals/presentation/goal_providers.dart';

part 'onboarding_notifier.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default('') String boutiqueName,
    String? boutiqueCategory,
    String? boutiqueCity,
    String? logoUrl,
    String? brandColor,
    @Default('TRACKED') String goalKind,
    @Default('REVENUE') String goalType,
    int? goalTargetValue,
    String? goalLabel,
    @Default(false) bool isLoading,
    @Default(false) bool isUploadingLogo,
    String? errorMessage,
  }) = _OnboardingState;
}

const _userIdKey = 'onboarding_user_id';
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class OnboardingNotifier extends AutoDisposeAsyncNotifier<OnboardingState> {
  late final AppDatabase _db;
  late final BoutiqueRepository _boutiqueRepo;
  late final GoalRepository _goalRepo;

  @override
  Future<OnboardingState> build() async {
    _db = ref.watch(appDatabaseProvider);
    _boutiqueRepo = ref.watch(boutiqueRepositoryProvider);
    _goalRepo = ref.watch(goalRepositoryProvider);

    final userId = await _resolveUserId();
    if (userId == null) {
      return const OnboardingState();
    }
    final draft = await _db.getDraftForUser(userId);
    if (draft == null) {
      return const OnboardingState();
    }
    return OnboardingState(
      currentStep: (draft.currentStep - 1).clamp(0, 1),
      boutiqueName: draft.boutiqueName ?? '',
      boutiqueCategory: draft.boutiqueCategory,
      boutiqueCity: draft.boutiqueCity,
      logoUrl: draft.boutiqueLogoUrl,
      brandColor: draft.boutiqueBrandColor,
      goalKind: draft.goalKind ?? 'TRACKED',
      goalType: draft.goalType ?? 'REVENUE',
      goalTargetValue: draft.goalTargetValue,
      goalLabel: draft.goalLabel,
    );
  }

  Future<String?> _resolveUserId() async {
    return _secureStorage.read(key: _userIdKey);
  }

  void _update(OnboardingState Function(OnboardingState s) f) {
    final current = state.valueOrNull ?? const OnboardingState();
    state = AsyncData(f(current));
  }

  void setBoutiqueName(String v) =>
      _update((s) => s.copyWith(boutiqueName: v, errorMessage: null));
  void setBoutiqueCategory(String v) =>
      _update((s) => s.copyWith(boutiqueCategory: v, errorMessage: null));
  void setBoutiqueCity(String v) =>
      _update((s) => s.copyWith(boutiqueCity: v, errorMessage: null));
  void setBrandColor(String? v) =>
      _update((s) => s.copyWith(brandColor: v, errorMessage: null));

  void setGoalKind(String v) =>
      _update((s) => s.copyWith(goalKind: v, errorMessage: null));
  void setGoalType(String v) =>
      _update((s) => s.copyWith(goalType: v, errorMessage: null));
  void setGoalTargetValue(int? v) =>
      _update((s) => s.copyWith(goalTargetValue: v, errorMessage: null));
  void setGoalLabel(String? v) =>
      _update((s) => s.copyWith(goalLabel: v, errorMessage: null));

  Future<void> uploadLogo(XFile file) async {
    _update((s) => s.copyWith(isUploadingLogo: true, errorMessage: null));
    try {
      final url = await _boutiqueRepo.uploadLogo(file);
      _update((s) => s.copyWith(logoUrl: url, isUploadingLogo: false));
    } catch (e) {
      _update((s) => s.copyWith(
            isUploadingLogo: false,
            errorMessage: 'Logo upload failed',
          ));
    }
  }

  Future<void> saveDraft() async {
    final userId = await _resolveUserId();
    if (userId == null) return;
    final s = state.valueOrNull;
    if (s == null) return;
    await _db.upsertDraft(
      OnboardingDraftsCompanion.insert(
        userId: userId,
        boutiqueName: Value(s.boutiqueName),
        boutiqueCategory: Value(s.boutiqueCategory),
        boutiqueCity: Value(s.boutiqueCity),
        boutiqueLogoUrl: Value(s.logoUrl),
        boutiqueBrandColor: Value(s.brandColor),
        goalKind: Value(s.goalKind),
        goalType: Value(s.goalType),
        goalLabel: Value(s.goalLabel),
        goalTargetValue: Value(s.goalTargetValue),
        currentStep: Value(s.currentStep + 1),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> submitStep1() async {
    final s = state.valueOrNull ?? const OnboardingState();
    if (s.boutiqueName.trim().isEmpty ||
        s.boutiqueCategory == null ||
        s.boutiqueCity == null) {
      _update((s) => s.copyWith(errorMessage: 'Tous les champs requis'));
      return false;
    }
    _update((s) => s.copyWith(isLoading: true, errorMessage: null));
    try {
      await _boutiqueRepo.update(
        BoutiquePatchInput(
          name: s.boutiqueName.trim(),
          category: s.boutiqueCategory,
          city: s.boutiqueCity,
          brandColor: s.brandColor,
        ),
      );
      ref.invalidate(currentBoutiqueProvider);
      _update((s) => s.copyWith(isLoading: false, currentStep: 1));
      await saveDraft();
      return true;
    } catch (e) {
      _update((s) => s.copyWith(
            isLoading: false,
            errorMessage: 'Échec de la mise à jour',
          ));
      return false;
    }
  }

  Future<bool> submitStep2({bool skip = false}) async {
    final s = state.valueOrNull ?? const OnboardingState();
    _update((s) => s.copyWith(isLoading: true, errorMessage: null));
    try {
      if (!skip) {
        if (s.goalKind == 'TRACKED') {
          if (s.goalTargetValue == null || s.goalTargetValue! <= 0) {
            _update((s) => s.copyWith(
                  isLoading: false,
                  errorMessage: 'Cible requise',
                ));
            return false;
          }
          await _goalRepo.createGoal(CreateGoalInput(
            kind: 'TRACKED',
            goalType: s.goalType,
            targetValue: s.goalTargetValue,
          ));
        } else {
          if (s.goalLabel == null || s.goalLabel!.trim().isEmpty) {
            _update((s) => s.copyWith(
                  isLoading: false,
                  errorMessage: 'Objectif requis',
                ));
            return false;
          }
          await _goalRepo.createGoal(CreateGoalInput(
            kind: 'SELF_REPORT',
            label: s.goalLabel!.trim(),
            targetValue: s.goalTargetValue,
          ));
        }
        PostHogService.capture('onboarding_step_2_complete', properties: {
          'goal_kind': s.goalKind,
          'goal_type': s.goalType,
        });
      } else {
        PostHogService.capture('onboarding_step_2_skipped');
      }

      // Best-effort cleanup; never block onboarding on draft delete failures.
      final userId = await _resolveUserId();
      if (userId != null) {
        try {
          await _db.deleteDraftForUser(userId);
        } catch (_) {}
      }
      ref.invalidate(currentBoutiqueProvider);
      ref.invalidate(activeGoalProvider);
      _update((s) => s.copyWith(isLoading: false));
      return true;
    } catch (e) {
      _update((s) => s.copyWith(
            isLoading: false,
            errorMessage: 'Échec — réessaie',
          ));
      return false;
    }
  }
}

final onboardingNotifierProvider =
    AsyncNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
