import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';

/// Stock indicator chip — UX_DESIGN_SYSTEM_V1.1.md §3.6.
/// 4px chip radius (NOT pill), tabPill typography.
///
/// Compact mode shows just the count (used as overlay on product cards).
/// Full mode shows count + "en stock" label (used in detail variant rows).
class StockChip extends StatelessWidget {
  const StockChip({
    super.key,
    required this.stock,
    this.compact = false,
  });

  final int stock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isOut = stock == 0;
    final isLow = stock <= 5 && !isOut;

    final Color bg;
    final Color fg;
    final String label;

    if (isOut) {
      bg = c.coralTint12;
      fg = c.coralFg;
      label = compact ? 'Rupture' : 'Rupture';
    } else if (isLow) {
      bg = c.coralTint12;
      fg = c.coralFg;
      label = compact ? '$stock' : '$stock en stock';
    } else {
      bg = c.greenTint12;
      fg = c.greenFg;
      label = compact ? '$stock' : '$stock en stock';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: 3,
      ),
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
