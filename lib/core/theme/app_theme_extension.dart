import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

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

  // ── Shadow ─────────────────────────────────────────────
  List<BoxShadow> get appCardShadow => isDark
      ? const <BoxShadow>[]
      : const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ];

  List<BoxShadow> get appCardShadowLg => isDark
      ? []
      : [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ];

  // ── Streak / Achievement ────────────────────────────────
  Color get appStreak =>
      isDark ? AppColors.streakDarkMode : AppColors.streak;

  Color get appStreakBg =>
      isDark ? AppColors.streakDarkMode.withValues(alpha: 0.15)
             : AppColors.streakBg;

  // ── AI accent ───────────────────────────────────────────
  Color get appAi =>
      isDark ? AppColors.aiDarkMode : AppColors.ai;

  Color get appAiBg =>
      isDark ? AppColors.aiDarkMode.withValues(alpha: 0.15)
             : AppColors.aiBg;

  // ── Hero gradient (canonical) ──────────────────────────
  // Use this on all hero/premium cards — never hard-code.
  LinearGradient get appHeroGradient => const LinearGradient(
        colors: [
          AppColors.heroGradientStart,
          AppColors.heroGradientEnd,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  BoxShadow get appHeroGlow => BoxShadow(
        color: AppColors.heroGradientGlow.withValues(alpha: 0.35),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );
}