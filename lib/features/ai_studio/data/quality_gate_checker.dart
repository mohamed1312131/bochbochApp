import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../domain/quality_thresholds.dart';
import 'quality_gate_result.dart';

/// Parameters passed into the isolate. Must be sendable (no BuildContext etc).
class QualityCheckParams {
  const QualityCheckParams({
    required this.bytes,
    required this.originalFileBytes,
    required this.shortestEdgePx,
    required this.platform,
  });
  final Uint8List bytes;         // already-downscaled image bytes for analysis
  final int originalFileBytes;
  final int shortestEdgePx;     // from the original image
  final String platform;
}

/// Top-level function so compute() can serialize it.
/// Called only from [QualityGateChecker.analyze] via compute().
QualityGateResult runGateInIsolate(QualityCheckParams p) {
  // ── 1. Hard checks (no pixel decode needed) ────────────
  final hardReasons = <QualityReason>[];

  if (p.originalFileBytes > QualityThresholds.maxOriginalBytes) {
    hardReasons.add(QualityReason.fileTooLarge);
  }
  if (p.shortestEdgePx < QualityThresholds.minShortestEdgePx) {
    hardReasons.add(QualityReason.lowResolution);
  }

  if (hardReasons.isNotEmpty) {
    return QualityGateResult(
      gateVersion: QualityThresholds.gateVersion,
      platform: p.platform,
      verdict: QualityVerdict.block,
      scores: QualityScores(
        sharpness: 0,
        brightness: 0,
        shortestEdgePx: p.shortestEdgePx,
        originalBytes: p.originalFileBytes,
      ),
      reasons: hardReasons,
      overridden: false,
    );
  }

  // ── 2. Decode the already-downscaled copy ───────────────
  final decoded = img.decodeImage(p.bytes);
  if (decoded == null) {
    // Corrupt image — treat as hard block.
    return QualityGateResult(
      gateVersion: QualityThresholds.gateVersion,
      platform: p.platform,
      verdict: QualityVerdict.block,
      scores: QualityScores(
        sharpness: 0,
        brightness: 0,
        shortestEdgePx: p.shortestEdgePx,
        originalBytes: p.originalFileBytes,
      ),
      reasons: [QualityReason.blurry],
      overridden: false,
    );
  }

  // ── 3. Convert to grayscale ────────────────────────────
  final gray = img.grayscale(decoded);
  final width = gray.width;
  final height = gray.height;

  // ── 4. Laplacian variance (sharpness) ──────────────────
  // Kernel: [0,1,0, 1,-4,1, 0,1,0]
  // Applied to center 60% of the frame to reduce flat-background bias.
  final xStart = (width * 0.2).round();
  final xEnd = (width * 0.8).round();
  final yStart = (height * 0.2).round();
  final yEnd = (height * 0.8).round();

  double sum = 0;
  double sumSq = 0;
  int count = 0;

  for (var y = yStart + 1; y < yEnd - 1; y++) {
    for (var x = xStart + 1; x < xEnd - 1; x++) {
      final center = gray.getPixel(x, y).r.toDouble();
      final top    = gray.getPixel(x, y - 1).r.toDouble();
      final bottom = gray.getPixel(x, y + 1).r.toDouble();
      final left   = gray.getPixel(x - 1, y).r.toDouble();
      final right  = gray.getPixel(x + 1, y).r.toDouble();

      final lap = (top + bottom + left + right) - 4 * center;
      sum += lap;
      sumSq += lap * lap;
      count++;
    }
  }

  final mean = count > 0 ? sum / count : 0.0;
  final variance = count > 0 ? (sumSq / count) - (mean * mean) : 0.0;

  // Normalize variance to 0–1. Cap at 2000 — typical sharp photos
  // land in the 200–800 range on a 512px downscale.
  final sharpness = (variance / 2000).clamp(0.0, 1.0);

  // ── 5. Mean brightness ─────────────────────────────────
  double brightnessSum = 0;
  int brightnessCount = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      brightnessSum += gray.getPixel(x, y).r.toDouble();
      brightnessCount++;
    }
  }
  // Pixel values are 0–255; normalize to 0–1.
  final brightness =
      brightnessCount > 0 ? (brightnessSum / brightnessCount) / 255.0 : 0.5;

  // ── 6. Composite decision tree ─────────────────────────
  final softReasons = <QualityReason>[];

  if (sharpness < QualityThresholds.blockSharpness) {
    softReasons.add(QualityReason.blurry);
  }
  if (brightness < QualityThresholds.warnBrightnessLow) {
    softReasons.add(QualityReason.tooDark);
  }
  if (brightness > QualityThresholds.warnBrightnessHigh) {
    softReasons.add(QualityReason.toooBright);
  }
  if (p.shortestEdgePx < QualityThresholds.warnShortestEdgePx) {
    softReasons.add(QualityReason.lowResolution);
  }

  // Blurry below blockSharpness = block. All other soft reasons = warn.
  final hasBlock = softReasons.contains(QualityReason.blurry) &&
      sharpness < QualityThresholds.blockSharpness;
  final verdict = hasBlock
      ? QualityVerdict.block
      : softReasons.isNotEmpty
          ? QualityVerdict.warn
          : QualityVerdict.pass;

  // For a pure warn (not block), blurry is only added if below warnSharpness.
  final finalReasons = softReasons.where((r) {
    if (r == QualityReason.blurry) {
      return sharpness < QualityThresholds.warnSharpness;
    }
    return true;
  }).toList();

  return QualityGateResult(
    gateVersion: QualityThresholds.gateVersion,
    platform: p.platform,
    verdict: verdict,
    scores: QualityScores(
      sharpness: sharpness,
      brightness: brightness,
      shortestEdgePx: p.shortestEdgePx,
      originalBytes: p.originalFileBytes,
    ),
    reasons: finalReasons,
    overridden: false,
  );
}

/// Public API. Stateless. Call from the provider, not from UI directly.
abstract final class QualityGateChecker {
  QualityGateChecker._();

  /// Analyzes [analysisBytes] (a downscaled copy) against [originalFileBytes]
  /// and [shortestEdgePx] (from the original image).
  ///
  /// Runs in an isolate via [compute] — safe to call from UI thread.
  static Future<QualityGateResult> analyze({
    required Uint8List analysisBytes,
    required int originalFileBytes,
    required int shortestEdgePx,
    required String platform,
  }) async {
    // compute() spins an isolate. The function must be top-level.
    return compute(
      runGateInIsolate,
      QualityCheckParams(
        bytes: analysisBytes,
        originalFileBytes: originalFileBytes,
        shortestEdgePx: shortestEdgePx,
        platform: platform,
      ),
    );
  }
}
