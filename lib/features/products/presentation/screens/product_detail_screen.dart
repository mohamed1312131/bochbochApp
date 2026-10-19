import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_tab_strip.dart';
import '../../../../shared/widgets/stock_chip.dart';
import '../../domain/product_models.dart';
import '../providers/product_provider.dart';
import '../widgets/product_history_tab.dart';
import '../widgets/product_stock_tab.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: context.colors.surface0,
      body: productAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (_, __) => _DetailError(
          onRetry: () =>
              ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) => _ProductDetailContent(product: product),
      ),
    );
  }
}

class _ProductDetailContent extends ConsumerStatefulWidget {
  const _ProductDetailContent({required this.product});
  final Product product;

  @override
  ConsumerState<_ProductDetailContent> createState() =>
      _ProductDetailContentState();
}

class _ProductDetailContentState
    extends ConsumerState<_ProductDetailContent> {
  int _currentImageIndex = 0;
  int _activeTab = 0;

  Future<void> _confirmDelete() async {
    final c = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: c.surface1,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(context.radius.radiusSheet),
        ),
        title: Text(
          'Supprimer ce produit ?',
          style: context.typography.h4.copyWith(color: c.fg1),
        ),
        content: Text(
          'Cette action est irréversible.',
          style: context.typography.bodyMd.copyWith(color: c.fg2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Annuler',
              style: context.typography.button.copyWith(color: c.fg2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'Supprimer',
              style: context.typography.button.copyWith(color: c.coralFg),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    try {
      await ref
          .read(productRepositoryProvider)
          .deleteProduct(widget.product.id);
      ref
          .read(productListProvider.notifier)
          .removeProduct(widget.product.id);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: context.colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final product = widget.product;
    final images = product.images;
    final profitPerUnit = product.baseSellPrice - product.baseCostPrice;
    final profitMarginPct = product.baseSellPrice > 0
        ? (profitPerUnit / product.baseSellPrice * 100).toStringAsFixed(1)
        : '0';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroImage(
            images: images,
            currentIndex: _currentImageIndex,
            onPageChanged: (i) =>
                setState(() => _currentImageIndex = i),
            onBack: () => context.pop(),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.screenEdge,
            context.spacing.screenEdge,
            context.spacing.screenEdge,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: context.typography.h2.copyWith(color: c.fg1),
                    ),
                  ),
                  SizedBox(width: context.spacing.space2),
                  _ActiveBadge(active: product.isActive),
                ],
              ),
              if (product.category != null) ...[
                SizedBox(height: context.spacing.space2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CategoryChip(label: product.category!),
                ),
              ],
              if (product.description != null) ...[
                SizedBox(height: context.spacing.space3),
                Text(
                  product.description!,
                  style: context.typography.bodyMd
                      .copyWith(color: c.fg2, height: 1.5),
                ),
              ],
              SizedBox(height: context.spacing.space5),
              DidoTabStrip(
                tabs: const ['Détails', 'Stock', 'Historique'],
                activeIndex: _activeTab,
                onTabTap: (i) => setState(() => _activeTab = i),
              ),
              SizedBox(height: context.spacing.space4),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: switch (_activeTab) {
            1 => ProductStockTab(product: product),
            2 => ProductHistoryTab(product: product),
            _ => Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.screenEdge),
                child: _DetailsTab(
                  product: product,
                  profitPerUnit: profitPerUnit,
                  profitMarginPct: profitMarginPct,
                  onDelete: _confirmDelete,
                ),
              ),
          },
        ),
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({
    required this.product,
    required this.profitPerUnit,
    required this.profitMarginPct,
    required this.onDelete,
  });

  final Product product;
  final int profitPerUnit;
  final String profitMarginPct;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prix',
            style: context.typography.h4.copyWith(color: c.fg1)),
        SizedBox(height: context.spacing.space3),
        _PricingCard(
          cost: product.baseCostPrice,
          sell: product.baseSellPrice,
          profit: profitPerUnit,
          pct: profitMarginPct,
        ),
        SizedBox(height: context.spacing.space6),
        Row(
          children: [
            Text('Stock',
                style: context.typography.h4.copyWith(color: c.fg1)),
            const Spacer(),
            Text(
              'Total : ${product.totalStock} unités',
              style:
                  context.typography.bodySmall.copyWith(color: c.fg3),
            ),
          ],
        ),
        SizedBox(height: context.spacing.space3),
        _VariantsCard(variants: product.variants),
        SizedBox(height: context.spacing.space6),
        Row(
          children: [
            Expanded(
              child: DidoButton.secondary(
                label: 'Modifier',
                icon: Icons.edit_outlined,
                onPressed: () => context.push(
                  '/products/${product.id}/edit',
                  extra: product,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: DidoButton.destructive(
                label: 'Supprimer',
                icon: Icons.delete_outline_rounded,
                onPressed: onDelete,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.space6),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Hero image
// ════════════════════════════════════════════════════════════
class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onBack,
  });

  final List<ProductImage> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: images.isNotEmpty
              ? PageView.builder(
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: images[i].url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: c.surface2),
                    errorWidget: (_, __, ___) => Container(
                      color: c.surface2,
                      alignment: Alignment.center,
                      child: Icon(Icons.inventory_2_outlined,
                          size: 48, color: c.fg3),
                    ),
                  ),
                )
              : Container(
                  color: c.surface2,
                  alignment: Alignment.center,
                  child: Icon(Icons.inventory_2_outlined,
                      size: 64, color: c.fg3),
                ),
        ),
        // Bottom scrim for legibility (uses scrim token; transparent-end
        // expressed as scrim with alpha 0 to keep it token-derived).
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [c.scrim, c.scrim.withAlpha(0)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: _OverlayButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: context.motion.base,
                  curve: context.motion.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: currentIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: currentIndex == i
                        ? c.surface0
                        : c.surface0.withAlpha(127),
                    borderRadius:
                        BorderRadius.circular(context.radius.radiusFull),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.92,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: c.fg1, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: c.surface0, size: 16),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Active badge — neutral chip per §3.6 (fg-1 solid for ACTIVE)
