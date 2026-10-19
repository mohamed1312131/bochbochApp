import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';

/// Stock movement category — drives icon + tint on the history row.
enum StockHistoryKind { sold, restock, broken, gift }

/// Stock history row — FLUTTER_SPEC §6.15.
///
/// Single audit-log line: kind-tinted icon circle, label + signed
/// delta in the top row, subtitle + optional photo indicator +
/// before→after counters in the bottom row.
class StockHistoryRow extends StatelessWidget {
  const StockHistoryRow({
    super.key,
    required this.kind,
    required this.label,
    required this.delta,
    required this.subtitle,
    required this.quantityBefore,
    required this.quantityAfter,
    this.hasPhoto = false,
    this.showBottomBorder = true,
  });

  final StockHistoryKind kind;
  final String label;
  final int delta;
  final String subtitle;
  final int quantityBefore;
  final int quantityAfter;
  final bool hasPhoto;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final deltaText = delta > 0 ? '+$delta' : '$delta';
    final deltaColor = delta > 0
        ? c.greenFg
        : (delta < 0 ? c.redFg : c.fg1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: showBottomBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.border1, width: 1),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconCircle(kind: kind),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.bodyMd
                            .copyWith(color: c.fg1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      deltaText,
                      style: context.typography.delta
                          .copyWith(color: deltaColor),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.bodySmall
                            .copyWith(color: c.fg3),
                      ),
                    ),
                    if (hasPhoto) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.image_outlined, size: 14, color: c.fg3),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '$quantityBefore→$quantityAfter',
                      style: context.typography.caption.copyWith(
                        color: c.fg3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.kind});

  final StockHistoryKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, IconData icon, Color iconColor) = switch (kind) {
      StockHistoryKind.sold => (
          c.brandTealTint08,
          Icons.shopping_bag_outlined,
          c.brandTeal,
        ),
      StockHistoryKind.restock => (
          c.greenTint12,
          Icons.inventory_2_outlined,
          c.greenFg,
        ),
      StockHistoryKind.broken => (
          c.coralTint12,
          Icons.warning_amber_rounded,
          c.coralFg,
        ),
      StockHistoryKind.gift => (
          c.brandTealTint08,
          Icons.auto_awesome,
          c.brandTeal,
        ),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: iconColor),
    );
  }
}
