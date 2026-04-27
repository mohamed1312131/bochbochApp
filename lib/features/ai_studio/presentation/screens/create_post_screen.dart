import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../providers/ai_studio_provider.dart';
import '../widgets/quality_warning_sheet.dart';
import '../../domain/ai_studio_models.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiStudioProvider.notifier).initSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiStudioProvider);

    ref.listen<AiStudioState>(aiStudioProvider, (prev, next) {
      if (prev?.status == next.status) return;

      if (next.status == AiStudioStatus.gateWarning ||
          next.status == AiStudioStatus.gateBlocked) {
        _showQualitySheet(context, next);
      }

      if (next.status == AiStudioStatus.analyzed &&
          next.analysisResult != null) {
        context.push(
          '/ai-studio/create-post/result',
          extra: {
            'result': next.analysisResult!,
            'photoUrls': next.photos.map((p) => p.cloudinaryUrl).toList(),
            'sessionId': next.session?.id ?? '',
          },
        );
      }
    });

    final isBusy = state.status == AiStudioStatus.processingPhoto ||
        state.status == AiStudioStatus.uploadingPhoto ||
        state.status == AiStudioStatus.analyzing;

    final isAnalyzing = state.status == AiStudioStatus.analyzing;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: switch (state.status) {
          AiStudioStatus.initializingSession => const _LoadingBody(
              message: 'Setting up your studio…',
            ),
          AiStudioStatus.error => _ErrorBody(
              message: state.error ?? 'Something went wrong',
              onRetry: () =>
                  ref.read(aiStudioProvider.notifier).initSession(),
            ),
          _ => Column(
              children: [
                // ── Custom header ──────────────────────────────
                _Header(
                  step: state.photos.isEmpty
                      ? 1
                      : (state.photos.length < 3 ? 2 : 3),
                  totalSteps: 3,
                  // Back is pure navigation — do NOT abandon the session.
                  // The user can resume from the hub card on re-entry.
                  onBack: () => context.pop(),
                  onStartOver: () => _confirmStartOver(context, ref),
                ),

                // ── Scrollable content ─────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                      AppSpacing.screenHorizontal,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Snap your product',
                          style: AppTypography.h1.copyWith(
                            color: context.appTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Natural light works best',
                          style: AppTypography.body.copyWith(
                            color: context.appTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Primary slot
                        _PrimarySlot(
                          photo: state.photos.isNotEmpty
                              ? state.photos[0]
                              : null,
                          isBusy: isBusy,
                          onTap: _pickPhoto,
                          // No per-photo remove in provider — no-op
                          onRemove: () {},
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Secondary slots
                        _SecondarySlots(
                          primaryFilled: state.photos.isNotEmpty,
                          photo2: state.photos.length > 1
                              ? state.photos[1]
                              : null,
                          photo3: state.photos.length > 2
                              ? state.photos[2]
                              : null,
                          isBusy: isBusy,
                          onTapSlot2: _pickPhoto,
                          onTapSlot3: _pickPhoto,
                          onRemoveSlot2: () {},
                          onRemoveSlot3: () {},
                        ),

                        // Busy label while processing/uploading
                        if (state.status ==
                                AiStudioStatus.processingPhoto ||
                            state.status ==
                                AiStudioStatus.uploadingPhoto) ...[
                          const SizedBox(height: AppSpacing.md),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.appBrand,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  state.status ==
                                          AiStudioStatus.processingPhoto
                                      ? 'Checking photo quality…'
                                      : 'Uploading…',
                                  style: AppTypography.caption.copyWith(
                                    color: context.appTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),
                        const _RotatingTipCard(),
                      ],
                    ),
                  ),
                ),

                // ── Bottom CTA ─────────────────────────────────
                _BottomCta(
                  active: state.canAnalyze && !isBusy,
                  isLoading: isAnalyzing,
                  onTap: () =>
                      ref.read(aiStudioProvider.notifier).analyze(),
                ),
              ],
            ),
        },
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await _showSourceSheet();
    if (source == null) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (file == null) return;

    await ref.read(aiStudioProvider.notifier).pickAndProcessPhoto(file);
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              ListTile(
                leading: Icon(
                  Icons.camera_alt_rounded,
                  color: context.appTextPrimary,
                ),
                title: Text(
                  'Take a photo',
                  style: AppTypography.body
                      .copyWith(color: context.appTextPrimary),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: context.appTextPrimary,
                ),
                title: Text(
                  'Choose from gallery',
                  style: AppTypography.body
                      .copyWith(color: context.appTextPrimary),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStartOver(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: dialogCtx.appSurface,
        title: Text(
          'Start a new session?',
          style: AppTypography.h4.copyWith(
            color: dialogCtx.appTextPrimary,
          ),
        ),
        content: Text(
          "This will clear your current photo and analysis. "
          "You'll use 1 analyze quota for the next photo.",
          style: AppTypography.body.copyWith(
            color: dialogCtx.appTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                color: dialogCtx.appTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Start over',
              style: AppTypography.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(aiStudioProvider.notifier).abandonExplicitly();
    if (!context.mounted) return;
    // Pop back to hub — the next entry will get a fresh session.
    context.pop();
  }

  Future<void> _showQualitySheet(
    BuildContext context,
    AiStudioState state,
  ) async {
    final result = state.pendingPipelineResult?.gateResult;
    if (result == null) return;

    final action = await QualityWarningSheet.show(context, result);
    if (!mounted) return;

    final notifier = ref.read(aiStudioProvider.notifier);
    switch (action) {
      case QualitySheetAction.useAnyway:
        await notifier.overrideAndUpload();
      case QualitySheetAction.retake:
      case null:
        notifier.resetToIdle();
    }
  }
}

// ─── Loading / Error bodies (preserved) ──────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.body
                .copyWith(color: context.appTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body
                  .copyWith(color: context.appTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

// ─── Header: back button + step indicator ────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.onStartOver,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.appTextPrimary,
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(totalSteps, (i) {
                final filled = i < step;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i < totalSteps - 1 ? 4 : 0,
                    ),
                    height: 3,
                    decoration: BoxDecoration(
                      color: filled ? context.appBrand : context.appBorder,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$step/$totalSteps',
            style: AppTypography.caption.copyWith(
              color: context.appTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.appTextPrimary,
            ),
            onSelected: (value) {
              if (value == 'start_over') onStartOver();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'start_over',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Start over',
                      style: AppTypography.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Primary slot — hero camera tile ─────────────────────────────

class _PrimarySlot extends StatefulWidget {
  const _PrimarySlot({
    required this.photo,
    required this.isBusy,
    required this.onTap,
    required this.onRemove,
  });

  final AiSessionPhoto? photo;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  State<_PrimarySlot> createState() => _PrimarySlotState();
}

class _PrimarySlotState extends State<_PrimarySlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photo != null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: CachedNetworkImage(
                  imageUrl: widget.photo!.cloudinaryUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: context.appSurfaceL2),
                  errorWidget: (context, url, error) => Container(
                    color: context.appSurfaceL2,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: context.appTextTertiary,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Primary',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Remove is a no-op — provider has no per-photo delete
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state — gradient hero with pulsing camera icon
    return GestureDetector(
      onTap: widget.isBusy ? null : widget.onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: context.appHeroGradient,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [context.appHeroGlow],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tap to take a photo',
                  style: AppTypography.h4.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your main product shot',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Secondary slots row ──────────────────────────────────────────

class _SecondarySlots extends StatelessWidget {
  const _SecondarySlots({
    required this.primaryFilled,
    required this.photo2,
    required this.photo3,
    required this.isBusy,
    required this.onTapSlot2,
    required this.onTapSlot3,
    required this.onRemoveSlot2,
    required this.onRemoveSlot3,
  });

  final bool primaryFilled;
  final AiSessionPhoto? photo2;
  final AiSessionPhoto? photo3;
  final bool isBusy;
  final VoidCallback onTapSlot2;
  final VoidCallback onTapSlot3;
  final VoidCallback onRemoveSlot2;
  final VoidCallback onRemoveSlot3;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondarySlot(
            label: 'Add angle',
            icon: Icons.threesixty_rounded,
            photo: photo2,
            locked: !primaryFilled || isBusy,
            onTap: onTapSlot2,
            onRemove: onRemoveSlot2,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SecondarySlot(
            label: 'Add detail',
            icon: Icons.center_focus_strong_rounded,
            photo: photo3,
            locked: !primaryFilled || isBusy,
            onTap: onTapSlot3,
            onRemove: onRemoveSlot3,
          ),
        ),
      ],
    );
  }
}

class _SecondarySlot extends StatelessWidget {
  const _SecondarySlot({
    required this.label,
    required this.icon,
    required this.photo,
    required this.locked,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final AiSessionPhoto? photo;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: CachedNetworkImage(
                  imageUrl: photo!.cloudinaryUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: context.appSurfaceL2),
                  errorWidget: (context, url, error) => Container(
                    color: context.appSurfaceL2,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: context.appTextTertiary,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Opacity(
      opacity: locked ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: DottedBorderBox(
            borderColor: context.appBorder,
            radius: AppRadius.lg,
            child: Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    locked ? Icons.lock_outline_rounded : icon,
                    size: 22,
                    color: context.appTextTertiary,
                  ),
                  const SizedBox(height: AppSpacing.xxs + 2),
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: context.appTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dotted border CustomPainter ─────────────────────────────────

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.borderColor,
    required this.radius,
    required this.child,
  });

  final Color borderColor;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: borderColor, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();

    const dashLength = 5.0;
    const gapLength = 4.0;

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

// ─── Rotating AI tip card ─────────────────────────────────────────

class _RotatingTipCard extends StatefulWidget {
  const _RotatingTipCard();

  @override
  State<_RotatingTipCard> createState() => _RotatingTipCardState();
}

class _RotatingTipCardState extends State<_RotatingTipCard> {
  static const List<_Tip> _tips = [
    _Tip(
      icon: Icons.wb_sunny_rounded,
      text: 'Natural daylight near a window gives the best results',
    ),
    _Tip(
      icon: Icons.wallpaper_rounded,
      text: 'Plain backgrounds help the AI focus on your product',
    ),
    _Tip(
      icon: Icons.camera_rounded,
      text: 'Hold the phone steady — blur reduces AI accuracy',
    ),
    _Tip(
      icon: Icons.filter_center_focus_rounded,
      text: 'Fill the frame — your product should be the main subject',
    ),
    _Tip(
      icon: Icons.palette_rounded,
      text: 'True colors help AI write accurate descriptions',
    ),
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _tips.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_index];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appAiBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.appAi.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.appAi.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(tip.icon, color: context.appAi, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                tip.text,
                key: ValueKey(_index),
                style: AppTypography.bodySmall.copyWith(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip {
  const _Tip({required this.icon, required this.text});
  final IconData icon;
  final String text;
}

// ─── Bottom CTA ───────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.active,
    required this.isLoading,
    required this.onTap,
  });

  final bool active;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.sm,
          AppSpacing.screenHorizontal,
          AppSpacing.md,
        ),
        child: GestureDetector(
          onTap: active && !isLoading ? onTap : null,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: active ? context.appHeroGradient : null,
              color: active ? null : context.appSurfaceL2,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: active ? [context.appHeroGlow] : null,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: active
                              ? AppColors.white
                              : context.appTextTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Analyze with AI',
                          style: AppTypography.bodyLarge.copyWith(
                            color: active
                                ? AppColors.white
                                : context.appTextTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
