import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';

/// v1.1 status badge — UX_DESIGN_SYSTEM_V1.1.md §3.6.
/// Chip-radius (4px), tabPill typography, padding 3 / 8.
/// Colors mapped from order status to v1.1 palette tokens.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, label) = switch (status) {
      'PENDING' => (c.surface2, c.fg2, 'En attente'),
      'CONFIRMED' => (c.surface2, c.fg1, 'Confirmée'),
      'SHIPPED' => (c.surface2, c.fg1, 'Expédiée'),
      'DELIVERED' => (c.greenTint12, c.greenFg, 'Livrée'),
      'CANCELLED' => (c.coralTint12, c.coralFg, 'Annulée'),
      'EXCHANGE_IN_PROGRESS' => (c.brandTealTint08, c.brandTeal, 'Échange en cours'),
      'ISSUE_OPEN' => (c.coralTint12, c.coralFg, 'Litige ouvert'),
      'RTO_IN_TRANSIT' => (c.coralTint12, c.coralFg, 'RTO en transit'),
      'RTO_RECEIVED' => (c.coralTint12, c.coralFg, 'RTO reçu'),
      'PARTIALLY_SHIPPED' => (c.brandTealTint08, c.brandTeal, 'Partiellement expédiée'),
      _ => (c.surface2, c.fg3, status),
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
