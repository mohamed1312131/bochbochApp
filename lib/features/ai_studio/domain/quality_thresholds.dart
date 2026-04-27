/// All quality gate tunable constants in one place.
/// Bump [gateVersion] whenever any threshold or algorithm changes.
/// Backend analytics use this to correlate override rates across versions.
abstract final class QualityThresholds {
  QualityThresholds._();

  /// Stored in quality_gate_result JSONB. Bump on any change.
  static const String gateVersion = 'v1';

  // ── Hard limits (block unconditionally) ─────────────────
  /// Shortest edge below this → block. Enhance pipeline degrades below 800px.
  static const int minShortestEdgePx = 800;

  /// Original file size above this → block.
  static const int maxOriginalBytes = 15 * 1024 * 1024; // 15 MB

  // ── Soft limits (warn, seller can override) ──────────────
  /// Shortest edge in [minShortestEdgePx, warnShortestEdgePx) → warn.
  static const int warnShortestEdgePx = 1200;

  /// Sharpness (0–1, Laplacian variance normalized).
  /// Below [blockSharpness] → block. In [blockSharpness, warnSharpness) → warn.
  static const double blockSharpness = 0.15;
  static const double warnSharpness = 0.40;

  /// Mean brightness (0–1). Too dark or blown-out is a warn, not a block —
  /// the seller may be photographing a dark product intentionally.
  static const double warnBrightnessLow = 0.12;
  static const double warnBrightnessHigh = 0.93;

  // ── Processing constants ─────────────────────────────────
  /// Longest edge for the Laplacian analysis copy. Sharpness is a
  /// low-frequency signal — resolution beyond this adds no information.
  static const int analysisLongestEdgePx = 512;

  /// Max file size after compression before upload. Backend hard limit is 2MB.
  /// We target 1.8MB to leave headroom for multipart overhead.
  static const int maxCompressedBytes = 1800 * 1024; // 1.8 MB

  /// Longest edge for the upload copy. Matches backend Cloudinary config.
  static const int uploadLongestEdgePx = 1080;

  /// JPEG quality for the upload copy.
  static const int uploadJpegQuality = 85;
}
