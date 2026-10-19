import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// DIDO motion tokens — v1.1
/// Source: UX_DESIGN_SYSTEM_V1.1.md §2.6
///
/// Single curve for the entire system. No springs, no bounces.
/// Access at runtime via `context.motion.X` (see AppThemeX).
@immutable
class AppMotion {
  /// Press feedback — scale 1 → 0.98 + light haptic.
  final Duration tap;

  /// Color/opacity state changes (focus ring fade).
  final Duration fast;

  /// Standard view/screen transitions, tab strip underline slide.
  final Duration base;

  /// Bottom sheet present/dismiss.
  final Duration sheet;

  /// Number count-up after data change (Home tile values).
  final Duration deliberate;

  /// The single easing curve for v1.1 — Apple-style ease-out.
  final Curve easeOut;

  const AppMotion({
    required this.tap,
    required this.fast,
    required this.base,
    required this.sheet,
    required this.deliberate,
    required this.easeOut,
  });

  static const AppMotion standard = AppMotion(
    tap: Duration(milliseconds: 80),
    fast: Duration(milliseconds: 120),
    base: Duration(milliseconds: 250),
    sheet: Duration(milliseconds: 320),
    deliberate: Duration(milliseconds: 600),
    easeOut: Cubic(0.2, 0, 0, 1),
  );
}
