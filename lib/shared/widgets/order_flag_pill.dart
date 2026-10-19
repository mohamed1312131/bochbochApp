import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import '../../features/orders/domain/order_models.dart';

/// FLUTTER_SPEC §2.9 — small pill rendered on each order list row to
/// surface secondary signals (VIP / COD / Bloqué / Retour / Échange).
///
/// Visual spec: 22px tall, 8px horizontal padding, radius 9999, font
/// 500 · 11/14. Color palette varies per [OrderFlag] kind. The
/// overflow `+N` variant uses the neutral surface bg.
class OrderFlagPill extends StatelessWidget {
  const OrderFlagPill({super.key, required this.flag}) : overflowCount = null;

  /// Overflow variant: `+N` pill. Pass [count] = the number of flags
  /// hidden by the 2-flag cap.
  const OrderFlagPill.overflow({super.key, required int count})
      : flag = null,
        overflowCount = count;

  final OrderFlag? flag;
  final int? overflowCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, text) = _styleFor(c);
    return Container(
      height: 22,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.typography.label.copyWith(color: fg),
      ),
    );
  }

  (Color, Color, String) _styleFor(dynamic c) {
    if (overflowCount != null) {
      return (c.surface2, c.fg3, '+$overflowCount');
    }
    switch (flag!) {
      case OrderFlag.vip:
        return (c.brandTealTint08, c.brandTeal, 'VIP');
      case OrderFlag.cod:
        return (c.surface2, c.fg2, 'COD');
      case OrderFlag.bloque:
        return (c.coralTint12, c.coralFg, 'Bloqué');
      case OrderFlag.retour:
        return (c.surface2, c.fg2, 'Retour en cours');
      case OrderFlag.echange:
        return (c.brandTealTint08, c.brandTeal, 'Échange en cours');
    }
  }
}
