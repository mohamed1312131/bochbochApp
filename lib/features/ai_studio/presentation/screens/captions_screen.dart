import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../domain/ai_studio_models.dart';
import '../providers/ai_studio_provider.dart';

class CaptionsScreen extends ConsumerStatefulWidget {
  const CaptionsScreen({
    super.key,
    required this.sessionId,
    required this.analysisResult,
  });

  final String sessionId;
  final AiAnalysisResult analysisResult;

  @override
  ConsumerState<CaptionsScreen> createState() => _CaptionsScreenState();
}

class _CaptionsScreenState extends ConsumerState<CaptionsScreen> {
  String _selectedPlatform = 'INSTAGRAM';
  String _selectedLanguage = 'derja';
  final _intentController = TextEditingController();
  final _priceController = TextEditingController();
  bool _hasGenerated = false;

  final _platforms = ['INSTAGRAM', 'FACEBOOK', 'TIKTOK'];
  final _languages = ['derja', 'french', 'arabic_formal', 'english'];

  @override
  void dispose() {
    _intentController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _canGenerate => _intentController.text.trim().length >= 5;

  Future<void> _generate() async {
    final intent = _intentController.text.trim();
    if (intent.length < 5) return;

    FocusScope.of(context).unfocus();

    await ref.read(aiStudioProvider.notifier).generateCaptions(
          platform: _selectedPlatform,
          language: _selectedLanguage,
          intent: intent,
          priceHint: _priceController.text.trim().isEmpty
              ? null
              : _priceController.text.trim(),
        );
    if (mounted) {
      setState(() => _hasGenerated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiStudioProvider);
    final isLoading = state.status == AiStudioStatus.generatingCaptions;
    final captions = state.captionsResult;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: context.appTextPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AI Captions',
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

                    // ── Options (hidden after first successful generation) ──
                    if (!_hasGenerated || captions == null) ...[
                      _SectionLabel(label: 'What are you posting about?'),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tell the AI your goal — required',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.appTextTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _intentController,
                        maxLines: 2,
                        maxLength: 200,
                        onChanged: (_) => setState(() {}),
                        style: AppTypography.body
                            .copyWith(color: context.appTextPrimary),
                        decoration: _inputDecoration(
                          context,
                          hint: 'e.g. launching summer collection, 20% off this weekend...',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _SectionLabel(label: 'Platform'),
                      const SizedBox(height: AppSpacing.sm),
                      _SegmentedRow(
                        options: _platforms,
                        selected: _selectedPlatform,
                        labels: const {
                          'INSTAGRAM': 'Instagram',
                          'FACEBOOK': 'Facebook',
                          'TIKTOK': 'TikTok',
                        },
                        onSelect: (v) =>
                            setState(() => _selectedPlatform = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _SectionLabel(label: 'Language'),
                      const SizedBox(height: AppSpacing.sm),
                      _SegmentedRow(
                        options: _languages,
                        selected: _selectedLanguage,
                        labels: const {
                          'derja': 'Derja',
                          'french': 'French',
                          'arabic_formal': 'Arabic',
                          'english': 'English',
                        },
                        onSelect: (v) =>
                            setState(() => _selectedLanguage = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      _SectionLabel(label: 'Price hint (optional)'),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _priceController,
                        maxLength: 40,
                        style: AppTypography.body
                            .copyWith(color: context.appTextPrimary),
                        decoration: _inputDecoration(
                          context,
                          hint: 'e.g. 120 TND',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // ── Loading state ────────────────────────
                    if (isLoading) ...[
                      const SizedBox(height: AppSpacing.xxxl),
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: context.appBrand,
                              strokeWidth: 2.5,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Generating captions...',
                              style: AppTypography.body.copyWith(
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Error state ──────────────────────────
                    if (state.status == AiStudioStatus.error &&
                        state.error != null &&
                        !isLoading) ...[
                      _ErrorBanner(
                        message: state.error!,
                        onRetry: _generate,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ── Caption cards ────────────────────────
                    if (captions != null && !isLoading) ...[
                      Row(
                        children: [
                          Text(
                            '${captions.variations.length} variations',
                            style: AppTypography.h4.copyWith(
                              color: context.appTextPrimary,
                            ),
                          ),
                          if (captions.partial) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                'partial',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          TextButton(
                            onPressed: _generate,
                            child: Text(
                              'Regenerate',
                              style: AppTypography.bodySmall.copyWith(
                                color: context.appBrand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (captions.partial) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'AI returned fewer variations than usual. Tap Regenerate for a fresh try.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (captions.bestPostingTime != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 14,
                                color: context.appTextTertiary),
                            const SizedBox(width: 4),
                            Text(
                              'Best time: ${captions.bestPostingTime}',
                              style: AppTypography.bodySmall.copyWith(
                                color: context.appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      ...captions.variations.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md),
                              child: _CaptionCard(
                                variation: entry.value,
                                index: entry.key,
                              ),
                            ),
                          ),
                    ],

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA ───────────────────────────────────
            if (captions == null && !isLoading)
              _GenerateButton(
                onTap: _canGenerate ? _generate : null,
                label: _canGenerate
                    ? 'Generate captions'
                    : 'Describe your post first',
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTypography.body.copyWith(color: context.appTextTertiary),
      filled: true,
      fillColor: context.appSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: context.appBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: context.appBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: context.appBrand, width: 1.5),
      ),
      counterStyle:
          AppTypography.bodySmall.copyWith(color: context.appTextTertiary),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.label.copyWith(
        color: context.appTextTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final List<String> options;
  final String selected;
  final Map<String, String> labels;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: opt == options.last ? 0 : AppSpacing.xs,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.appBrand
                    : context.appSurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected
                      ? context.appBrand
                      : context.appBorder,
                ),
              ),
              child: Text(
                labels[opt] ?? opt,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected
                      ? Colors.white
                      : context.appTextSecondary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CaptionCard extends StatefulWidget {
  const _CaptionCard({required this.variation, required this.index});
  final CaptionVariation variation;
  final int index;

  @override
  State<_CaptionCard> createState() => _CaptionCardState();
}

class _CaptionCardState extends State<_CaptionCard> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(
        ClipboardData(text: widget.variation.fullText));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  String get _styleLabel => switch (widget.variation.style) {
        'casual_fun' => 'Casual & Fun',
        'professional' => 'Professional',
        'urgent_scarcity' => 'Urgent',
        'educational' => 'Educational',
        'story_based' => 'Story',
        _ => widget.variation.style,
      };

  Color get _styleColor => switch (widget.variation.style) {
        'casual_fun' => const Color(0xFF05687B),
        'professional' => const Color(0xFF3B82F6),
        'urgent_scarcity' => const Color(0xFFEF4444),
        'educational' => const Color(0xFF8B5CF6),
        'story_based' => const Color(0xFFF59E0B),
        _ => AppColors.brand,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _styleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    _styleLabel,
                    style: AppTypography.label.copyWith(
                      color: _styleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.index + 1}/5',
                  style: AppTypography.label.copyWith(
                    color: context.appTextTertiary,
                  ),
                ),
              ],
            ),
          ),

          // ── Caption text ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: Text(
              widget.variation.text,
              style: AppTypography.body.copyWith(
                color: context.appTextPrimary,
                height: 1.6,
              ),
            ),
          ),

          // ── Hashtags ──────────────────────────────────────
          if (widget.variation.hashtags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: Text(
                widget.variation.hashtags
                    .map((h) => '#$h')
                    .join(' '),
                style: AppTypography.bodySmall.copyWith(
                  color: context.appBrand,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // ── CTA chip ──────────────────────────────────────
          if (widget.variation.callToAction.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 14,
                    color: context.appTextTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.variation.callToAction,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.appTextSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Copy button ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _copy,
                icon: Icon(
                  _copied
                      ? Icons.check_rounded
                      : Icons.copy_rounded,
                  size: 16,
                  color: _copied
                      ? AppColors.success
                      : context.appTextSecondary,
                ),
                label: Text(
                  _copied ? 'Copied!' : 'Copy caption',
                  style: AppTypography.bodySmall.copyWith(
                    color: _copied
                        ? AppColors.success
                        : context.appTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _copied
                        ? AppColors.success
                        : context.appBorder,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onTap, required this.label});
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
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
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Something went wrong. Check your connection and try again.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
