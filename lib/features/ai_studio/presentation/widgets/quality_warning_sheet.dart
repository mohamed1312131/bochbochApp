import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../data/quality_gate_result.dart';

/// Bottom sheet shown when the quality gate returns [QualityVerdict.warn]
/// or [QualityVerdict.block].
///
/// For [warn]: shows "Use anyway" and "Retake photo" options.
/// For [block]: shows "Retake photo" only — no override path.
///
/// Returns [QualitySheetAction] via Navigator.pop.
enum QualitySheetAction { retake, useAnyway }

class QualityWarningSheet extends StatelessWidget {
  const QualityWarningSheet({super.key, required this.result});

  final QualityGateResult result;

  static Future<QualitySheetAction?> show(
    BuildContext context,
    QualityGateResult result,
  ) {
    return showModalBottomSheet<QualitySheetAction>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (_) => QualityWarningSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBlock = result.verdict == QualityVerdict.block;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ─────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Icon + title ─────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isBlock
                        ? AppColors.errorBg
                        : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    isBlock
                        ? Icons.block_rounded
                        : Icons.warning_amber_rounded,
                    color: isBlock ? AppColors.error : AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    isBlock
                        ? 'Photo not usable'
                        : 'Photo quality is low',
                    style: AppTypography.h4.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Reason list ──────────────────────────────────
            ...result.reasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: context.appTextSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _reasonText(r),
                        style: AppTypography.body.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── CTAs ─────────────────────────────────────────
            if (!isBlock) ...[
              // Warn: two options
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, QualitySheetAction.retake),
                  child: const Text('Retake photo'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, QualitySheetAction.useAnyway),
                  child: Text(
                    'Use anyway',
                    style: TextStyle(color: context.appTextSecondary),
                  ),
                ),
              ),
            ] else ...[
              // Block: retake only
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, QualitySheetAction.retake),
                  child: const Text('Retake photo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _reasonText(QualityReason reason) => switch (reason) {
        QualityReason.blurry =>
          'The photo is too blurry. Hold the phone steady and tap the product to focus.',
        QualityReason.tooDark =>
          'The photo is too dark. Move to a brighter spot or turn on a light.',
        QualityReason.toooBright =>
          'The photo is overexposed. Avoid direct sunlight or strong backlighting.',
        QualityReason.lowResolution =>
          'The photo resolution is too low. Try zooming out and shooting closer.',
        QualityReason.fileTooLarge =>
          'The file is too large to process. Try a standard photo instead.',
      };
}
