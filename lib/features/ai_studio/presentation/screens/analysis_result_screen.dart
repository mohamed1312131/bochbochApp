import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../domain/ai_studio_models.dart';
import 'captions_screen.dart';

class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({
    super.key,
    required this.result,
    required this.photoUrls,
    required this.sessionId,
  });

  final AiAnalysisResult result;
  final List<String> photoUrls;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: context.appTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'AI Analysis',
          style: AppTypography.h4.copyWith(color: context.appTextPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // ── Photo strip ──────────────────────────
                    if (photoUrls.isNotEmpty) _PhotoStrip(urls: photoUrls),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Confidence badge ─────────────────────
                    _ConfidenceBadge(confidence: result.confidence),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Low confidence warning ───────────────
                    if (result.isLowConfidence) ...[
                      _LowConfidenceWarning(onRetake: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ── Title suggestion ─────────────────────
                    _ResultSection(
                      label: 'Product name',
                      child: Text(
                        result.titleSuggestion.isEmpty
                            ? 'Could not determine'
                            : result.titleSuggestion,
                        style: AppTypography.h4.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Category + audience row ──────────────
                    Row(
                      children: [
                        Expanded(
                          child: _ResultSection(
                            label: 'Category',
                            child: _Chip(
                              label: _formatCategory(result.category),
                              color: context.appBrand,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ResultSection(
                            label: 'Audience',
                            child: _Chip(
                              label: _formatAudience(result.targetAudience),
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Colors ───────────────────────────────
                    _ResultSection(
                      label: 'Colors',
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (result.primaryColor.isNotEmpty)
                            _Chip(
                              label: result.primaryColor,
                              color: context.appBrand,
                              isPrimary: true,
                            ),
                          ...result.secondaryColors.map(
                            (c) => _Chip(
                              label: c,
                              color: context.appTextSecondary,
                            ),
                          ),
                          if (result.primaryColor.isEmpty &&
                              result.secondaryColors.isEmpty)
                            Text(
                              'Not detected',
                              style: AppTypography.body.copyWith(
                                color: context.appTextTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Materials ────────────────────────────
                    if (result.materials.isNotEmpty) ...[
                      _ResultSection(
                        label: 'Materials',
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: result.materials
                              .map((m) => _Chip(
                                    label: m,
                                    color: const Color(0xFFF59E0B),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ── Style tags ───────────────────────────
                    if (result.styleTags.isNotEmpty) ...[
                      _ResultSection(
                        label: 'Style',
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: result.styleTags
                              .map((t) => _Chip(
                                    label: t,
                                    color: const Color(0xFF22C55E),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ── Occasion tags ────────────────────────
                    if (result.occasionTags.isNotEmpty) ...[
                      _ResultSection(
                        label: 'Best for',
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: result.occasionTags
                              .map((t) => _Chip(
                                    label: t,
                                    color: const Color(0xFF3B82F6),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // ── Bottom CTAs ──────────────────────────────────
            _BottomActions(result: result, sessionId: sessionId),
          ],
        ),
      ),
    );
  }

  String _formatCategory(String raw) {
    if (raw.isEmpty) return 'Other';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _formatAudience(String raw) => switch (raw) {
        'women' => 'Women',
        'men' => 'Men',
        'unisex' => 'Unisex',
        'kids' => 'Kids',
        _ => 'General',
      };
}

// ── Bottom action bar ──────────────────────────────────────────

class _BottomActions extends ConsumerWidget {
  const _BottomActions({required this.result, required this.sessionId});
  final AiAnalysisResult result;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.buttonBottom,
      ),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhance — primary (Step 8, not yet built)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                // TODO(step8): navigate to enhance flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enhance coming in next step'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: const Text('Enhance photo ✨'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Skip to captions — secondary (Step 9, not yet built)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CaptionsScreen(
                      sessionId: sessionId,
                      analysisResult: result,
                    ),
                  ),
                );
              },
              child: Text(
                'Skip to captions',
                style: TextStyle(color: context.appTextSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        children: urls
            .map(
              (url) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    url,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});
  final String confidence;

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (confidence) {
      'high' => (
          AppColors.success,
          AppColors.successBg,
          'High confidence ✓',
        ),
      'medium' => (
          AppColors.warning,
          AppColors.warningBg,
          'Medium confidence',
        ),
      _ => (
          AppColors.error,
          AppColors.errorBg,
          'Low confidence — consider retaking',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LowConfidenceWarning extends StatelessWidget {
  const _LowConfidenceWarning({required this.onRetake});
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'The photo was unclear — results may be inaccurate. Try a sharper, well-lit photo.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onRetake,
            child: Text(
              'Retake',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.label.copyWith(
            color: context.appTextTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    this.isPrimary = false,
  });

  final String label;
  final Color color;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: isPrimary
            ? Border.all(color: color.withValues(alpha: 0.4))
            : null,
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