// ════════════════════════════════════════════════════════════
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, label) = active
        ? (c.fg1, c.surface0, 'Actif')
        : (c.surface2, c.fg2, 'Inactif');
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

// ════════════════════════════════════════════════════════════
// Category chip — neutral, NO teal (Rule 3)
// ════════════════════════════════════════════════════════════
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(context.radius.radiusChip),
      ),
      child: Text(
        label,
        style: context.typography.tabPill.copyWith(color: c.fg2),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Pricing card
// ════════════════════════════════════════════════════════════
class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.cost,
    required this.sell,
    required this.profit,
    required this.pct,
  });

  final int cost;
  final int sell;
  final int profit;
  final String pct;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _PriceRow(label: "Prix d'achat", value: MillimesFormatter.format(cost)),
          Container(height: 1, color: c.border1),
          _PriceRow(label: 'Prix de vente', value: MillimesFormatter.format(sell)),
          Container(height: 1, color: c.border1),
          _PriceRow(
            label: 'Bénéfice par vente',
            value: '+${MillimesFormatter.format(profit)} ($pct %)',
            valueColor: c.greenFg,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueStyle = isBold
        ? context.typography.bodyMd.copyWith(
            color: valueColor ?? c.fg1,
            fontWeight: FontWeight.w700,
          )
        : context.typography.bodyMd.copyWith(color: valueColor ?? c.fg1);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space4,
        vertical: context.spacing.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: context.typography.body.copyWith(color: c.fg2)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Variants card
// ════════════════════════════════════════════════════════════
class _VariantsCard extends StatelessWidget {
  const _VariantsCard({required this.variants});
  final List<ProductVariant> variants;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = variants.where((v) => v.isActive).toList();
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < active.length; i++) ...[
            _VariantRow(variant: active[i]),
            if (i < active.length - 1)
              Container(height: 1, color: c.border1),
          ],
        ],
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({required this.variant});
  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space4,
        vertical: context.spacing.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.isSimple ? 'Standard' : variant.attributeLabel,
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space1),
                Text(
                  variant.sku,
                  style:
                      context.typography.bodySmall.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          StockChip(stock: variant.stockQuantity),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Skeleton + error
// ════════════════════════════════════════════════════════════
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget bar({required double w, required double h}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(4),
        ),
      ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
            duration: const Duration(milliseconds: 1500),
            color: c.surface3,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 320,
          width: double.infinity,
          color: c.surface2,
        ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
              duration: const Duration(milliseconds: 1500),
              color: c.surface3,
            ),
        Padding(
          padding: EdgeInsets.all(context.spacing.screenEdge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(w: 220, h: 24),
              SizedBox(height: context.spacing.space2),
              bar(w: 100, h: 14),
              SizedBox(height: context.spacing.space6),
              bar(w: 80, h: 16),
              SizedBox(height: context.spacing.space3),
              Container(
                height: 144,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius:
                      BorderRadius.circular(context.radius.radiusCard),
                ),
              ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
                    duration: const Duration(milliseconds: 1500),
                    color: c.surface3,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Impossible de charger le produit',
              textAlign: TextAlign.center,
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space4),
            DidoButton.secondary(
              label: 'Réessayer',
              onPressed: onRetry,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Tap feedback (TODO(extract))
// ════════════════════════════════════════════════════════════
class _ScaleTap extends StatefulWidget {
  const _ScaleTap({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.98,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;
  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) {
              _set(true);
              HapticFeedback.lightImpact();
            },
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _set(false);
              widget.onTap!();
            },
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: context.motion.tap,
        curve: context.motion.easeOut,
        child: widget.child,
      ),
    );
  }
}
