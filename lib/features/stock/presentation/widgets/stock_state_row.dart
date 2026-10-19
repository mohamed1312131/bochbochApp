import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';

/// Discrete stock-state categories — controls the quantity color
/// and the row's semantic meaning. Caller maps backend status to
/// one of these.
enum StockStateKind { neutral, available, reserved, backorder }

/// Stock state row — FLUTTER_SPEC §6 (state breakdown).
///
/// One row inside the "stock state" card on the product detail
/// screen. Header has an UPPERCASE label + a tabular-number quantity
/// (color-coded by [kind]). A description sits below, and an
/// optional `subItems` list renders as a left-border-indented column
/// (used for the RÉSERVÉ AUX COMMANDES variant that lists each
/// reserving order).
class StockStateRow extends StatelessWidget {
  const StockStateRow({
    super.key,
    required this.label,
    required this.quantity,
    required this.kind,
    required this.description,
    this.subItems,
    this.showBottomBorder = true,
  });

  final String label;
  final int quantity;
  final StockStateKind kind;
  final String description;
  final List<String>? subItems;
  final bool showBottomBorder;

  Color _quantityColor(BuildContext context) {
    final c = context.colors;
    switch (kind) {
      case StockStateKind.neutral:
        return c.fg1;
      case StockStateKind.available:
        return c.greenFg;
      case StockStateKind.reserved:
        return c.coralFg;
      case StockStateKind.backorder:
        return c.fg1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasSubItems = subItems != null && subItems!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(bottom: 18),
      decoration: showBottomBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.border1, width: 1),
              ),
            )
          : null,
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
                  style: context.typography.label.copyWith(color: c.fg3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$quantity',
                style: context.typography.tileNum.copyWith(
                  color: _quantityColor(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: context.typography.body.copyWith(
              color: c.fg2,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          if (hasSubItems) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: c.border1, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < subItems!.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    Text(
                      subItems![i],
                      style: context.typography.caption
                          .copyWith(color: c.fg2),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
