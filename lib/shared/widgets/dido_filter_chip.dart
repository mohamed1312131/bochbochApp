import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_scale_tap.dart';

/// Pill filter chip — UX_DESIGN_SYSTEM_V1.1.md §3.6.
///
/// Used for list-filter rows ("Toutes / En rupture") and period
/// chips ("60 jours ▾"). NOT to be confused with [SegmentChip] /
/// [StatusBadge] / [StockChip] which are 4px-radius badges.
///
/// Pass `showChevron: true` for the period-picker variant and
/// `leadingIcon` for the icon + label variant.
class DidoFilterChip extends StatelessWidget {
  const DidoFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showChevron = false,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showChevron;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = selected ? c.fg1 : c.surface1;
    final fg = selected ? c.surface1 : c.fg1;
    final chevronColor = selected ? c.surface1 : c.fg3;

    return DidoScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: selected ? null : Border.all(color: c.border1, width: 1),
          borderRadius: BorderRadius.circular(context.radius.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: context.typography.smallMd.copyWith(color: fg),
            ),
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: chevronColor),
            ],
          ],
        ),
      ),
    );
  }
}
