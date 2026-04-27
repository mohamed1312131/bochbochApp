import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../domain/ai_studio_models.dart';
import '../providers/ai_studio_provider.dart';
import 'analysis_result_screen.dart';

class AiStudioHubScreen extends ConsumerStatefulWidget {
  const AiStudioHubScreen({super.key});

  @override
  ConsumerState<AiStudioHubScreen> createState() => _AiStudioHubScreenState();
}

class _AiStudioHubScreenState extends ConsumerState<AiStudioHubScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off session hydration. Notifier is idempotent — no-op if a
    // session is already loaded. Silent on hydration failure.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiStudioProvider.notifier).initSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quotaAsync = ref.watch(aiQuotaStatusProvider);
    final studioState = ref.watch(aiStudioProvider);
    final captions = quotaAsync.asData?.value.captions;
    final resetsAt = quotaAsync.asData?.value.resetsAt;
    final exhausted = captions != null && captions.remaining == 0;

    final hasResumeState = studioState.photos.isNotEmpty ||
        studioState.analysisResult != null;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: title + quota pill ────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Studio',
                            style: AppTypography.h1.copyWith(
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'What do you want to create today?',
                            style: AppTypography.body.copyWith(
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        quotaAsync.when(
                          data: (q) => _QuotaPill(
                            used: q.captions.used,
                            limit: q.captions.limit,
                            remaining: q.captions.remaining,
                          ),
                          loading: () => const _QuotaPill.loading(),
                          error: (_, __) => _QuotaPill.error(
                            onRetry: () =>
                                ref.invalidate(aiQuotaStatusProvider),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _ThemeToggleButton(
                          onTap: () =>
                              ref.read(themeModeProvider.notifier).toggle(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Resume card (shown only when session has state) ──
              if (hasResumeState) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _ResumeCard(
                    photos: studioState.photos,
                    analysis: studioState.analysisResult,
                    sessionId: studioState.session?.id ?? '',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // ── Hero: Camera CTA (animated) ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: _CameraHero(
                  disabled: exhausted,
                  disabledMessage: exhausted && resetsAt != null
                      ? 'Quota exhausted — resets ${_formatResetsAt(resetsAt)}'
                      : null,
                  onTap: exhausted
                      ? null
                      : () => context.push('/ai-studio/create-post'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Prompt chips (full bleed scroll) ─────────────
              const _PromptChipsRow(),
              const SizedBox(height: AppSpacing.xl),

              // ── Recent creations strip (THE STAR) ────────────
              const _RecentCreationsSection(),
              const SizedBox(height: AppSpacing.xl),

              // ── Coming soon ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMING SOON',
                      style: AppTypography.label.copyWith(
                        color: context.appTextTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const _ComingSoonRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'WhatsApp reply helper',
                      subtitle: 'Auto-reply to customer questions',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const _ComingSoonRow(
                      icon: Icons.campaign_outlined,
                      title: 'Ad creative generator',
                      subtitle: 'Facebook & Instagram ad variations',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quota pill ───────────────────────────────────────────────────

class _QuotaPill extends StatelessWidget {
  const _QuotaPill({
    required this.used,
    required this.limit,
    required this.remaining,
  })  : _loading = false,
        _errorState = false,
        onRetry = null;

  const _QuotaPill.loading()
      : used = 0,
        limit = 0,
        remaining = 0,
        _loading = true,
        _errorState = false,
        onRetry = null;

  const _QuotaPill.error({required VoidCallback this.onRetry})
      : used = 0,
        limit = 0,
        remaining = 0,
        _loading = false,
        _errorState = true;

  final int used;
  final int limit;
  final int remaining;
  final bool _loading;
  final bool _errorState;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    if (_errorState) {
      textColor = context.appTextTertiary;
    } else if (remaining == 0) {
      textColor = AppColors.error;
    } else if (remaining <= 2) {
      textColor = AppColors.warning;
    } else {
      textColor = context.appTextPrimary;
    }

    final Widget body;
    if (_loading) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 14, color: context.appTextTertiary),
          const SizedBox(width: AppSpacing.xxs + 2),
          SizedBox(
            width: 36,
            height: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appTextTertiary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        ],
      );
    } else if (_errorState) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: textColor),
          const SizedBox(width: AppSpacing.xxs + 2),
          Text(
            '—',
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: AppTypography.caption.copyWith(
                color: context.appBrand,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: context.appBrand,
              ),
            ),
          ),
        ],
      );
    } else {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: context.appAi),
          const SizedBox(width: AppSpacing.xxs + 2),
          Text(
            '$remaining left',
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: context.appBorder),
      ),
      child: body,
    );
  }
}

