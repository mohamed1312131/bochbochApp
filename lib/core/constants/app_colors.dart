import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────
  static const brand = Color(0xFF05687B);
  static const brandLight = Color(0xFFE6F4F7);
  static const brandDark = Color(0xFF034D5C);
  static const brandDarkMode = Color(0xFF0A8FA6);
  static const brandLightDarkMode = Color(0xFF0A3D47);

  // ── Neutrals Light ───────────────────────────────────────
  static const background = Color(0xFFF8F9FC);
  static const surfaceL1 = Color(0xFFF2F3F7);
  static const surfaceL2 = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);

  // ── Neutrals Dark ────────────────────────────────────────
  static const backgroundDark = Color(0xFF000000);
  static const surfaceL1Dark = Color(0xFF1C1C1E);
  static const surfaceL2Dark = Color(0xFF2C2C2E);
  static const surfaceL3Dark = Color(0xFF3A3A3C);
  static const borderDark = Color(0xFF3A3A3C);

  // ── Text ─────────────────────────────────────────────────
  static const textPrimary = Color(0xFF0A0A0A);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const textTertiaryDark = Color(0xFF6B7280);

  // ── Semantic ─────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorBg = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoBg = Color(0xFFDBEAFE);

  // ── Always white ─────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);

  // ── Achievement / Streak ─────────────────────────────────
  // For streaks, celebrations, "on fire" states.
  // Warm amber — visually separates from brand teal.
  static const streak = Color(0xFFFF8A3D);
  static const streakBg = Color(0xFFFFF1E6);
  static const streakDarkMode = Color(0xFFFFB56B);

  // ── AI / Premium ─────────────────────────────────────────
  // For AI features, magic moments, premium tier.
  // Used ONLY on AI touchpoints — sparkle consistency.
  static const ai = Color(0xFF7C3AED);
  static const aiBg = Color(0xFFF3E8FF);
  static const aiDarkMode = Color(0xFFA78BFA);

  // ── Hero gradient (canonical) ────────────────────────────
  // The gradient used across home, insights, settings hero cards.
  // Declared here so screens stop inventing their own.
  static const heroGradientStart = Color(0xFF05687B);
  static const heroGradientEnd = Color(0xFF023D49);
  static const heroGradientGlow = Color(0xFF05687B);
}