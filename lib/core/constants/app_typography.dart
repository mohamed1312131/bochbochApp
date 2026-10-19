import 'package:flutter/material.dart';

// NOTE: This file contains TWO typography classes by design.
// - AppTextStyles: the v1.1 ThemeExtension. Access via context.typography.
// - AppTypography: deprecated v1.0 static-only API kept for migration.
//
// The split exists because Dart prohibits a class from having a static
// and instance member with the same name (h1, h2, body, etc. collide).
// Prompt 6 (app_theme_extension.dart) wires `context.typography` to
// resolve to an AppTextStyles instance, so callsite ergonomics match
// UX_DESIGN_SYSTEM_V1.1.md §7.3 exactly.
//
// Delete the AppTypography class entirely after all screens migrate
// to context.typography.X.

/// DIDO typography tokens — v1.1
/// Source: UX_DESIGN_SYSTEM_V1.1.md Section 2.2
///
/// Font: Inter (bundled in assets/fonts/, registered in pubspec.yaml).
/// Numeric strings use tabular figures via FontFeature.tabularFigures().
///
/// Access at runtime via `context.typography.X` (see AppThemeX).
/// Typography is mode-agnostic — color is applied at the call site.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  // ── Headlines ──────────────────────────────────────────
  /// Screen titles (Commandes, Clients, Produits, Stats, Aujourd'hui).
  final TextStyle h1;

  /// Section headlines, large-number tile values when not using `number`.
  final TextStyle h2;

  /// Sheet titles, customer detail name.
  final TextStyle h3;

  /// Card titles, list-item primary line.
  final TextStyle h4;

  // ── Body ───────────────────────────────────────────────
  /// Default body copy, list-item secondary line.
  final TextStyle body;

  /// Emphasized body, list-item amount.
  final TextStyle bodyMd;

  /// Tile delta line, helper text, timestamp.
  final TextStyle bodySmall;

  /// Tile delta value (positive/negative tone). Tabular nums.
  final TextStyle bodySmallMd;

  // ── Labels & captions ──────────────────────────────────
  /// UPPERCASE section labels above lists/tiles. Always rendered with `fg-3`.
  final TextStyle label;

  /// Tertiary timestamp, secondary metadata.
  final TextStyle caption;

  // ── Numerics ───────────────────────────────────────────
  /// Big numbers in tiles. Tabular nums. Auto-shrink handled by callsite.
  final TextStyle number;

  /// Order total, hero numerics. Tabular nums.
  final TextStyle numberLg;

  // ── Interactive ────────────────────────────────────────
  /// Primary, secondary, text button labels.
  final TextStyle button;

  /// Tab strip labels.
  final TextStyle tab;

  /// Badge / segment-pill text.
  final TextStyle tabPill;

  /// Inputs only. 16px to prevent iOS auto-zoom on focus.
  final TextStyle input;

  // ── Stock module additions (FLUTTER_SPEC.md) ───────────
  /// Hero numerics on the stock dashboard / receive-shipment summary.
  final TextStyle display;

  /// Product detail page name (tighter than h2, larger than h3).
  final TextStyle h1Product;

  /// Big-number value on dashboard tiles. Tabular nums.
  final TextStyle tileNum;

  /// Trend / delta line value (e.g. +24%). Tabular nums.
  final TextStyle delta;

  /// Emphasized inline number — list-row trailing prices. Tabular nums.
  final TextStyle bodyMdNum;

  /// Compact emphasized body — segmented control labels, helper rows.
  final TextStyle smallMd;

  /// Boutique-chip monogram letter. Optical sizing only — no leading.
  final TextStyle boutiqueMono;

  /// Status bar / system clock copy. Custom weight for iOS parity.
  final TextStyle statusBar;

  const AppTextStyles({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.body,
    required this.bodyMd,
    required this.bodySmall,
    required this.bodySmallMd,
    required this.label,
    required this.caption,
    required this.number,
    required this.numberLg,
    required this.button,
    required this.tab,
    required this.tabPill,
    required this.input,
    required this.display,
    required this.h1Product,
    required this.tileNum,
    required this.delta,
    required this.bodyMdNum,
    required this.smallMd,
    required this.boutiqueMono,
    required this.statusBar,
  });

  static const AppTextStyles standard = AppTextStyles(
    h1: TextStyle(
      fontFamily: 'Inter',
      fontSize: 28,
      height: 32 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.56,
    ),
    h2: TextStyle(
      fontFamily: 'Inter',
      fontSize: 24,
      height: 28 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.48,
    ),
    h3: TextStyle(
      fontFamily: 'Inter',
      fontSize: 20,
      height: 24 / 20,
      fontWeight: FontWeight.w600,
    ),
    h4: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      height: 22 / 17,
      fontWeight: FontWeight.w600,
    ),
    body: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
    ),
    bodyMd: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w500,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
    ),
    bodySmallMd: TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    label: TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    caption: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
    ),
    number: TextStyle(
      fontFamily: 'Inter',
      fontSize: 28,
      height: 32 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.56,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    numberLg: TextStyle(
      fontFamily: 'Inter',
      fontSize: 24,
      height: 28 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.48,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    button: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w500,
    ),
    tab: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w500,
    ),
    tabPill: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
    ),
    input: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w400,
    ),
    display: TextStyle(
      fontFamily: 'Inter',
      fontSize: 36,
      height: 40 / 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02 * 36,
    ),
    h1Product: TextStyle(
      fontFamily: 'Inter',
      fontSize: 22,
      height: 26 / 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.01 * 22,
    ),
    tileNum: TextStyle(
      fontFamily: 'Inter',
      fontSize: 28,
      height: 32 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02 * 28,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    delta: TextStyle(
      fontFamily: 'Inter',
      fontSize: 17,
      height: 22 / 17,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    bodyMdNum: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    smallMd: TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    boutiqueMono: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      height: 12 / 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    // statusBar — spec asks for w590 (iOS system weight). Flutter's
    // stable FontWeight only exposes w100…w900 in 100-step increments,
    // so we round to w600 per the task instruction.
    statusBar: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
  );

  @override
  AppTextStyles copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? body,
    TextStyle? bodyMd,
    TextStyle? bodySmall,
    TextStyle? bodySmallMd,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? number,
    TextStyle? numberLg,
    TextStyle? button,
    TextStyle? tab,
    TextStyle? tabPill,
    TextStyle? input,
    TextStyle? display,
    TextStyle? h1Product,
    TextStyle? tileNum,
    TextStyle? delta,
    TextStyle? bodyMdNum,
    TextStyle? smallMd,
    TextStyle? boutiqueMono,
    TextStyle? statusBar,
  }) {
    return AppTextStyles(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      body: body ?? this.body,
      bodyMd: bodyMd ?? this.bodyMd,
      bodySmall: bodySmall ?? this.bodySmall,
      bodySmallMd: bodySmallMd ?? this.bodySmallMd,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      number: number ?? this.number,
      numberLg: numberLg ?? this.numberLg,
      button: button ?? this.button,
      tab: tab ?? this.tab,
      tabPill: tabPill ?? this.tabPill,
      input: input ?? this.input,
      display: display ?? this.display,
      h1Product: h1Product ?? this.h1Product,
      tileNum: tileNum ?? this.tileNum,
      delta: delta ?? this.delta,
      bodyMdNum: bodyMdNum ?? this.bodyMdNum,
      smallMd: smallMd ?? this.smallMd,
      boutiqueMono: boutiqueMono ?? this.boutiqueMono,
      statusBar: statusBar ?? this.statusBar,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      h4: TextStyle.lerp(h4, other.h4, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyMd: TextStyle.lerp(bodyMd, other.bodyMd, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      bodySmallMd: TextStyle.lerp(bodySmallMd, other.bodySmallMd, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      number: TextStyle.lerp(number, other.number, t)!,
      numberLg: TextStyle.lerp(numberLg, other.numberLg, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      tab: TextStyle.lerp(tab, other.tab, t)!,
      tabPill: TextStyle.lerp(tabPill, other.tabPill, t)!,
      input: TextStyle.lerp(input, other.input, t)!,
      display: TextStyle.lerp(display, other.display, t)!,
      h1Product: TextStyle.lerp(h1Product, other.h1Product, t)!,
      tileNum: TextStyle.lerp(tileNum, other.tileNum, t)!,
      delta: TextStyle.lerp(delta, other.delta, t)!,
      bodyMdNum: TextStyle.lerp(bodyMdNum, other.bodyMdNum, t)!,
      smallMd: TextStyle.lerp(smallMd, other.smallMd, t)!,
      boutiqueMono: TextStyle.lerp(boutiqueMono, other.boutiqueMono, t)!,
      statusBar: TextStyle.lerp(statusBar, other.statusBar, t)!,
    );
  }
}

// ════════════════════════════════════════════════════════════
// LEGACY v1.0 API — static-only, deprecated
// ════════════════════════════════════════════════════════════
// All values retuned to v1.1 sizes/weights and swapped to Inter
// so screens render correctly without any code changes.
// Delete this entire class after all screens migrate to
// context.typography.X.

@Deprecated('Use AppTextStyles via context.typography. Will be removed after screen migration.')
abstract final class AppTypography {
  @Deprecated('Display token dropped — resolves to h1. Use context.typography.h1.')
  static const TextStyle display = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.56,
  );

  @Deprecated('Use context.typography.h1')
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.56,
  );

  @Deprecated('Use context.typography.h2')
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    height: 28 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.48,
  );

  @Deprecated('Use context.typography.h3')
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w600,
  );

  @Deprecated('Use context.typography.h4')
  static const TextStyle h4 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
  );

  @Deprecated('bodyLarge dropped — resolves to body. Use context.typography.body.')
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
  );

  @Deprecated('Use context.typography.body')
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
  );

  @Deprecated('Use context.typography.bodySmall')
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );

  @Deprecated('Use context.typography.label — size 12→11, tracking unchanged')
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  @Deprecated('Use context.typography.caption — size 11→12, tracking 0.5→0')
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
}
