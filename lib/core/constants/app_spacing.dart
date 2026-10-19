import 'dart:ui';
import 'package:flutter/material.dart';

/// DIDO spacing tokens — v1.1
/// Source: UX_DESIGN_SYSTEM_V1.1.md §2.3
///
/// Strict 4px grid. Access at runtime via `context.spacing.X`.
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  // ── Numeric scale (4px grid) ───────────────────────────
  /// 4px — tight stacking within a label.
  final double space1;

  /// 8px — label-to-value pairs in cards.
  final double space2;

  /// 12px — between cards in a list.
  final double space3;

  /// 16px — card internal padding, screen edge padding.
  final double space4;

  /// 20px — between sub-blocks within a card (e.g. stacked
  /// `_BreakdownBlock`s in stats), where space4 reads tight and
  /// space6 reads loose.
  final double space5;

  /// 24px — top of screen to first element, section gaps within content.
  final double space6;

  /// 32px — between major sections.
  final double space8;

  /// 48px — empty-state vertical centering.
  final double space12;

  // ── Semantic aliases ───────────────────────────────────
  /// 16px — horizontal padding from screen edge.
  final double screenEdge;

  /// 16px — internal padding inside cards/tiles.
  final double cardPadding;

  /// 32px — gap between major sections within a screen.
  final double sectionGap;

  const AppSpacing({
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space5,
    required this.space6,
    required this.space8,
    required this.space12,
    required this.screenEdge,
    required this.cardPadding,
    required this.sectionGap,
  });

  static const AppSpacing standard = AppSpacing(
    space1: 4,
    space2: 8,
    space3: 12,
    space4: 16,
    space5: 20,
    space6: 24,
    space8: 32,
    space12: 48,
    screenEdge: 16,
    cardPadding: 16,
    sectionGap: 32,
  );

  @override
  AppSpacing copyWith({
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space5,
    double? space6,
    double? space8,
    double? space12,
    double? screenEdge,
    double? cardPadding,
    double? sectionGap,
  }) {
    return AppSpacing(
      space1: space1 ?? this.space1,
      space2: space2 ?? this.space2,
      space3: space3 ?? this.space3,
      space4: space4 ?? this.space4,
      space5: space5 ?? this.space5,
      space6: space6 ?? this.space6,
      space8: space8 ?? this.space8,
      space12: space12 ?? this.space12,
      screenEdge: screenEdge ?? this.screenEdge,
      cardPadding: cardPadding ?? this.cardPadding,
      sectionGap: sectionGap ?? this.sectionGap,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      space1: lerpDouble(space1, other.space1, t)!,
      space2: lerpDouble(space2, other.space2, t)!,
      space3: lerpDouble(space3, other.space3, t)!,
      space4: lerpDouble(space4, other.space4, t)!,
      space5: lerpDouble(space5, other.space5, t)!,
      space6: lerpDouble(space6, other.space6, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space12: lerpDouble(space12, other.space12, t)!,
      screenEdge: lerpDouble(screenEdge, other.screenEdge, t)!,
      cardPadding: lerpDouble(cardPadding, other.cardPadding, t)!,
      sectionGap: lerpDouble(sectionGap, other.sectionGap, t)!,
    );
  }

  // ════════════════════════════════════════════════════════
  // LEGACY STATIC ALIASES — v1.0 → v1.1 migration shim
  // ════════════════════════════════════════════════════════
  // Kept on AppSpacing so existing screens compile unchanged.
  // Delete this block after screens migrate to context.spacing.X.

  @Deprecated('Use context.spacing.space1')
  static const double xxs = 4;

  @Deprecated('Use context.spacing.space2')
  static const double xs = 8;

  @Deprecated('Use context.spacing.space3')
  static const double sm = 12;

  @Deprecated('Use context.spacing.space4')
  static const double md = 16;

  @Deprecated('Use context.spacing.space4 — value tightened 20→16 per v1.1 §2.3 (off-grid 20 dropped).')
  static const double lg = 16;

  @Deprecated('Use context.spacing.space6')
  static const double xl = 24;

  @Deprecated('Use context.spacing.space8')
  static const double xxl = 32;

  @Deprecated('Use context.spacing.space8 — value retuned 40→32 per v1.1 §2.3 (off-grid 40 dropped).')
  static const double xxxl = 32;

  @Deprecated('Use context.spacing.space12')
  static const double xxxxl = 48;

  @Deprecated('No v1.1 equivalent — audit usage and replace per case.')
  static const double xxxxxl = 64;

  @Deprecated('Use context.spacing.screenEdge — value tightened 20→16 per v1.1 §2.3.')
  static const double screenHorizontal = 16;

  // NOTE: legacy `cardPadding` static dropped — name collides with the
  // v1.1 instance field. Grep showed 0 usages, so deletion is safe.
  // If a screen ever surfaces a reference, swap to context.spacing.cardPadding.

  @Deprecated('Use context.spacing.sectionGap — value retuned 40→32 per v1.1 §2.3.')
  static const double sectionTop = 32;

  @Deprecated('Use context.spacing.space6')
  static const double sectionBottom = 24;

  @Deprecated('Use context.spacing.space3')
  static const double cardGap = 12;

  @Deprecated('Use context.spacing.screenEdge — value tightened 20→16 per v1.1 §2.3.')
  static const double listRowInset = 16;

  @Deprecated('Use context.spacing.space8')
  static const double buttonBottom = 32;
}
