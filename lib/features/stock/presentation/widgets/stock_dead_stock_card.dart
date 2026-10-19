import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_card.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';

/// Dead-stock card — FLUTTER_SPEC §6.14.
///
/// Single row in the "Stock mort" list. 56×56 thumbnail + product
/// metadata + amount, with optional "Promouvoir" / "Solder" action
/// buttons below. The card body itself is tappable when [onTap] is
/// non-null (navigates to the product detail).
class StockDeadStockCard extends StatelessWidget {
  const StockDeadStockCard({
    super.key,
    required this.productName,
    required this.unitsLine,
    required this.categoryLine,
    required this.amount,
    this.thumbnailColor,
    this.thumbnailUrl,
    this.onPromote,
    this.onDiscount,
    this.onTap,
  });

  final String productName;
  final String unitsLine;
  final String categoryLine;
  final String amount;
  final Color? thumbnailColor;
  final String? thumbnailUrl;
  final VoidCallback? onPromote;
  final VoidCallback? onDiscount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasActions = onPromote != null || onDiscount != null;

    final card = DidoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(
                color: thumbnailColor ?? c.surface3,
                url: thumbnailUrl,
                radius: context.radius.radiusInput,
              ),
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
                            productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.typography.bodyMd
                                .copyWith(color: c.fg1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 70),
                          child: Text(
                            amount,
                            textAlign: TextAlign.right,
                            style: context.typography.bodyMdNum
                                .copyWith(color: c.fg1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unitsLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.bodySmall
                          .copyWith(color: c.fg3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.bodySmall
                          .copyWith(color: c.fg3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onPromote != null)
                  Expanded(
                    child: _ActionButton(
                      label: 'Promouvoir',
                      onTap: onPromote!,
                    ),
                  ),
                if (onPromote != null && onDiscount != null)
                  const SizedBox(width: 8),
                if (onDiscount != null)
                  Expanded(
                    child: _ActionButton(
                      label: 'Solder',
                      onTap: onDiscount!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return DidoScaleTap(onTap: onTap, child: card);
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.color,
    required this.url,
    required this.radius,
  });

  final Color color;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? null
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: c.surface3),
            ),
    );
    return box;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: c.border1, width: 1),
          borderRadius:
              BorderRadius.circular(context.radius.radiusInput),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.typography.smallMd.copyWith(color: c.fg1),
        ),
      ),
    );
  }
}
