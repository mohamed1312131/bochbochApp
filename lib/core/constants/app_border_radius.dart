import 'dart:ui';
import 'package:flutter/material.dart';

/// DIDO radius tokens — v1.1
/// Source: UX_DESIGN_SYSTEM_V1.1.md §2.4
///
/// Buttons use radiusInput (8px), NOT pill shape.
/// Status badges use radiusChip (4px). Avatars and FAB use radiusFull.
/// Access at runtime via `context.radius.X`.
@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  /// 4px — status badges, segment pills.
  final double radiusChip;

  /// 8px — inputs, buttons, product thumbnails, compact stat tiles.
  final double radiusInput;

  /// 8px — dashboard tiles.
  final double radiusTile;

  /// 12px — cards, list-item containers, identity blocks.
  final double radiusCard;

  /// 16px — bottom sheet top corners, hero tiles.
  final double radiusSheet;

  /// 9999px — avatars, FAB, communication action circles.
  final double radiusFull;

  const AppRadius({
    required this.radiusChip,
    required this.radiusInput,
    required this.radiusTile,
    required this.radiusCard,
    required this.radiusSheet,
    required this.radiusFull,
  });

  static const AppRadius standard = AppRadius(
    radiusChip: 4,
    radiusInput: 8,
    radiusTile: 8,
    radiusCard: 12,
    radiusSheet: 16,
    radiusFull: 9999,
  );

  @override
  AppRadius copyWith({
    double? radiusChip,
    double? radiusInput,
    double? radiusTile,
    double? radiusCard,
    double? radiusSheet,
    double? radiusFull,
  }) {
    return AppRadius(
      radiusChip: radiusChip ?? this.radiusChip,
      radiusInput: radiusInput ?? this.radiusInput,
      radiusTile: radiusTile ?? this.radiusTile,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusSheet: radiusSheet ?? this.radiusSheet,
      radiusFull: radiusFull ?? this.radiusFull,
    );
  }

  @override
  AppRadius lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      radiusChip: lerpDouble(radiusChip, other.radiusChip, t)!,
      radiusInput: lerpDouble(radiusInput, other.radiusInput, t)!,
      radiusTile: lerpDouble(radiusTile, other.radiusTile, t)!,
      radiusCard: lerpDouble(radiusCard, other.radiusCard, t)!,
      radiusSheet: lerpDouble(radiusSheet, other.radiusSheet, t)!,
      radiusFull: lerpDouble(radiusFull, other.radiusFull, t)!,
    );
  }

  // ════════════════════════════════════════════════════════
  // LEGACY STATIC ALIASES — v1.0 → v1.1 migration shim
  // ════════════════════════════════════════════════════════

  @Deprecated('Use context.radius.radiusChip')
  static const double xs = 4;

  @Deprecated('Use context.radius.radiusInput')
  static const double sm = 8;

  @Deprecated('Use context.radius.radiusCard')
  static const double md = 12;

  @Deprecated('Use context.radius.radiusSheet')
  static const double lg = 16;

  @Deprecated('Use context.radius.radiusSheet — value tightened 20→16 per v1.1 §2.4 (off-grid 20 dropped).')
  static const double xl = 16;

  @Deprecated('No v1.1 equivalent — radius scale stops at 16 before jumping to full. Audit usage and replace per case.')
  static const double xxl = 24;

  @Deprecated('Use context.radius.radiusFull')
  static const double full = 9999;
}
