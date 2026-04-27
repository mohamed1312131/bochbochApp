class ApiError {
  const ApiError({
    required this.message,
    this.code,
    this.errors,
    this.metadata,
  });

  final String message;
  final String? code;
  final Map<String, List<String>>? errors;

  /// Free-form server metadata (retryAfterMs, resetAt, etc.).
  /// Used by AiException to surface countdown timers and reset dates.
  final Map<String, dynamic>? metadata;

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        message: json['message'] as String? ?? 'Something went wrong',
        code: json['code'] as String?,
        errors: (json['errors'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        ),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}
