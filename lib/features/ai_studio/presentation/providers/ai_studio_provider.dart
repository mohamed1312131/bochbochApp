import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/ai_studio_repository.dart';
import '../../data/photo_pipeline.dart';
import '../../data/quality_gate_result.dart';
import '../../domain/ai_studio_models.dart';

// ── Repository ─────────────────────────────────────────────
final aiStudioRepositoryProvider = Provider<AiStudioRepository>(
  (ref) => AiStudioRepository(),
);

// ── Session state ──────────────────────────────────────────
enum AiStudioStatus {
  idle,
  initializingSession,
  pickingPhoto,
  processingPhoto,  // compress + gate running
  gateWarning,      // verdict = warn, waiting for seller decision
  gateBlocked,      // verdict = block, must retake
  uploadingPhoto,
  ready,            // photos uploaded, can analyze
  analyzing,
  analyzed,
  generatingCaptions,
  captionsReady,
  error,
}

class AiStudioState {
  const AiStudioState({
    this.status = AiStudioStatus.idle,
    this.session,
    this.photos = const [],
    this.pendingPipelineResult,
    this.analysisResult,
    this.captionsResult,
    this.error,
    this.quotaRemaining,
  });

  final AiStudioStatus status;
  final AiSession? session;
  final List<AiSessionPhoto> photos;

  /// Set during [gateWarning] / [gateBlocked] states.
  /// Cleared after seller decides.
  final PhotoPipelineResult? pendingPipelineResult;

  final AiAnalysisResult? analysisResult;
  final CaptionsResult? captionsResult;
  final String? error;

  /// Populated from X-AI-Quota-Remaining response header after analyze.
  final int? quotaRemaining;

  bool get canAddMorePhotos => photos.length < 3;
  bool get canAnalyze =>
      photos.isNotEmpty &&
      session != null &&
      status == AiStudioStatus.ready;

  AiStudioState copyWith({
    AiStudioStatus? status,
    AiSession? session,
    List<AiSessionPhoto>? photos,
    PhotoPipelineResult? pendingPipelineResult,
    AiAnalysisResult? analysisResult,
    CaptionsResult? captionsResult,
    String? error,
    int? quotaRemaining,
    bool clearPending = false,
    bool clearError = false,
    bool clearAnalysis = false,
    bool clearCaptions = false,
  }) =>
      AiStudioState(
        status: status ?? this.status,
        session: session ?? this.session,
        photos: photos ?? this.photos,
        pendingPipelineResult: clearPending
            ? null
            : pendingPipelineResult ?? this.pendingPipelineResult,
        analysisResult: clearAnalysis
            ? null
            : analysisResult ?? this.analysisResult,
        captionsResult: clearCaptions
            ? null
            : captionsResult ?? this.captionsResult,
        error: clearError ? null : error ?? this.error,
        quotaRemaining: quotaRemaining ?? this.quotaRemaining,
      );
}

class AiStudioNotifier extends AutoDisposeNotifier<AiStudioState> {
  @override
  AiStudioState build() => const AiStudioState();

  AiStudioRepository get _repo => ref.read(aiStudioRepositoryProvider);

  // ── Session init ───────────────────────────────────────────

  Future<void> initSession({String? productId}) async {
    if (state.session != null) return; // already have one
    state = state.copyWith(status: AiStudioStatus.initializingSession);
    try {
      final session = await _repo.createOrGetSession(productId: productId);

      // Default landing state — hydration below may upgrade this.
      state = state.copyWith(
        status: AiStudioStatus.idle,
        session: session,
      );

      // Only ACTIVE sessions can be mid-workflow. Skip hydration for
      // anything else (COMPLETED/ABANDONED/EXPIRED won't reach here via
      // createOrGetSession, but guard anyway).
      if (session.status != 'ACTIVE') return;

      // Rehydrate from backend — photos + latest analysis in one round
      // trip. Silent fallback to idle on failure: a broken hydration call
      // must never block the user from entering the hub.
      try {
        final hydrated = await _repo.getSessionState(session.id);

        final AiStudioStatus nextStatus;
        if (hydrated.latestAnalysis != null) {
          nextStatus = AiStudioStatus.analyzed;
        } else if (hydrated.photos.isNotEmpty) {
          nextStatus = AiStudioStatus.ready;
        } else {
          nextStatus = AiStudioStatus.idle;
        }

        state = state.copyWith(
          status: nextStatus,
          photos: hydrated.photos,
          analysisResult: hydrated.latestAnalysis,
        );
      } catch (_) {
        // Silent — state already has session + idle status from above.
      }
    } catch (e) {
      state = state.copyWith(
        status: AiStudioStatus.error,
        error: e.toString(),
      );
    }
  }

