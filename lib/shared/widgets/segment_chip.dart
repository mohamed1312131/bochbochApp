import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';

/// Customer segment chip — UX_DESIGN_SYSTEM_V1.1.md §3.6.
/// 4px chip radius (NOT pill), tabPill typography.
///
/// Backend segment codes are mapped to v1.1's three semantic groups:
/// positive (green tint), attention (coral tint), neutral (surface2).
class SegmentChip extends StatelessWidget {
  const SegmentChip({super.key, required this.segment});

  final String segment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg, String label) = switch (segment) {
      'VIP' => (c.greenTint12, c.greenFg, 'VIP'),
      'LOYAL' => (c.greenTint12, c.greenFg, 'Fidèle'),
      'AT_RISK' => (c.coralTint12, c.coralFg, 'À risque'),
      'NEW' => (c.surface2, c.fg2, 'Nouveau'),
      'RETURNER' => (c.surface2, c.fg2, 'De retour'),
      _ => (c.surface2, c.fg3, segment),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.radius.radiusChip),
      ),
      child: Text(
        label,
        style: context.typography.tabPill.copyWith(color: fg),
      ),
    );
  }
}
