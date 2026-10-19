abstract class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;

  /// Backend-provided machine code (e.g. `INVALID_CREDENTIALS`,
  /// `ACCOUNT_LOCKED`). Lets the UI branch on stable identifiers
  /// instead of fragile string-matching against localized messages.
  final String? code;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection'])
      : super(code: null);
}

class ServerException extends AppException {
  const ServerException({
    required this.statusCode,
    required String message,
    String? code,
  }) : super(message, code: code);
  final int statusCode;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Session expired',
    String? code,
  ]) : super(code: code);
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Resource not found',
    String? code,
  ]) : super(code: code);
}

class ValidationException extends AppException {
  const ValidationException({
    required String message,
    this.errors = const {},
    String? code,
  }) : super(message, code: code);

  /// Per-field validation errors from the backend (Zod / Fastify).
  /// Map of field name → list of messages. Empty when the backend
  /// didn't return field-level details.
  final Map<String, List<String>> errors;
}

class CacheException extends AppException {
  const CacheException([super.message = 'Local data error'])
      : super(code: null);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong'])
      : super(code: null);
}

// ── AI-specific exceptions ───────────────────────────────────────────
// Maps to the backend code taxonomy in AI_MODULE_BACKEND.md §11.
// UI branches on [code], not on HTTP status.

enum AiErrorCode {
  quotaExceeded,        // QUOTA_EXCEEDED (402)       — show upgrade CTA
  costCeilingExceeded,  // COST_CEILING_EXCEEDED (503) — show "try tomorrow"
  providerUnavailable,  // AI_PROVIDER_UNAVAILABLE (503) — show retry countdown
  providerError,        // AI_PROVIDER_ERROR (502)    — show retry
  parseError,           // AI_PARSE_ERROR (502)       — show retry
  storageUploadFailed,  // STORAGE_UPLOAD_FAILED (502) — show retry
  rateLimitExceeded,    // RATE_LIMIT_EXCEEDED (429)  — show countdown
  sessionNotFound,      // SESSION_NOT_FOUND (404)    — restart session
  inputRejected,        // INPUT_REJECTED (422)       — bad content
  suspended,            // SUSPENDED (402)            — account locked
  unknown,              // anything else
}

class AiException extends AppException {
  const AiException({
    required this.aiCode,
    required String message,
    this.retryAfterMs,
    this.resetAt,
  }) : super(message, code: null);

  final AiErrorCode aiCode;

  /// Set on RATE_LIMIT_EXCEEDED and PROVIDER_UNAVAILABLE.
  /// Flutter uses this for countdown timers.
  final int? retryAfterMs;

  /// Set on QUOTA_EXCEEDED — when the quota resets (ISO string).
  final String? resetAt;

  static AiErrorCode _codeFromString(String? raw) => switch (raw) {
        'QUOTA_EXCEEDED' => AiErrorCode.quotaExceeded,
        'COST_CEILING_EXCEEDED' => AiErrorCode.costCeilingExceeded,
        'AI_PROVIDER_UNAVAILABLE' => AiErrorCode.providerUnavailable,
        'AI_PROVIDER_ERROR' => AiErrorCode.providerError,
        'AI_PARSE_ERROR' => AiErrorCode.parseError,
        'STORAGE_UPLOAD_FAILED' => AiErrorCode.storageUploadFailed,
        'RATE_LIMIT_EXCEEDED' => AiErrorCode.rateLimitExceeded,
        'SESSION_NOT_FOUND' => AiErrorCode.sessionNotFound,
        'INPUT_REJECTED' => AiErrorCode.inputRejected,
        'SUSPENDED' => AiErrorCode.suspended,
        _ => AiErrorCode.unknown,
      };

  factory AiException.fromApiError({
    required String? code,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    return AiException(
      aiCode: _codeFromString(code),
      message: message,
      retryAfterMs: metadata?['retryAfterMs'] as int?,
      resetAt: metadata?['resetAt'] as String?,
    );
  }
}