  // ── Photo pick + pipeline ──────────────────────────────────

  Future<void> pickAndProcessPhoto(XFile file) async {
    if (!state.canAddMorePhotos) return;

    state = state.copyWith(status: AiStudioStatus.processingPhoto);

    try {
      final result = await PhotoPipeline.process(file.path);

      switch (result.gateResult.verdict) {
        case QualityVerdict.pass:
          // Gate cleared — upload immediately.
          await _upload(result);

        case QualityVerdict.warn:
          // Surface warning sheet — UI listens and shows the sheet.
          state = state.copyWith(
            status: AiStudioStatus.gateWarning,
            pendingPipelineResult: result,
          );

        case QualityVerdict.block:
          state = state.copyWith(
            status: AiStudioStatus.gateBlocked,
            pendingPipelineResult: result,
          );
      }
    } catch (e) {
      state = state.copyWith(
        status: AiStudioStatus.error,
        error: 'Could not process photo: ${e.toString()}',
        clearError: false,
      );
    }
  }

  /// Called when seller taps "Use anyway" on a warning.
  Future<void> overrideAndUpload() async {
    final pending = state.pendingPipelineResult;
    if (pending == null) return;
    final overridden = PhotoPipeline.override(pending);
    await _upload(overridden);
  }

  /// Called when seller taps "Retake photo".
  void resetToIdle() {
    state = state.copyWith(
      status: state.photos.isEmpty
          ? AiStudioStatus.idle
          : AiStudioStatus.ready,
      clearPending: true,
      clearError: true,
    );
  }

  Future<void> _upload(PhotoPipelineResult pipeline) async {
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(
      status: AiStudioStatus.uploadingPhoto,
      clearPending: true,
    );

    try {
      final photo = await _repo.uploadPhoto(
        sessionId: session.id,
        compressedBytes: pipeline.compressedBytes,
        gateResult: pipeline.gateResult,
      );
      state = state.copyWith(
        status: AiStudioStatus.ready,
        photos: [...state.photos, photo],
      );
    } catch (e) {
      state = state.copyWith(
        status: AiStudioStatus.error,
        error: e.toString(),
      );
    }
  }

  // ── Analyze ────────────────────────────────────────────────

  Future<void> analyze() async {
    final session = state.session;
    if (session == null || !state.canAnalyze) return;

    state = state.copyWith(status: AiStudioStatus.analyzing);

    try {
      final result = await _repo.analyze(session.id);
      state = state.copyWith(
        status: AiStudioStatus.analyzed,
        analysisResult: result,
      );
    } catch (e) {
      // Surface AiException codes to the UI via the error string for now.
      // Step 7 will branch on AiErrorCode directly.
      state = state.copyWith(
        status: AiStudioStatus.error,
        error: e.toString(),
      );
    }
  }

  // ── Abandon ────────────────────────────────────────────────

  /// Abandon the current session. ONLY call from an explicit user action
  /// (e.g. a "Start over" menu item with a confirm dialog). Never wire
  /// this to back buttons, dispose, or error handlers — losing a session
  /// burns a paid analyze generation the user did not agree to discard.
  Future<void> abandonExplicitly() async {
    final session = state.session;
    if (session == null) return;
    try {
      await _repo.abandonSession(session.id);
    } catch (_) {
      // Best-effort. Don't block navigation.
    }
  }

  // ── Captions ────────────────────────────────────────────────

  Future<void> generateCaptions({
    required String platform,
    required String language,
    required String intent,
    String? priceHint,
  }) async {
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(
      status: AiStudioStatus.generatingCaptions,
      clearError: true,
    );

    try {
      final result = await _repo.generateCaptions(
        sessionId: session.id,
        platform: platform,
        language: language,
        intent: intent,
        priceHint: priceHint,
      );
      state = state.copyWith(
        status: AiStudioStatus.captionsReady,
        captionsResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: AiStudioStatus.error,
        error: e.toString(),
      );
    }
  }
}

final aiStudioProvider =
    NotifierProvider.autoDispose<AiStudioNotifier, AiStudioState>(
  AiStudioNotifier.new,
);

// ── Quota status provider ───────────────────────────────────
// Separate from the session-scoped AiStudioNotifier because quota is
// user-scoped and should survive session lifecycle.
final aiQuotaStatusProvider = FutureProvider.autoDispose<AiQuotaStatus>(
  (ref) async {
    final repo = ref.read(aiStudioRepositoryProvider);
    return repo.getQuotaStatus();
  },
);
