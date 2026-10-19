import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_card.dart';
import '../../../stock/presentation/providers/stock_provider.dart';
import '../../../stock/presentation/sheets/adjust_stock_sheet.dart';
import '../../../stock/presentation/sheets/restock_sheet.dart';
import '../../../stock/presentation/sheets/stock_state_sheet.dart';
import '../../domain/product_models.dart';

/// Stock tab body for the product detail screen — FLUTTER_SPEC §7.5.
///
/// Renders one card per active variant. Each card shows the
/// onHand/available/committed/backordered breakdown (tap to inspect
/// in [showStockStateSheet]) and exposes Restocker / Ajuster sheets.
class ProductStockTab extends ConsumerWidget {
  const ProductStockTab({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = product.variants.where((v) => v.isActive).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < variants.length; i++) ...[
            _VariantStockCard(product: product, variant: variants[i]),
            if (i < variants.length - 1) const SizedBox(height: 16),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _VariantStockCard extends ConsumerWidget {
  const _VariantStockCard({required this.product, required this.variant});

  final Product product;
  final ProductVariant variant;

  String get _variantLabel =>
      variant.isSimple ? 'Standard' : variant.attributeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final stateAsync = ref.watch(stockStateProvider(variant.id));
    final state = stateAsync.valueOrNull;
    final onHand = state?.onHand ?? 0;
    final available = state?.available ?? 0;
    final committed = state?.committed ?? 0;
    final backordered = state?.backordered ?? 0;

    return DidoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _variantLabel,
                      style: context.typography.bodyMd.copyWith(color: c.fg1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      variant.sku,
                      style:
                          context.typography.caption.copyWith(color: c.fg3),
                    ),
                  ],
                ),
              ),
              if (backordered > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.coralTint12,
                    borderRadius:
                        BorderRadius.circular(context.radius.radiusChip),
                  ),
                  child: Text(
                    'Backorder',
                    style:
                        context.typography.tabPill.copyWith(color: c.coralFg),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showStockStateSheet(
              context: context,
              variantId: variant.id,
              productName: product.name,
              variantLabel: _variantLabel,
            ),
            child: stateAsync.when(
              loading: () => Column(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(
                            context.radius.radiusInput),
                      ),
                    ),
                    if (i < 3) const SizedBox(height: 8),
                  ],
                ],
              ),
              error: (_, __) => Text(
                'Erreur de chargement',
                style: context.typography.bodySmall.copyWith(color: c.redFg),
              ),
              data: (_) => Column(
                children: [
                  _StateLine(
                    icon: Icons.inventory_2_outlined,
                    label: '$onHand en stock physique',
                    color: c.fg1,
                  ),
                  const SizedBox(height: 8),
                  _StateLine(
                    icon: Icons.check_circle_outline,
                    label: '$available disponible',
                    color: c.greenFg,
                  ),
                  const SizedBox(height: 8),
                  _StateLine(
                    icon: Icons.access_time,
                    label: '$committed réservé',
                    color: c.coralFg,
                  ),
                  const SizedBox(height: 8),
                  _StateLine(
                    icon: Icons.schedule,
                    label: '$backordered backorder',
                    color: c.fg1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Seuil d'alerte : par défaut",
            style: context.typography.caption.copyWith(color: c.fg3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DidoButton.secondary(
                  label: 'Restocker',
                  fullWidth: true,
                  onPressed: () => showRestockSheet(
                    context: context,
                    variantId: variant.id,
                    productName: product.name,
                    variantSubtitle:
                        '$_variantLabel · Stock actuel : $onHand',
                    currentStock: onHand,
                    currentWacMillimes: variant.effectiveCostPrice,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DidoButton.secondary(
                  label: 'Ajuster',
                  fullWidth: true,
                  onPressed: () => showAdjustStockSheet(
                    context: context,
                    variantId: variant.id,
                    productName: product.name,
                    variantSubtitle:
                        '$_variantLabel · Stock actuel : $onHand',
                    currentStock: onHand,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StateLine extends StatelessWidget {
  const _StateLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: context.typography.body.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
