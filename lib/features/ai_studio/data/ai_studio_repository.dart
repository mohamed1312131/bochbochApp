import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_handler.dart';
import '../domain/ai_studio_models.dart';
import 'quality_gate_result.dart';

class AiStudioRepository {
  Future<Dio> _getDio() async => (await DioClient.getInstance()).dio;

  // ── Session ───────────────────────────────────────────────

  /// Creates a new session or returns the existing ACTIVE one.
  /// Backend is idempotent — safe to call on every studio open.
  Future<AiSession> createOrGetSession({String? productId}) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.aiSessions,
        data: {
          if (productId != null) 'productId': productId,
        },
      );
      return AiSession.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> abandonSession(String sessionId) async {
    try {
      final dio = await _getDio();
      await dio.patch(
        ApiEndpoints.aiSessionAbandon(sessionId),
        data: <String, dynamic>{},
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Photos ────────────────────────────────────────────────

  /// Uploads a compressed photo to the session.
  /// [gateResult] is sent as the quality_gate_result field.
  /// Returns the created [AiSessionPhoto].
  Future<AiSessionPhoto> uploadPhoto({
    required String sessionId,
    required Uint8List compressedBytes,
    required QualityGateResult gateResult,
  }) async {
    try {
      final dio = await _getDio();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          compressedBytes,
          filename: 'photo.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
        'qualityGateResult': jsonEncode(gateResult.toJson()),
      });

      final response = await dio.post(
        ApiEndpoints.aiSessionPhotos(sessionId),
        data: formData,
      );

      return AiSessionPhoto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Analyze ───────────────────────────────────────────────

  /// Triggers Gemini analysis on all uploaded photos in the session.
  /// Quota-gated. Returns [AiAnalysisResult] with the 9 fields.
  /// Response headers X-AI-Quota-* are available but we read them
  /// from the provider state rather than here.
  Future<AiAnalysisResult> analyze(String sessionId) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.aiSessionAnalyze(sessionId),
        data: <String, dynamic>{},
      );
      return AiAnalysisResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Captions ──────────────────────────────────────────────

  /// Generates 5 caption variations using the session's prior analyze result.
  /// Quota-gated. Requires analyze to have been called first.
  Future<CaptionsResult> generateCaptions({
    required String sessionId,
    required String platform,
    required String language,
    required String intent,
    String? priceHint,
  }) async {
    try {
      final dio = await _getDio();
      final response = await dio.post(
        ApiEndpoints.aiSessionCaptions(sessionId),
        data: {
          'platform': platform,
          'language': language,
          'intent': intent,
          if (priceHint != null && priceHint.isNotEmpty) 'priceHint': priceHint,
        },
      );
      return CaptionsResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Quota ─────────────────────────────────────────────────

  /// Fetches current month quota state across all AI features.
  /// Used by AI Studio hub to display real usage counts.
  Future<AiQuotaStatus> getQuotaStatus() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/ai/quota-status');
      return AiQuotaStatus.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ── Session hydration ─────────────────────────────────────

  /// Fetches the full state of a session in one round trip:
  /// session metadata + all photos + latest analyze result (if any).
  /// Used on app wake / re-entry to restore UI without multiple calls.
  Future<AiSessionState> getSessionState(String sessionId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/ai/sessions/$sessionId/state');
      return AiSessionState.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
