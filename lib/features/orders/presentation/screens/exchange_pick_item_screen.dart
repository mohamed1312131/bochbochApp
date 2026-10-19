import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_product_image.dart';
import '../../../../shared/widgets/stock_chip.dart';
import '../../../products/domain/product_models.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../domain/exchange_models.dart';
import 'exchange_costs_screen.dart';

/// Screen 1 of the exchange flow — choose the swap target.
///
/// Loads the boutique's products via [productListProvider], lets the
/// seller pick a product (and a specific variant for multi-variant
/// products via a small modal sheet), then pushes
/// [ExchangeCostsScreen] with the updated draft.
class ExchangePickItemScreen extends ConsumerStatefulWidget {
  const ExchangePickItemScreen({super.key, required this.draft});

  final ExchangeDraft draft;

  @override
  ConsumerState<ExchangePickItemScreen> createState() =>
      _ExchangePickItemScreenState();
}

class _ExchangePickItemScreenState
    extends ConsumerState<ExchangePickItemScreen> {
  late ExchangeDraft _draft;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onProductTap(ProductLean product) async {
    try {
      final full = await ref
          .read(productRepositoryProvider)
          .getProduct(product.id);
      if (!mounted) return;
      if (full.variants.isEmpty) return;

      ProductVariant? selected;
      if (full.variants.length == 1) {
        selected = full.variants.first;
      } else {
        selected = await _pickVariant(full);
        if (selected == null) return;
      }

      setState(() {
        _draft = _draft.copyWith(
          target: ExchangeTargetVariant(
            productId: full.id,
            variantId: selected!.id,
            productName: full.name,
            attributes: {for (final a in selected.attributes) a.name: a.value},
            sellPrice: selected.effectiveSellPrice,
            // availableQuantity is the stock-aware figure (Chunk 8a);
            // fall back to the legacy stockQuantity if the variant
            // wasn't enriched.
            onHandQuantity:
                selected.availableQuantity ?? selected.stockQuantity,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de charger le produit'),
          backgroundColor: context.colors.red,
        ),
      );
    }
  }

  Future<ProductVariant?> _pickVariant(Product product) {
    return showModalBottomSheet<ProductVariant>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VariantPickerSheet(product: product),
    );
  }

  void _onContinue() {
    if (_draft.target == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExchangeCostsScreen(draft: _draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final productsAsync = ref.watch(productListProvider);
    final canContinue = _draft.target != null;

    return Scaffold(
      backgroundColor: c.surface1,
      appBar: AppBar(title: const Text('Échange · choisir l\'article')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.spacing.space4,
                context.spacing.space3,
                context.spacing.space4,
                context.spacing.space4,
              ),
              children: [
                if (_draft.original != null) ...[
                  _OriginalItemCard(snapshot: _draft.original!),
                  SizedBox(height: context.spacing.space4),
                ],
                _SearchField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                ),
                SizedBox(height: context.spacing.space3),
                _CategoryStrip(),
                SizedBox(height: context.spacing.space4),
                Padding(
                  padding: EdgeInsets.only(left: context.spacing.space2),
                  child: Text(
                    'ARTICLES DISPONIBLES',
                    style: context.typography.label.copyWith(color: c.fg3),
                  ),
                ),
                SizedBox(height: context.spacing.space2),
                productsAsync.when(
                  data: (products) {
                    final q = _query.trim().toLowerCase();
                    final filtered = q.isEmpty
                        ? products
                        : products
                              .where((p) => p.name.toLowerCase().contains(q))
                              .toList();
                    if (filtered.isEmpty) {
                      return _EmptyState(query: q);
                    }
                    return _ProductsCard(
                      products: filtered,
                      selectedTarget: _draft.target,
                      onTap: _onProductTap,
                    );
                  },
                  loading: () => Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.spacing.space6,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => _ErrorState(
                    onRetry: () => ref.invalidate(productListProvider),
                  ),
                ),
              ],
            ),
          ),
          _Footer(canContinue: canContinue, onContinue: _onContinue),
        ],
      ),
    );
  }
}

// ── Original item card ────────────────────────────────────
class _OriginalItemCard extends StatelessWidget {
  const _OriginalItemCard({required this.snapshot});
  final ExchangeOriginalSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space3),
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(context.radius.radiusInput),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.swap_horiz_rounded, color: c.fg3),
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARTICLE RETOURNÉ',
                  style: context.typography.label.copyWith(color: c.fg3),
                ),
                SizedBox(height: context.spacing.space1),
                Text(
                  snapshot.productName,
                  style: context.typography.h4.copyWith(color: c.fg1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (snapshot.attributesLabel.isNotEmpty ||
                    snapshot.unitPrice > 0)
                  Padding(
                    padding: EdgeInsets.only(top: context.spacing.space1),
                    child: Text(
                      [
                        if (snapshot.attributesLabel.isNotEmpty)
                          snapshot.attributesLabel,
                        MillimesFormatter.format(snapshot.unitPrice),
                      ].join(' · '),
                      style: context.typography.bodySmall.copyWith(
                        color: c.fg3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search field ──────────────────────────────────────────
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher un article…',
          prefixIcon: Icon(Icons.search, size: 20, color: c.fg3),
          isDense: true,
          filled: true,
          fillColor: c.surface2,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.brandTeal, width: 1),
          ),
        ),
      ),
    );
  }
}

