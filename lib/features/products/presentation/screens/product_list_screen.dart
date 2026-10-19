import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/providers/user_name_provider.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_filter_chip.dart';
import '../../../../shared/widgets/stock_chip.dart';
import '../../domain/product_models.dart';
import '../providers/product_provider.dart';

enum ProductListFilter { all, lowStock, outOfStock }

// TODO(home): wire to real data — boutique provider
const _mockBoutiqueName = 'Boutique Sania';
const _mockBoutiqueInitial = 'S';

// TODO(notifs): wire to real data — notifications provider
const _mockHasUnreadNotifs = true;

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() =>
      _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';
  ProductListFilter _filter = ProductListFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final productsAsync = ref.watch(productListProvider);
    final userAsync = ref.watch(userNameProvider);
    final userInitial = userAsync.maybeWhen(
      data: (name) => name.isNotEmpty ? name[0].toUpperCase() : 'M',
      orElse: () => 'M',
    );

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.screenEdge,
                context.spacing.space4,
                context.spacing.screenEdge,
                context.spacing.space2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _BoutiqueChip(),
                  _UserAvatar(initial: userInitial),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.screenEdge,
                vertical: context.spacing.space3,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Produits',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.screenEdge,
                0,
                context.spacing.screenEdge,
                context.spacing.space3,
              ),
              child: _SearchInput(
                controller: _searchController,
                hint: 'Nom, catégorie…',
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.screenEdge,
                0,
                context.spacing.screenEdge,
                context.spacing.space2,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DidoFilterChip(
                      label: 'Toutes',
                      selected: _filter == ProductListFilter.all,
                      onTap: () => setState(
                          () => _filter = ProductListFilter.all),
                    ),
                    const SizedBox(width: 8),
                    DidoFilterChip(
                      label: 'Bientôt en rupture',
                      selected: _filter == ProductListFilter.lowStock,
                      onTap: () => setState(
                          () => _filter = ProductListFilter.lowStock),
                    ),
                    const SizedBox(width: 8),
                    DidoFilterChip(
                      label: 'En rupture',
                      selected: _filter == ProductListFilter.outOfStock,
                      onTap: () => setState(
                          () => _filter = ProductListFilter.outOfStock),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: productsAsync.when(
                loading: () => const _ProductGridSkeleton(),
                error: (_, __) => _ErrorState(
                  onRetry: () =>
                      ref.read(productListProvider.notifier).refresh(),
                ),
                data: (products) {
                  if (products.isEmpty) return const _EmptyState();
                  final filtered = _applyFilters(products);
                  if (filtered.isEmpty) {
                    return _NoSearchResults(query: _query);
                  }
                  return RefreshIndicator(
                    color: c.fg1,
                    onRefresh: () =>
                        ref.read(productListProvider.notifier).refresh(),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.spacing.screenEdge,
                            context.spacing.space2,
                            context.spacing.screenEdge,
                            context.spacing.space3,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'CATALOGUE · ${filtered.length} ${filtered.length == 1 ? 'ARTICLE' : 'ARTICLES'}',
                              style: context.typography.label.copyWith(
                                color: c.fg3,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ProductGrid(
                            products: filtered,
                            scrollController: _scrollController,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const _Fab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  List<ProductLean> _applyFilters(List<ProductLean> products) {
    Iterable<ProductLean> result = products;
    if (_query.isNotEmpty) {
      result = result.where((p) =>
          p.name.toLowerCase().contains(_query) ||
          (p.category?.toLowerCase().contains(_query) ?? false));
    }
    switch (_filter) {
      case ProductListFilter.all:
        break;
      case ProductListFilter.lowStock:
        result = result.where((p) => p.hasLowStock && p.totalStock > 0);
        break;
      case ProductListFilter.outOfStock:
        result = result.where((p) => p.totalStock <= 0);
        break;
    }
    return result.toList();
  }
}

// ════════════════════════════════════════════════════════════
// Header pieces (duplicated — TODO(extract))
// ════════════════════════════════════════════════════════════
class _BoutiqueChip extends StatelessWidget {
  const _BoutiqueChip();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: () {
        // TODO(home): open boutique switcher bottom sheet
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: c.brandTeal,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _mockBoutiqueInitial,
                style: context.typography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.surface0,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Text(
              _mockBoutiqueName,
              style: context.typography.bodyMd.copyWith(color: c.fg1),
            ),
            SizedBox(width: context.spacing.space1),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: c.fg3),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: () => context.push('/settings'),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.brandTealTint08,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: context.typography.bodySmallMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.brandTeal,
                ),
              ),
            ),
            if (_mockHasUnreadNotifs)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.surface0, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Search input (§3.8)
// ════════════════════════════════════════════════════════════
class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(context.radius.radiusInput),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: context.typography.input.copyWith(color: c.fg1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.typography.input.copyWith(color: c.fg3),
          prefixIcon: Icon(Icons.search_rounded, color: c.fg3, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Product grid (YSL-inspired — no card wrapper)
// ════════════════════════════════════════════════════════════
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.scrollController,
  });

  final List<ProductLean> products;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        context.spacing.screenEdge,
        0,
        context.spacing.screenEdge,
        100,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: context.spacing.space6,
        crossAxisSpacing: context.spacing.space3,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(product: products[i]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final ProductLean product;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profit = product.profitMargin;
    final showStockBadge = product.totalStock <= 5;

    return _ScaleTap(
      onTap: () => context.push('/products/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius:
                    BorderRadius.circular(context.radius.radiusCard),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.primaryImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: product.primaryImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 32,
                          color: c.fg3,
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 32,
                        color: c.fg3,
                      ),
                    ),
                  if (showStockBadge)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: StockChip(
                        stock: product.totalStock,
                        compact: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.spacing.space2),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typography.h4.copyWith(color: c.fg1),
          ),
          SizedBox(height: context.spacing.space1),
          Row(
            children: [
              Text(
                MillimesFormatter.format(product.baseSellPrice),
                style: context.typography.bodyMd.copyWith(
                  color: c.fg1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: context.spacing.space2),
              if (profit > 0)
                Text(
                  '+${MillimesFormatter.format(profit)}',
                  style: context.typography.bodySmall.copyWith(
                    color: c.greenFg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          if (product.totalStock <= 0) ...[
            SizedBox(height: context.spacing.space1),
            _InlineStockBadge(
              label: 'Rupture',
              bg: c.coralTint12,
              fg: c.redFg,
            ),
          ] else if (product.hasLowStock) ...[
            SizedBox(height: context.spacing.space1),
            _InlineStockBadge(
              label: 'Bientôt en rupture',
              bg: c.coralTint12,
              fg: c.coralFg,
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Empty / error / no-search-result / skeleton
// ════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Aucun produit',
              style: context.typography.h3.copyWith(color: c.fg2),
            ),
            SizedBox(height: context.spacing.space1),
            Text(
              'Ajoute ton premier produit pour commencer.',
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
            SizedBox(height: context.spacing.space4),
            DidoButton.primary(
              label: 'Ajouter un produit',
              onPressed: () => context.push('/products/add'),
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 32, color: c.fg3),
            SizedBox(height: context.spacing.space2),
            Text(
              'Aucun résultat pour « $query »',
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Impossible de charger les produits',
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

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        context.spacing.screenEdge,
        context.spacing.space6,
        context.spacing.screenEdge,
        100,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: context.spacing.space6,
        crossAxisSpacing: context.spacing.space3,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius:
                      BorderRadius.circular(context.radius.radiusCard),
                ),
              ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
                    duration: const Duration(milliseconds: 1500),
                    color: c.surface3,
                  ),
            ),
            SizedBox(height: context.spacing.space2),
            bar(w: 120, h: 14),
            SizedBox(height: context.spacing.space1),
            bar(w: 80, h: 12),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// FAB (§3.9 — bottom-right floating, fg-1, shadow-fab)
// ════════════════════════════════════════════════════════════
class _Fab extends StatelessWidget {
  const _Fab();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.96,
      onTap: () => context.push('/products/add'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: c.fg1,
          shape: BoxShape.circle,
          boxShadow: context.shadows.shadowFab,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add_rounded, color: c.surface0, size: 26),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Tap feedback (TODO(extract): duplicate of home/orders/picker)
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


// TODO(chunk 10+): extract shared with `_ActiveBadge` (settings) and
// `_StatusBadge` (home/orders) into
// `lib/shared/widgets/inline_status_badge.dart`. Same surface1/coral
// chip pattern with `radiusChip` + `tabPill` typography.
class _InlineStockBadge extends StatelessWidget {
  const _InlineStockBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
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
