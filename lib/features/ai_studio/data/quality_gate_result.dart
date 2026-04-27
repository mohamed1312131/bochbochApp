/// The result of the client-side photo quality gate.
///
/// Shape matches the backend [quality_gate_result] JSONB column in
/// ai_session_photos (AI_MODULE_BACKEND.md §3.2). Any change here
/// must bump [QualityThresholds.gateVersion].
class QualityGateResult {
  const QualityGateResult({
    required this.gateVersion,
    required this.platform,
    required this.verdict,
    required this.scores,
    required this.reasons,
    required this.overridden,
  });

  final String gateVersion;
  final String platform; // 'ios' | 'android'
  final QualityVerdict verdict;
  final QualityScores scores;
  final List<QualityReason> reasons;

  /// True when seller tapped "Use anyway" on a [QualityVerdict.warn].
  /// Set to true by [PhotoPipeline] after seller confirms override.
  final bool overridden;

  QualityGateResult copyWith({bool? overridden}) => QualityGateResult(
        gateVersion: gateVersion,
        platform: platform,
        verdict: verdict,
        scores: scores,
        reasons: reasons,
        overridden: overridden ?? this.overridden,
      );

  Map<String, dynamic> toJson() => {
        'gate_version': gateVersion,
        'platform': platform,
        'verdict': verdict.name,
        'scores': scores.toJson(),
        'reasons': reasons.map((r) => r.name).toList(),
        'overridden': overridden,
      };
}

enum QualityVerdict {
  pass,  // gate cleared — upload immediately
  warn,  // marginal — show warning, allow override
  block, // hard failure — must retake
}

enum QualityReason {
  blurry,          // sharpness below threshold
  tooDark,         // mean brightness too low
  toooBright,      // mean brightness too high (blown out)
  lowResolution,   // shortest edge below minimum
  fileTooLarge,    // original file exceeds hard limit
}

class QualityScores {
  const QualityScores({
    required this.sharpness,
    required this.brightness,
    required this.shortestEdgePx,
    required this.originalBytes,
  });

  /// Normalized Laplacian variance, 0–1. Higher = sharper.
  final double sharpness;

  /// Mean pixel brightness, 0–1.
  final double brightness;

  /// Shortest edge of the original image in pixels.
  final int shortestEdgePx;

  /// Original file size in bytes before compression.
  final int originalBytes;

  Map<String, dynamic> toJson() => {
        'sharpness': sharpness,
        'brightness': brightness,
        'shortest_edge_px': shortestEdgePx,
        'original_bytes': originalBytes,
      };
}
