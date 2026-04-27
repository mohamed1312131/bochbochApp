class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.hasMore,
    this.nextCursor,
    this.total,
  });

  final List<T> data;
  final bool hasMore;
  final String? nextCursor;
  final int? total;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      PaginatedResponse(
        data: (json['data'] as List).map((e) => fromJson(e)).toList(),
        hasMore: json['hasMore'] as bool? ?? false,
        nextCursor: json['nextCursor'] as String?,
        total: json['total'] as int?,
      );
}