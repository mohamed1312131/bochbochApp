/// Domain types for the Bulk Actions flow (Feature 13).
library;

class BulkActionRow {
  const BulkActionRow({
    required this.orderId,
    required this.ok,
    this.error,
  });

  final String orderId;
  final bool ok;
  final String? error;

  factory BulkActionRow.fromJson(Map<String, dynamic> json) => BulkActionRow(
        orderId: json['orderId'] as String,
        ok: json['ok'] as bool? ?? false,
        error: json['error'] as String?,
      );
}

class BulkActionResult {
  const BulkActionResult({
    required this.updated,
    required this.results,
  });

  final int updated;
  final List<BulkActionRow> results;

  /// All rows succeeded. Caller can simplify the success snackbar.
  bool get allOk => results.every((r) => r.ok);

  /// Rows where the write phase rejected the order. Empty when the
  /// pre-validate phase passed and every order was written.
  List<BulkActionRow> get failures =>
      results.where((r) => !r.ok).toList(growable: false);

  factory BulkActionResult.fromJson(Map<String, dynamic> json) =>
      BulkActionResult(
        updated: (json['updated'] as num?)?.toInt() ?? 0,
        results: (json['results'] as List<dynamic>? ?? const [])
            .map((e) => BulkActionRow.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}