// ── Category strip (single "Tous" pill in v1) ─────────────
// Multi-category filtering deferred to v1.x — the chip strip is
// laid out per spec but currently shows only the always-on
// "Tous" pill. When categories ship, populate from the products'
// distinct categories and add filter behavior.
class _CategoryStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.fg1,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            'Tous',
            style: context.typography.tabPill.copyWith(color: c.surface0),
          ),
        ),
      ],
    );
  }
}

// ── Products card ─────────────────────────────────────────
class _ProductsCard extends StatelessWidget {
  const _ProductsCard({
    required this.products,
    required this.selectedTarget,
    required this.onTap,
  });

  final List<ProductLean> products;
  final ExchangeTargetVariant? selectedTarget;
  final ValueChanged<ProductLean> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        children: [
          for (var i = 0; i < products.length; i++) ...[
            _ProductRow(
              product: products[i],
              isSelected: selectedTarget?.productId == products[i].id,
              onTap: () => onTap(products[i]),
            ),
            if (i < products.length - 1) Container(height: 1, color: c.border1),
          ],
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });
  final ProductLean product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isOut = product.totalStock <= 0;
    return InkWell(
      onTap: isOut ? null : onTap,
      child: Opacity(
        opacity: isOut ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: isSelected ? c.brandTealTint08 : Colors.transparent,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: product.primaryImageUrl != null
                      ? DidoProductImage(
                          imageUrl: product.primaryImageUrl!,
                          fit: BoxFit.cover,
                          placeholderBuilder: (_) =>
                              Container(color: c.surface2),
                          errorBuilder: (_) => Container(
                            color: c.surface2,
                            child: Icon(
                              Icons.image_outlined,
                              size: 18,
                              color: c.fg3,
                            ),
                          ),
                        )
                      : Container(
                          color: c.surface2,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: c.fg3,
                          ),
                        ),
                ),
              ),
              SizedBox(width: context.spacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: context.typography.bodyMd.copyWith(
                        color: isOut ? c.fg3 : c.fg1,
                        decoration: isOut ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.spacing.space1),
                    Text(
                      product.isMultiVariant
                          ? 'Plusieurs variantes · ${MillimesFormatter.format(product.baseSellPrice)}'
                          : MillimesFormatter.format(product.baseSellPrice),
                      style: context.typography.bodySmall.copyWith(
                        color: c.fg3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.spacing.space2),
              StockChip(stock: product.totalStock, compact: true),
              if (isSelected) ...[
                SizedBox(width: context.spacing.space2),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c.brandTeal,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.check, size: 14, color: c.surface0),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Variant picker (small modal sheet for multi-variant products) ──
class _VariantPickerSheet extends StatelessWidget {
  const _VariantPickerSheet({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: c.surface0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choisir une variante',
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
              ),
            ),
            Container(height: 1, color: c.border1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: product.variants.length,
                separatorBuilder: (_, __) =>
                    Container(height: 1, color: c.border1),
                itemBuilder: (_, i) {
                  final v = product.variants[i];
                  final stock = v.availableQuantity ?? v.stockQuantity;
                  final label = v.attributes.isEmpty
                      ? 'Default'
                      : v.attributes.map((a) => a.value).join(' · ');
                  return InkWell(
                    onTap: stock > 0 ? () => Navigator.pop(context, v) : null,
                    child: Opacity(
                      opacity: stock > 0 ? 1 : 0.55,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: context.typography.bodyMd.copyWith(
                                      color: c.fg1,
                                    ),
                                  ),
                                  SizedBox(height: context.spacing.space1),
                                  Text(
                                    MillimesFormatter.format(
                                      v.effectiveSellPrice,
                                    ),
                                    style: context.typography.bodySmall
                                        .copyWith(color: c.fg3),
                                  ),
                                ],
                              ),
                            ),
                            StockChip(stock: stock, compact: true),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: context.spacing.space3),
          ],
        ),
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final String query;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space5),
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      alignment: Alignment.center,
      child: Text(
        query.isEmpty
            ? 'Aucun produit dans le catalogue.'
            : 'Aucun résultat pour "$query".',
        style: context.typography.body.copyWith(color: c.fg3),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space5),
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: c.coralFg, size: 32),
          SizedBox(height: context.spacing.space2),
          Text(
            'Impossible de charger les produits',
            style: context.typography.body.copyWith(color: c.fg1),
          ),
          SizedBox(height: context.spacing.space3),
          DidoButton.secondary(
            label: 'Réessayer',
            onPressed: onRetry,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

// ── Fixed footer ──────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({required this.canContinue, required this.onContinue});
  final bool canContinue;
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.spacing.space4,
          context.spacing.space3,
          context.spacing.space4,
          context.spacing.space4,
        ),
        decoration: BoxDecoration(
          color: c.surface0,
          border: Border(top: BorderSide(color: c.border1)),
        ),
        child: DidoButton.primary(
          label: 'Continuer',
          onPressed: canContinue ? onContinue : null,
          enabled: canContinue,
        ),
      ),
    );
  }
}
