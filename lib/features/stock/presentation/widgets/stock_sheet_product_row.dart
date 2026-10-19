import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_card.dart';

/// Product header row used at the top of stock-adjust / restock
/// bottom sheets — FLUTTER_SPEC §6.2.
///
/// 44×44 thumbnail (color tone or image) + product name + subtitle.
/// Wrapped in a [DidoCard] so the row sits on a bordered surface
/// inside the sheet body.
class StockSheetProductRow extends StatelessWidget {
  const StockSheetProductRow({
    super.key,
    required this.productName,
    required this.subtitle,
    this.thumbnailColor,
    this.thumbnailUrl,
  });

  final String productName;
  final String subtitle;
  final Color? thumbnailColor;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = thumbnailColor ?? c.surface3;

    return DidoCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Thumbnail(
            color: tone,
            url: thumbnailUrl,
            radius: context.radius.radiusTile,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.bodyMd.copyWith(color: c.fg1),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      context.typography.bodySmall.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    return Container(
      width: 44,
      height: 44,
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
              errorBuilder: (_, __, ___) => Container(color: color),
            ),
    );
  }
}