// ─── Resets-at formatter ──────────────────────────────────────────

String _formatResetsAt(DateTime resetsAt) {
  final now = DateTime.now();
  final diff = resetsAt.difference(now);
  final days = diff.inDays;
  if (days < 14) {
    if (diff.isNegative || days == 0) return 'today';
    if (days == 1) return 'tomorrow';
    return 'in $days days';
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return 'on ${months[resetsAt.month - 1]} ${resetsAt.day}';
}

// ─── Relative-time formatter ──────────────────────────────────────

String _formatRelativeTime(DateTime when) {
  final now = DateTime.now();
  final diff = now.difference(when);
  if (diff.isNegative) return 'just now';
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1 minute ago' : '$m minutes ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    if (d == 1) return 'yesterday';
    return '$d days ago';
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return 'on ${months[when.month - 1]} ${when.day}';
}

// ─── Resume card (subordinate visual weight vs. main CTA) ─────────

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.photos,
    required this.analysis,
    required this.sessionId,
  });

  final List<AiSessionPhoto> photos;
  final AiAnalysisResult? analysis;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final hasAnalysis = analysis != null;
    final title = hasAnalysis
        ? 'Last session'
        : '${photos.length} photo${photos.length == 1 ? '' : 's'} uploaded';
    final subtitle = hasAnalysis
        ? 'Analyzed ${_formatRelativeTime(analysis!.generatedAt)}'
        : 'Ready to analyze';
    final ctaLabel = hasAnalysis ? 'View result →' : 'Continue →';

    void onTap() {
      if (hasAnalysis) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(
              result: analysis!,
              photoUrls: photos.map((p) => p.cloudinaryUrl).toList(),
              sessionId: sessionId,
            ),
          ),
        );
      } else {
        context.push('/ai-studio/create-post');
      }
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 48,
                height: 48,
                child: photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photos.first.cloudinaryUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: context.appSurfaceL2,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: context.appSurfaceL2,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 18,
                            color: context.appTextTertiary,
                          ),
                        ),
                      )
                    : Container(
                        color: context.appSurfaceL2,
                        child: Icon(
                          Icons.photo_outlined,
                          size: 20,
                          color: context.appTextTertiary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Confidence pill (analyzed only)
            if (hasAnalysis) ...[
              const SizedBox(width: AppSpacing.xs),
              _ResumeConfidencePill(confidence: analysis!.confidence),
              const SizedBox(width: AppSpacing.xs),
            ],

            // CTA text
            Text(
              ctaLabel,
              style: AppTypography.caption.copyWith(
                color: context.appBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeConfidencePill extends StatelessWidget {
  const _ResumeConfidencePill({required this.confidence});
  final String confidence;

  @override
  Widget build(BuildContext context) {
    // Mirrors AnalysisResultScreen._ConfidenceBadge color mapping.
    final (Color fg, Color bg, String label) = switch (confidence) {
      'high' => (AppColors.success, AppColors.successBg, 'High'),
      'medium' => (AppColors.warning, AppColors.warningBg, 'Medium'),
      _ => (AppColors.error, AppColors.errorBg, 'Low'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Camera hero with subtle animation ────────────────────────────

class _CameraHero extends StatefulWidget {
  const _CameraHero({
    required this.onTap,
    this.disabled = false,
    this.disabledMessage,
  });

  final VoidCallback? onTap;
  final bool disabled;
  final String? disabledMessage;

  @override
  State<_CameraHero> createState() => _CameraHeroState();
}

class _CameraHeroState extends State<_CameraHero>
    with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final AnimationController _sparkleController;
  late final Animation<double> _breathing;
  late final Animation<double> _sparkleOpacity;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _breathing = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _sparkleOpacity = Tween<double>(begin: 0.45, end: 0.9).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: context.appHeroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: widget.disabled ? null : [context.appHeroGlow],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: animated sparkle (streak removed)
            Row(
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _sparkleOpacity,
                  builder: (context, _) => Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: AppColors.white.withValues(
                      alpha: _sparkleOpacity.value,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Breathing camera icon
            ScaleTransition(
              scale: _breathing,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Snap your product',
              style: AppTypography.h2.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 4),
            Text(
              widget.disabled && widget.disabledMessage != null
                  ? widget.disabledMessage!
                  : 'AI writes the caption — 30 seconds',
              style: AppTypography.body.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: widget.disabled
          ? Opacity(opacity: 0.55, child: content)
          : content,
    );
  }
}

// ─── Prompt chips (full bleed) ────────────────────────────────────

class _PromptChipsRow extends StatelessWidget {
  const _PromptChipsRow();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          _PromptChip(
            icon: Icons.shopping_bag_rounded,
            label: 'Nouvelle collection',
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.xs),
          _PromptChip(
            icon: Icons.local_offer_rounded,
            label: 'Promo / Soldes',
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.xs),
          _PromptChip(
            icon: Icons.inventory_2_rounded,
            label: 'Stock limité',
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.xs),
          _PromptChip(
            icon: Icons.nights_stay_rounded,
            label: 'Spécial Ramadan',
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.xs),
          _PromptChip(
            icon: Icons.new_releases_rounded,
            label: 'Nouveau produit',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: context.appBrand),
            const SizedBox(width: AppSpacing.xxs + 2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: context.appTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent creations strip (first-run examples) ──────────────────

class _RecentCreationsSection extends StatelessWidget {
  const _RecentCreationsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Row(
            children: [
              Text(
                'Get inspired',
                style: AppTypography.h4.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.appAiBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 10,
                      color: context.appAi,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Examples',
                      style: AppTypography.caption.copyWith(
                        color: context.appAi,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            children: const [
              _ExampleCard(
                category: 'Fashion',
                imageUrl:
                    'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&q=80',
                caption:
                    'Robe zarga jdida وصلت! 💙\nLivraison gratuite aujourd\'hui',
              ),
              SizedBox(width: AppSpacing.sm),
              _ExampleCard(
                category: 'Beauty',
                imageUrl:
                    'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=400&q=80',
                caption:
                    'Routine naturelle 🌿\nPour une peau lumineuse',
              ),
              SizedBox(width: AppSpacing.sm),
              _ExampleCard(
                category: 'Food',
                imageUrl:
                    'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=400&q=80',
                caption:
                    'M3ajel fresh 🔥\nDM للطلب · Livraison rapide',
              ),
              SizedBox(width: AppSpacing.sm),
              _ExampleCard(
                category: 'Accessories',
                imageUrl:
                    'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400&q=80',
                caption:
                    'Sac en cuir véritable ✨\nÉdition limitée',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.category,
    required this.imageUrl,
    required this.caption,
  });

  final String category;
  final String imageUrl;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
            ),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                children: [
                  // Real product photo from Unsplash
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: context.appSurfaceL2,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.appBrand.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: context.appSurfaceL2,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: context.appTextTertiary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Subtle dark gradient at the bottom for badge legibility
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.25),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Category badge — top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        category,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // AI sparkle — bottom-right
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 10,
                        color: context.appAi,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: context.appTextPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Coming soon rows ─────────────────────────────────────────────

class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.appBrandLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: context.appBrand, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              color: context.appTextTertiary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Theme toggle button ──────────────────────────────────────────

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.appSurface,
          shape: BoxShape.circle,
          border: Border.all(color: context.appBorder),
        ),
        child: Icon(
          context.isDark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          size: 18,
          color: context.appTextPrimary,
        ),
      ),
    );
  }
}
