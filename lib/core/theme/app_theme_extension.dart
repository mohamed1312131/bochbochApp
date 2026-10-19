import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';
import '../constants/app_border_radius.dart';
import '../constants/app_shadows.dart';
import '../constants/app_motion.dart';

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Grouped accessors (v1.1 API) ───────────────────────
  // Use these in new code. Each returns the registered ThemeExtension
  // instance for the active brightness.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppTextStyles get typography => Theme.of(this).extension<AppTextStyles>()!;
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
  AppRadius get radius => Theme.of(this).extension<AppRadius>()!;
  AppShadows get shadows => Theme.of(this).extension<AppShadows>()!;

  /// Motion is mode-agnostic and not registered as a ThemeExtension.
  AppMotion get motion => AppMotion.standard;

  // ════════════════════════════════════════════════════════
  // LEGACY FLAT GETTERS — kept for backward compatibility.
  // Migrate callsites to the grouped accessors above.
  // ════════════════════════════════════════════════════════

  // ── Backgrounds ────────────────────────────────────────
  Color get appBackground =>
      isDark ? AppColors.backgroundDark : AppColors.background;

  Color get appSurface =>
      isDark ? AppColors.surfaceL1Dark : AppColors.white;

  Color get appSurfaceL2 =>
      isDark ? AppColors.surfaceL2Dark : AppColors.surfaceL1;

  Color get appSurfaceL3 =>
      isDark ? AppColors.surfaceL3Dark : AppColors.surfaceL1;

  // ── Text ───────────────────────────────────────────────
  Color get appTextPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

  Color get appTextSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

  Color get appTextTertiary =>
      isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;

  // ── Border ─────────────────────────────────────────────
  Color get appBorder =>
      isDark ? AppColors.borderDark : AppColors.border;

  // ── Brand ──────────────────────────────────────────────
  Color get appBrand =>
      isDark ? AppColors.brandDarkMode : AppColors.brand;

  Color get appBrandLight =>
      isDark ? AppColors.brandLightDarkMode : AppColors.brandLight;

  // ════════════════════════════════════════════════════════
  // NEUTRALIZED GETTERS — palette/elevation violations.
  // Resolve to the nearest valid v1.1 token.
  // ════════════════════════════════════════════════════════

  @Deprecated('ELEVATION VIOLATION — v1.1 §2.5: cards use borders + spacing. Use context.shadows.shadowNone.')
  List<BoxShadow> get appCardShadow => shadows.shadowNone;

  @Deprecated('ELEVATION VIOLATION — v1.1 §2.5. Use context.shadows.shadowNone.')
  List<BoxShadow> get appCardShadowLg => shadows.shadowNone;

  @Deprecated('PALETTE VIOLATION — orange streak removed. Use context.colors.coral.')
  Color get appStreak => colors.coral;

  @Deprecated('PALETTE VIOLATION — orange streak removed. Use context.colors.coralTint12.')
  Color get appStreakBg => colors.coralTint12;

  @Deprecated('PALETTE VIOLATION — purple AI removed. AI Studio deferred to v2. Use context.colors.coral.')
  Color get appAi => colors.coral;

  @Deprecated('PALETTE VIOLATION — purple AI removed. Use context.colors.coralTint12.')
  Color get appAiBg => colors.coralTint12;

  @Deprecated('PALETTE VIOLATION — decorative gradient removed per Rule 4. Renders as solid fg-1.')
  LinearGradient get appHeroGradient => LinearGradient(
        colors: [colors.fg1, colors.fg1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @Deprecated('PALETTE VIOLATION — decorative glow removed.')
  BoxShadow get appHeroGlow => const BoxShadow(
        color: Color(0x00000000),
        blurRadius: 0,
        offset: Offset.zero,
      );
}
