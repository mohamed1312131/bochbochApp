import 'package:flutter/material.dart';

/// DIDO shadow tokens — v1.1
/// Source: UX_DESIGN_SYSTEM_V1.1.md §2.5
///
/// Elevation language collapsed to TWO tokens. Cards, tiles, inputs,
/// buttons, and badges use 1px borders + spacing — never shadow.
/// Only the FAB has elevation.
///
/// Access at runtime via `context.shadows.X`.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  /// Empty list — default for cards, tiles, inputs, buttons, status badges.
  /// Use this everywhere except FAB.
  final List<BoxShadow> shadowNone;

  /// FAB drop shadow — the ONLY elevation in the system.
  /// Light: rgba(10,10,10,0.12), blur 12px, y-offset 4px.
  /// Dark:  rgba(0,0,0,0.5),    blur 12px, y-offset 4px.
  final List<BoxShadow> shadowFab;

  // ── Stock module additions (FLUTTER_SPEC.md §6.1, §6.5) ────
  /// Bottom-sheet rim shadow — sheet floats above scrim.
  /// Light: rgba(10,10,10,0.12), blur 32px, y-offset -8px.
  /// Dark:  rgba(0,0,0,0.5),     blur 32px, y-offset -8px.
  final List<BoxShadow> shadowSheet;

  /// Segmented control selected-thumb micro-shadow. Mode-agnostic.
  /// rgba(0,0,0,0.05), blur 2px, y-offset 1px.
  final List<BoxShadow> shadowSegmentedThumb;

  /// Toggle switch thumb shadow. Mode-agnostic.
  /// rgba(0,0,0,0.2), blur 3px, y-offset 1px.
  final List<BoxShadow> shadowToggle;

  const AppShadows({
    required this.shadowNone,
    required this.shadowFab,
    required this.shadowSheet,
    required this.shadowSegmentedThumb,
    required this.shadowToggle,
  });

  static const AppShadows light = AppShadows(
    shadowNone: <BoxShadow>[],
    shadowFab: <BoxShadow>[
      BoxShadow(
        color: Color(0x1F0A0A0A),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    shadowSheet: <BoxShadow>[
      BoxShadow(
        color: Color(0x1F0A0A0A),
        blurRadius: 32,
        offset: Offset(0, -8),
      ),
    ],
    shadowSegmentedThumb: <BoxShadow>[
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
    shadowToggle: <BoxShadow>[
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
    ],
  );

  static const AppShadows dark = AppShadows(
    shadowNone: <BoxShadow>[],
    shadowFab: <BoxShadow>[
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    shadowSheet: <BoxShadow>[
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 32,
        offset: Offset(0, -8),
      ),
    ],
    shadowSegmentedThumb: <BoxShadow>[
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
    shadowToggle: <BoxShadow>[
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
    ],
  );

  @override
  AppShadows copyWith({
    List<BoxShadow>? shadowNone,
    List<BoxShadow>? shadowFab,
    List<BoxShadow>? shadowSheet,
    List<BoxShadow>? shadowSegmentedThumb,
    List<BoxShadow>? shadowToggle,
  }) {
    return AppShadows(
      shadowNone: shadowNone ?? this.shadowNone,
      shadowFab: shadowFab ?? this.shadowFab,
      shadowSheet: shadowSheet ?? this.shadowSheet,
      shadowSegmentedThumb: shadowSegmentedThumb ?? this.shadowSegmentedThumb,
      shadowToggle: shadowToggle ?? this.shadowToggle,
    );
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      shadowNone: BoxShadow.lerpList(shadowNone, other.shadowNone, t) ?? const <BoxShadow>[],
      shadowFab: BoxShadow.lerpList(shadowFab, other.shadowFab, t) ?? const <BoxShadow>[],
      shadowSheet: BoxShadow.lerpList(shadowSheet, other.shadowSheet, t) ?? const <BoxShadow>[],
      shadowSegmentedThumb:
          BoxShadow.lerpList(shadowSegmentedThumb, other.shadowSegmentedThumb, t) ?? const <BoxShadow>[],
      shadowToggle: BoxShadow.lerpList(shadowToggle, other.shadowToggle, t) ?? const <BoxShadow>[],
    );
  }

  // ════════════════════════════════════════════════════════
  // LEGACY STATIC ALIASES — RETUNED TO EMPTY
  // ════════════════════════════════════════════════════════
  // v1.1 §2.5: cards use borders + spacing, not shadows.
  // All v1.0 elevation tokens resolve to an empty list. Existing
  // callers will lose their drop shadows — that's the intent.
  // (Audit confirmed zero direct usage of these statics; the real
  // shadow consumers go through AppThemeX.appCardShadow, which
  // Prompt 7 will neutralize.)

  @Deprecated('ELEVATION removed per v1.1 §2.5 — cards use borders + spacing. Use context.shadows.shadowNone.')
  static const List<BoxShadow> xs = <BoxShadow>[];

  @Deprecated('ELEVATION removed per v1.1 §2.5. Use context.shadows.shadowNone.')
  static const List<BoxShadow> sm = <BoxShadow>[];

  @Deprecated('ELEVATION removed per v1.1 §2.5. Use context.shadows.shadowNone.')
  static const List<BoxShadow> md = <BoxShadow>[];

  @Deprecated('ELEVATION removed per v1.1 §2.5. Use context.shadows.shadowNone.')
  static const List<BoxShadow> lg = <BoxShadow>[];

  @Deprecated('ELEVATION removed per v1.1 §2.5. Use context.shadows.shadowNone.')
  static const List<BoxShadow> xl = <BoxShadow>[];

  @Deprecated('Use context.shadows.shadowNone.')
  static const List<BoxShadow> none = <BoxShadow>[];
}
