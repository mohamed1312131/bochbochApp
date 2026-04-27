abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class ServerException extends AppException {
  const ServerException({required this.statusCode, required String message})
      : super(message);
  final int statusCode;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found']);
}

class ValidationException extends AppException {
  const ValidationException({
    required String message,
    this.errors = const {},
  }) : super(message);
  final Map<String, List<String>> errors;
}

class CacheException extends AppException {
  const CacheException([super.message = 'Local data error']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong']);
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
    required this.code,
    required String message,
    this.retryAfterMs,
    this.resetAt,
  }) : super(message);

  final AiErrorCode code;

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
      code: _codeFromString(code),
      message: message,
      retryAfterMs: metadata?['retryAfterMs'] as int?,
      resetAt: metadata?['resetAt'] as String?,
    );
  }
}
