import 'package:flutter/material.dart';

/// DIDO color tokens — v1.1
/// Source: UX_DESIGN_SYSTEM_V1.1.md Section 2.1
///
/// Six-color discipline + WhatsApp green exception. Each color has exactly
/// one job. Never introduce a 7th color.
///
/// Access at runtime via `context.colors.X` (see AppThemeX).
/// Light/dark variants resolved automatically by the active ThemeData.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // ── Surfaces ───────────────────────────────────────────
  /// Page background, the bottom-most surface.
  final Color surface0;

  /// Cards, sheets, list containers — default raised surface.
  final Color surface1;

  /// Sunken inputs, subtle wells, neutral badge fills.
  final Color surface2;

  /// Hover/press well, one step deeper than [surface2].
  final Color surface3;

  // ── Foreground (text & structure) ──────────────────────
  /// Primary text, headers, FAB, primary buttons, active states.
  final Color fg1;

  /// Secondary text, supporting copy.
  final Color fg2;

  /// Tertiary text — section labels, placeholders, muted timestamps.
  /// Same value (#8A8A8A) in both light and dark modes.
  final Color fg3;

  /// Disabled / faintest text and icons.
  final Color fg4;

  // ── Borders ────────────────────────────────────────────
  /// Default 1px border on cards, inputs, dividers.
  final Color border1;

  /// Stronger separator (rare use).
  final Color border2;

  // ── Brand ──────────────────────────────────────────────
  /// Logo, splash, boutique avatar. Max 1–2 occurrences per screen.
  /// Never on buttons, tabs, or chips.
  final Color brandTeal;

  /// Boutique avatar background tint, focused input ring fill.
  final Color brandTealTint08;

  /// Stronger teal tint (focus rings, emphasis).
  final Color brandTealTint16;

  // ── Attention (coral) ──────────────────────────────────
  /// Attention dot, alert strip border, "needs you" indicator.
  final Color coral;

  /// Coral background fill on attention strip and badges.
  final Color coralTint12;

  /// Coral text on coral tint background.
  final Color coralFg;

  // ── Positive (green) ───────────────────────────────────
  /// Profit numbers, success state, growth deltas, VIP segment.
  final Color green;

  /// Green background fill on positive badges.
  final Color greenTint12;

  /// Green text on green tint background.
  final Color greenFg;

  // ── Destructive (red) ──────────────────────────────────
  /// Delete actions, cancel, error, negative deltas.
  final Color red;

  /// Red background fill on destructive badges.
  final Color redTint12;

  /// Red text on red tint background.
  final Color redFg;

  // ── Special ────────────────────────────────────────────
  /// Modal/sheet overlay.
  final Color scrim;

  /// EXCEPTION — Customer Detail action bar WhatsApp button only.
  /// Same value in both modes (brand integration).
  final Color whatsappGreen;

  const AppColors({
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.fg4,
    required this.border1,
    required this.border2,
    required this.brandTeal,
    required this.brandTealTint08,
    required this.brandTealTint16,
    required this.coral,
    required this.coralTint12,
    required this.coralFg,
    required this.green,
    required this.greenTint12,
    required this.greenFg,
    required this.red,
    required this.redTint12,
    required this.redFg,
    required this.scrim,
    required this.whatsappGreen,
  });

  // ── Light mode ─────────────────────────────────────────
  static const AppColors light = AppColors(
    surface0: Color(0xFFFFFFFF),
    surface1: Color(0xFFFAFAFA), // pushback from #FFFFFF — subtle elevation w/o shadow
    surface2: Color(0xFFF5F5F5),
    surface3: Color(0xFFEEEEEE),
    fg1: Color(0xFF0A0A0A),
    fg2: Color(0xFF4A4A4A),
    fg3: Color(0xFF8A8A8A),
    fg4: Color(0xFFB8B8B8),
    border1: Color(0xFFE5E5E5),
    border2: Color(0xFFD4D4D4),
    brandTeal: Color(0xFF05687B),
    brandTealTint08: Color(0x1405687B),
    brandTealTint16: Color(0x2905687B),
    coral: Color(0xFFF4A78D),
    coralTint12: Color(0x2EF4A78D),
    coralFg: Color(0xFFB45A3C),
    green: Color(0xFF10B981),
    greenTint12: Color(0x2410B981),
    greenFg: Color(0xFF047857),
    red: Color(0xFFDC2626),
    redTint12: Color(0x1FDC2626),
    redFg: Color(0xFFB91C1C),
    scrim: Color(0x800A0A0A),
    whatsappGreen: Color(0xFF25D366),
  );

  // ── Dark mode ──────────────────────────────────────────
  static const AppColors dark = AppColors(
    surface0: Color(0xFF0A0A0A),
    surface1: Color(0xFF0A0A0A),
    surface2: Color(0xFF1A1A1A),
    surface3: Color(0xFF242424),
    fg1: Color(0xFFFAFAFA),
    fg2: Color(0xFFB8B8B8),
    fg3: Color(0xFF8A8A8A), // same as light per spec
    fg4: Color(0xFF4A4A4A),
    border1: Color(0x14FFFFFF),
    border2: Color(0x24FFFFFF),
    brandTeal: Color(0xFF2A8FA1),
    brandTealTint08: Color(0x242A8FA1),
    brandTealTint16: Color(0x3D2A8FA1),
    coral: Color(0xFFE89B82),
    coralTint12: Color(0x29E89B82),
    coralFg: Color(0xFFF4B89F),
    green: Color(0xFF15B981),
    greenTint12: Color(0x2E15B981),
    greenFg: Color(0xFF34D399),
    red: Color(0xFFE74848),
    redTint12: Color(0x29E74848),
    redFg: Color(0xFFF87171),
    scrim: Color(0x99000000),
    whatsappGreen: Color(0xFF25D366),
  );

  @override
  AppColors copyWith({
    Color? surface0,
    Color? surface1,
    Color? surface2,
    Color? surface3,
    Color? fg1,
    Color? fg2,
    Color? fg3,
    Color? fg4,
    Color? border1,
    Color? border2,
    Color? brandTeal,
    Color? brandTealTint08,
    Color? brandTealTint16,
    Color? coral,
    Color? coralTint12,
    Color? coralFg,
    Color? green,
    Color? greenTint12,
    Color? greenFg,
    Color? red,
    Color? redTint12,
    Color? redFg,
    Color? scrim,
    Color? whatsappGreen,
  }) {
    return AppColors(
      surface0: surface0 ?? this.surface0,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      fg1: fg1 ?? this.fg1,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      fg4: fg4 ?? this.fg4,
      border1: border1 ?? this.border1,
      border2: border2 ?? this.border2,
      brandTeal: brandTeal ?? this.brandTeal,
      brandTealTint08: brandTealTint08 ?? this.brandTealTint08,
      brandTealTint16: brandTealTint16 ?? this.brandTealTint16,
      coral: coral ?? this.coral,
      coralTint12: coralTint12 ?? this.coralTint12,
      coralFg: coralFg ?? this.coralFg,
      green: green ?? this.green,
      greenTint12: greenTint12 ?? this.greenTint12,
      greenFg: greenFg ?? this.greenFg,
      red: red ?? this.red,
      redTint12: redTint12 ?? this.redTint12,
      redFg: redFg ?? this.redFg,
      scrim: scrim ?? this.scrim,
      whatsappGreen: whatsappGreen ?? this.whatsappGreen,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surface0: Color.lerp(surface0, other.surface0, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      fg1: Color.lerp(fg1, other.fg1, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      fg3: Color.lerp(fg3, other.fg3, t)!,
      fg4: Color.lerp(fg4, other.fg4, t)!,
      border1: Color.lerp(border1, other.border1, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      brandTeal: Color.lerp(brandTeal, other.brandTeal, t)!,
      brandTealTint08: Color.lerp(brandTealTint08, other.brandTealTint08, t)!,
      brandTealTint16: Color.lerp(brandTealTint16, other.brandTealTint16, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralTint12: Color.lerp(coralTint12, other.coralTint12, t)!,
      coralFg: Color.lerp(coralFg, other.coralFg, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenTint12: Color.lerp(greenTint12, other.greenTint12, t)!,
      greenFg: Color.lerp(greenFg, other.greenFg, t)!,
      red: Color.lerp(red, other.red, t)!,
      redTint12: Color.lerp(redTint12, other.redTint12, t)!,
      redFg: Color.lerp(redFg, other.redFg, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      whatsappGreen: Color.lerp(whatsappGreen, other.whatsappGreen, t)!,
    );
  }

  // ════════════════════════════════════════════════════════
  // LEGACY STATIC ALIASES — v1.0 → v1.1 migration shim
  // ════════════════════════════════════════════════════════
  // Kept on the AppColors class so existing screens that call
  // `AppColors.brand` / `AppColors.surfaceL1` / etc. continue to
  // compile unchanged. Each value is retuned to the closest valid
  // v1.1 token. Delete this entire block after all screens have
  // been migrated to `context.colors.X`.

  @Deprecated('Use context.colors.brandTeal')
  static const Color brand = Color(0xFF05687B);

  @Deprecated('Use context.colors.brandTealTint08')
  static const Color brandLight = Color(0x1405687B);

  @Deprecated('No equivalent in v1.1 — falls back to brandTeal')
  static const Color brandDark = Color(0xFF05687B);

  @Deprecated('Use context.colors.brandTeal (resolved by Theme in dark mode)')
  static const Color brandDarkMode = Color(0xFF2A8FA1);

  @Deprecated('Use context.colors.brandTealTint08 (resolved by Theme in dark mode)')
  static const Color brandLightDarkMode = Color(0x242A8FA1);

  @Deprecated('Use context.colors.surface0')
  static const Color background = Color(0xFFFFFFFF);

  @Deprecated('Use context.colors.surface2')
  static const Color surfaceL1 = Color(0xFFF5F5F5);

  @Deprecated('Use context.colors.surface1')
  static const Color surfaceL2 = Color(0xFFFAFAFA);

  @Deprecated('Use context.colors.surface0 (resolved by Theme in dark mode)')
  static const Color backgroundDark = Color(0xFF0A0A0A);

  @Deprecated('Use context.colors.surface1 (resolved by Theme in dark mode)')
  static const Color surfaceL1Dark = Color(0xFF0A0A0A);

  @Deprecated('Use context.colors.surface2 (resolved by Theme in dark mode)')
  static const Color surfaceL2Dark = Color(0xFF1A1A1A);

  @Deprecated('Use context.colors.surface3 (resolved by Theme in dark mode)')
  static const Color surfaceL3Dark = Color(0xFF242424);

  @Deprecated('Use context.colors.border1')
  static const Color border = Color(0xFFE5E5E5);

  @Deprecated('Use context.colors.border1 (resolved by Theme in dark mode)')
  static const Color borderDark = Color(0x14FFFFFF);

  @Deprecated('Use context.colors.fg1')
  static const Color textPrimary = Color(0xFF0A0A0A);

  @Deprecated('Use context.colors.fg2')
  static const Color textSecondary = Color(0xFF4A4A4A);

  @Deprecated('Use context.colors.fg3')
  static const Color textTertiary = Color(0xFF8A8A8A);

  @Deprecated('Use context.colors.fg1 (resolved by Theme in dark mode)')
  static const Color textPrimaryDark = Color(0xFFFAFAFA);

  @Deprecated('Use context.colors.fg2 (resolved by Theme in dark mode)')
  static const Color textSecondaryDark = Color(0xFFB8B8B8);

  @Deprecated('Use context.colors.fg3 (resolved by Theme in dark mode)')
  static const Color textTertiaryDark = Color(0xFF8A8A8A);

  @Deprecated('Use context.colors.green')
  static const Color success = Color(0xFF10B981);

  @Deprecated('Use context.colors.greenTint12')
  static const Color successBg = Color(0x2410B981);

  @Deprecated('Use context.colors.red')
  static const Color error = Color(0xFFDC2626);

  @Deprecated('Use context.colors.redTint12')
  static const Color errorBg = Color(0x1FDC2626);

  @Deprecated('PALETTE VIOLATION — orange not in v1.1. Use context.colors.coral.')
  static const Color warning = Color(0xFFF4A78D);

  @Deprecated('PALETTE VIOLATION — orange not in v1.1. Use context.colors.coralTint12.')
  static const Color warningBg = Color(0x2EF4A78D);

  @Deprecated('PALETTE VIOLATION — blue not in v1.1. Use context.colors.fg2.')
  static const Color info = Color(0xFF4A4A4A);

  @Deprecated('PALETTE VIOLATION — blue not in v1.1. Use context.colors.surface2.')
  static const Color infoBg = Color(0xFFF5F5F5);

  @Deprecated('Use context.colors.surface0')
  static const Color white = Color(0xFFFFFFFF);

  @Deprecated('PALETTE VIOLATION — orange streak removed. Use context.colors.coral.')
  static const Color streak = Color(0xFFF4A78D);

  @Deprecated('PALETTE VIOLATION — orange streak removed. Use context.colors.coralTint12.')
  static const Color streakBg = Color(0x2EF4A78D);

  @Deprecated('PALETTE VIOLATION — orange streak removed. Use context.colors.coral.')
  static const Color streakDarkMode = Color(0xFFE89B82);

  @Deprecated('PALETTE VIOLATION — purple AI removed. AI Studio deferred. Use context.colors.coral.')
  static const Color ai = Color(0xFFF4A78D);

  @Deprecated('PALETTE VIOLATION — purple AI removed. Use context.colors.coralTint12.')
  static const Color aiBg = Color(0x2EF4A78D);

  @Deprecated('PALETTE VIOLATION — purple AI removed.')
  static const Color aiDarkMode = Color(0xFFE89B82);

  @Deprecated('PALETTE VIOLATION — decorative gradients removed. Use a flat fg-1 surface.')
  static const Color heroGradientStart = Color(0xFF0A0A0A);

  @Deprecated('PALETTE VIOLATION — decorative gradients removed.')
  static const Color heroGradientEnd = Color(0xFF0A0A0A);

  @Deprecated('PALETTE VIOLATION — decorative gradients removed.')
  static const Color heroGradientGlow = Color(0x00000000);
}
