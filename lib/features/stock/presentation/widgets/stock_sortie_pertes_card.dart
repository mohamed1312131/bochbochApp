import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_card.dart';

/// One line in a [StockSortiePertesCard]. Caller pre-formats the
/// `count` and `amount` strings — the widget treats them as opaque.
class StockBreakdownRow {
  const StockBreakdownRow({
    required this.label,
    required this.count,
    required this.amount,
  });

  final String label;
  final String count;
  final String amount;
}

/// Sortie / Pertes breakdown card — FLUTTER_SPEC §6.13.
///
/// Two-column rows with a bordered total row. Used for "Sortie
/// hors-vente" and "Pertes" tables on the stock dashboard.
/// `totalAmountColor` overrides the total amount color (e.g.
/// `c.redFg` for the Pertes total).
class StockSortiePertesCard extends StatelessWidget {
  const StockSortiePertesCard({
    super.key,
    required this.rows,
    required this.total,
    this.totalAmountColor,
  });

  final List<StockBreakdownRow> rows;
  final StockBreakdownRow total;
  final Color? totalAmountColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _BreakdownRowView(
                row: row,
                labelStyle: context.typography.body.copyWith(
                  color: c.fg2,
                  fontSize: 14,
                  height: 20 / 14,
                ),
                amountStyle: context.typography.bodyMdNum
                    .copyWith(color: c.fg1),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.border1, width: 1),
              ),
            ),
            child: _BreakdownRowView(
              row: total,
              labelStyle: context.typography.bodyMd.copyWith(color: c.fg1),
              amountStyle: context.typography.delta.copyWith(
                color: totalAmountColor ?? c.fg1,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRowView extends StatelessWidget {
  const _BreakdownRowView({
    required this.row,
    required this.labelStyle,
    required this.amountStyle,
  });

  final StockBreakdownRow row;
  final TextStyle labelStyle;
  final TextStyle amountStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Label gets flex:3 so longer reason names ("Cassé / endommagé",
        // "Cadeaux influenceurs") don't get prematurely ellipsized when
        // count/amount happen to be short.
        Expanded(
          flex: 3,
          child: Text(
            row.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Text(
            row.count,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typography.caption.copyWith(color: c.fg3),
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 80),
          child: Text(
            row.amount,
            textAlign: TextAlign.right,
            style: amountStyle,
          ),
        ),
      ],
    );
  }
}
