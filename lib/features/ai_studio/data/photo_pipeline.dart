import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import '../domain/quality_thresholds.dart';
import 'quality_gate_result.dart';
import 'quality_gate_checker.dart';

class PhotoPipelineResult {
  const PhotoPipelineResult({
    required this.gateResult,
    required this.compressedBytes,
    required this.compressedSizeBytes,
  });

  final QualityGateResult gateResult;

  /// JPEG bytes ready to upload. Always set even if verdict is warn/block —
  /// caller decides whether to proceed based on verdict.
  final Uint8List compressedBytes;
  final int compressedSizeBytes;
}

abstract final class PhotoPipeline {
  PhotoPipeline._();

  /// Full pipeline for one photo file.
  ///
  /// Steps:
  ///   1. Read original file, measure size + resolution.
  ///   2. Compress to upload copy (1080px, JPEG 85).
  ///   3. Downscale upload copy further to 512px analysis copy.
  ///   4. Run quality gate in isolate on analysis copy.
  ///   5. Return [PhotoPipelineResult].
  ///
  /// Throws [PhotoPipelineException] on unrecoverable IO/decode errors.
  static Future<PhotoPipelineResult> process(String filePath) async {
    // ── 1. Read original ───────────────────────────────────
    final originalFile = File(filePath);
    final originalBytes = await originalFile.readAsBytes();
    final originalFileBytes = originalBytes.length;

    // Decode to measure dimensions. The image package does not expose a
    // header-only decoder in 4.x, so we decode fully then discard.
    final originalDecoded = img.decodeImage(originalBytes);
    if (originalDecoded == null) {
      throw const PhotoPipelineException('Could not read image dimensions.');
    }
    final shortestEdgePx = originalDecoded.width < originalDecoded.height
        ? originalDecoded.width
        : originalDecoded.height;

    // ── 2. Compress to upload copy ─────────────────────────
    // flutter_image_compress is native-backed (fast).
    // Resize to 1080px longest edge, JPEG 85.
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: QualityThresholds.uploadLongestEdgePx,
      minHeight: QualityThresholds.uploadLongestEdgePx,
      quality: QualityThresholds.uploadJpegQuality,
    );

    if (compressedBytes == null || compressedBytes.isEmpty) {
      throw const PhotoPipelineException('Image compression failed.');
    }

    // If still above upload limit after compression (rare — very large PNGs),
    // re-compress at lower quality. One retry only.
    Uint8List uploadBytes = Uint8List.fromList(compressedBytes);
    if (uploadBytes.length > QualityThresholds.maxCompressedBytes) {
      final recompressed = await FlutterImageCompress.compressWithList(
        uploadBytes,
        quality: 65,
      );
      uploadBytes = recompressed;
    }

    // ── 3. Downscale to 512px analysis copy ───────────────
    // Done in an isolate via compute to keep UI thread free.
    final analysisBytes = await compute(_downscaleForAnalysis, uploadBytes);

    // ── 4. Run quality gate ────────────────────────────────
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    final gateResult = await QualityGateChecker.analyze(
      analysisBytes: analysisBytes,
      originalFileBytes: originalFileBytes,
      shortestEdgePx: shortestEdgePx,
      platform: platform,
    );

    return PhotoPipelineResult(
      gateResult: gateResult,
      compressedBytes: uploadBytes,
      compressedSizeBytes: uploadBytes.length,
    );
  }

  /// Override the gate verdict after seller accepts a warning.
  /// Returns a new result with [QualityGateResult.overridden] = true.
  static PhotoPipelineResult override(PhotoPipelineResult result) {
    return PhotoPipelineResult(
      gateResult: result.gateResult.copyWith(overridden: true),
      compressedBytes: result.compressedBytes,
      compressedSizeBytes: result.compressedSizeBytes,
    );
  }
}

/// Top-level for compute(). Decodes and downscales to 512px longest edge.
Uint8List _downscaleForAnalysis(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final longestEdge = QualityThresholds.analysisLongestEdgePx;
  final scale = longestEdge / (decoded.width > decoded.height
      ? decoded.width.toDouble()
      : decoded.height.toDouble());

  if (scale >= 1.0) return bytes; // already smaller than 512px

  final resized = img.copyResize(
    decoded,
    width: (decoded.width * scale).round(),
    height: (decoded.height * scale).round(),
    interpolation: img.Interpolation.average,
  );

  return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
}

class PhotoPipelineException implements Exception {
  const PhotoPipelineException(this.message);
  final String message;
  @override
  String toString() => message;
}
