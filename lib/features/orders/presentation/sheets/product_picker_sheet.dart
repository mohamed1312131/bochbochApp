import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_product_image.dart';
import '../../../products/domain/product_models.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../stock/domain/stock_models.dart';
import '../../../stock/presentation/providers/stock_provider.dart';

/// Shared logic between `_VariantRow` (multi-variant pick) and
/// `_onProductTap` (single-variant short-circuit). Treats the
/// `StockState` as carrying real signal only when *any* of its
/// quantities is non-zero — chunks 1-7 mock state for unknown
/// variantIds returns all zeros, which we treat as "no live data,
/// fall back to legacy `variant.stockQuantity`".
bool _hasRealStockData(StockState state) =>
    state.onHand > 0 ||
    state.committedOrders.isNotEmpty ||
    state.backordered > 0;

bool _decideIsBackorder(StockState? state, ProductVariant variant) {
  if (state != null && _hasRealStockData(state)) {
    return state.available <= 0 && (variant.backorderEnabled ?? false);
  }
  return variant.stockQuantity <= 0 && (variant.backorderEnabled ?? false);
}

/// Authoritative "selection blocked" check — must match the
/// rendering logic that disables Case 4 rows during build.
bool _isHardBlocked(StockState? state, ProductVariant variant) {
  final backorderEnabled = variant.backorderEnabled ?? false;
  if (backorderEnabled) return false;
  if (state != null && _hasRealStockData(state)) {
    return state.available <= 0;
  }
  return variant.stockQuantity <= 0;
}

/// The shape returned to the caller when the user picks a product+variant.
/// Public so the order screen can keep it as a list field type.
class OrderItemDraft {
  const OrderItemDraft({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.unitPrice,
    required this.unitCost,
    this.quantity = 1,
    this.isBackorder = false,
  });

  final String productId;
  final String variantId;
  final String productName;
  final int unitPrice;
  final int unitCost;
  final int quantity;
  final bool isBackorder;

  OrderItemDraft copyWith({int? quantity, bool? isBackorder}) => OrderItemDraft(
    productId: productId,
    variantId: variantId,
    productName: productName,
    unitPrice: unitPrice,
    unitCost: unitCost,
    quantity: quantity ?? this.quantity,
    isBackorder: isBackorder ?? this.isBackorder,
  );
}

/// Opens the product picker. Returns the chosen draft, or null if dismissed.
Future<OrderItemDraft?> showProductPickerSheet(BuildContext context) {
  return showModalBottomSheet<OrderItemDraft>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ProductPickerSheet(),
  );
}

// ════════════════════════════════════════════════════════════
// Sheet root
// ════════════════════════════════════════════════════════════
class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _query = '';
  ProductLean? _selectedProduct;

  Future<List<ProductLean>> _loadProducts() async {
    final result = await ref
        .read(productRepositoryProvider)
        .getProducts(limit: 50);
    return result.data;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.surface0,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.radius.radiusSheet),
            ),
          ),
          child: Column(
            children: [
              const _DragHandle(),
              if (_selectedProduct == null)
                Expanded(
                  child: _ProductsView(
                    scrollController: scrollController,
                    query: _query,
                    onQueryChanged: (q) => setState(() => _query = q),
                    onProductTap: _onProductTap,
                    loader: _loadProducts,
                  ),
                )
              else
                Expanded(
                  child: _VariantView(
                    scrollController: scrollController,
                    product: _selectedProduct!,
                    onBack: () => setState(() => _selectedProduct = null),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onProductTap(ProductLean product) async {
    if (product.isMultiVariant) {
      setState(() => _selectedProduct = product);
      return;
    }
    // Single-variant: fetch full product to read the variant id+price+cost.
    try {
      final full = await ref
          .read(productRepositoryProvider)
          .getProduct(product.id);
      if (!mounted || full.variants.isEmpty) return;
      final v = full.variants.first;

      // Stock-aware short-circuit (chunk 8b-2 task 4). Wait for the
      // first stock-state read so Case 4 (out-of-stock without
      // backorder) blocks the pop with a SnackBar rather than
      // silently adding an unsellable item.
      final state = await ref.read(stockStateProvider(v.id).future);
      if (!mounted) return;

      if (_isHardBlocked(state, v)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Stock épuisé. Active backorders dans le produit ou '
              'réduis la quantité.',
            ),
          ),
        );
        return;
      }

      Navigator.pop(
        context,
        OrderItemDraft(
          productId: product.id,
          variantId: v.id,
          productName: product.name,
          unitPrice: v.effectiveSellPrice,
          unitCost: v.effectiveCostPrice,
          isBackorder: _decideIsBackorder(state, v),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de charger le produit'),
          backgroundColor: context.colors.red,
        ),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════
// Drag handle
// ════════════════════════════════════════════════════════════
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.space2),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.border2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Products view (search + list)
// ════════════════════════════════════════════════════════════
class _ProductsView extends StatefulWidget {
  const _ProductsView({
    required this.scrollController,
    required this.query,
    required this.onQueryChanged,
    required this.onProductTap,
    required this.loader,
  });

  final ScrollController scrollController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<ProductLean> onProductTap;
  final Future<List<ProductLean>> Function() loader;

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  late Future<List<ProductLean>> _future = widget.loader();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        // Title row
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space4,
            vertical: context.spacing.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Choisir un produit',
                  style: context.typography.h3.copyWith(color: c.fg1),
                ),
              ),
              _CloseButton(onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
        // Search
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            0,
            context.spacing.space4,
            context.spacing.space3,
          ),
          child: _SearchInput(
            controller: _searchController,
            hint: 'Chercher un produit…',
            onChanged: widget.onQueryChanged,
          ),
        ),
        Container(height: 1, color: c.border1),
        Expanded(
          child: FutureBuilder<List<ProductLean>>(
            future: _future,
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return _ProductsSkeleton(
                  scrollController: widget.scrollController,
                );
              }
              if (snap.hasError) {
                return _ErrorView(
                  message: 'Impossible de charger les produits',
                  onRetry: () => setState(() => _future = widget.loader()),
                );
              }
              final products = snap.data ?? const <ProductLean>[];
              if (products.isEmpty) {
                return const _NoProductsState();
              }
              final q = widget.query.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? products
                  : products
                        .where((p) => p.name.toLowerCase().contains(q))
                        .toList();
              if (filtered.isEmpty) {
                return _NoSearchResultsState(query: widget.query);
              }
              return ListView.separated(
                controller: widget.scrollController,
                padding: EdgeInsets.all(context.spacing.space4),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: context.spacing.space2),
                itemBuilder: (_, i) => _ProductRow(
                  product: filtered[i],
                  onTap: () => widget.onProductTap(filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});
  final ProductLean product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.spacing.space3),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(context.radius.radiusInput),
              child: SizedBox(
                width: 48,
                height: 48,
                child: product.primaryImageUrl != null
                    ? DidoProductImage(
                        imageUrl: product.primaryImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_) => _ImageFallback(),
                      )
                    : _ImageFallback(),
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  SizedBox(height: context.spacing.space1),
                  Text(
                    MillimesFormatter.format(product.baseSellPrice),
                    style: context.typography.bodyMd.copyWith(
                      color: c.fg1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (product.isMultiVariant)
              Icon(Icons.chevron_right_rounded, size: 20, color: c.fg3),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      color: c.surface2,
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, size: 24, color: c.fg3),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Variant view
// ════════════════════════════════════════════════════════════
class _VariantView extends ConsumerWidget {
  const _VariantView({
    required this.scrollController,
    required this.product,
    required this.onBack,
  });

  final ScrollController scrollController;
  final ProductLean product;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final productAsync = ref.watch(productDetailProvider(product.id));

    return Column(
      children: [
        // Title row
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space4,
            vertical: context.spacing.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Choisir une variante',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.h3.copyWith(color: c.fg1),
                ),
              ),
              _CloseButton(onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
        // Back link
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            0,
            context.spacing.space4,
            context.spacing.space3,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _ScaleTap(
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: c.fg1,
                    ),
                    SizedBox(width: context.spacing.space1),
                    Text(
                      'Retour aux produits',
                      style: context.typography.button.copyWith(color: c.fg1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(height: 1, color: c.border1),
        Expanded(
          child: productAsync.when(
            loading: () =>
                _ProductsSkeleton(scrollController: scrollController),
            error: (_, __) => _ErrorView(
              message: 'Impossible de charger les variantes',
              onRetry: () => ref.invalidate(productDetailProvider(product.id)),
            ),
            data: (full) {
              final variants = full.variants.where((v) => v.isActive).toList();
              if (variants.isEmpty) {
                return const _NoVariantsState();
              }
              return ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.all(context.spacing.space4),
                itemCount: variants.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: context.spacing.space2),
                itemBuilder: (_, i) => _VariantRow(
                  variant: variants[i],
                  onPick: ({required bool isBackorder}) {
                    Navigator.pop(
                      context,
                      OrderItemDraft(
                        productId: full.id,
                        variantId: variants[i].id,
                        productName: full.name,
                        unitPrice: variants[i].effectiveSellPrice,
                        unitCost: variants[i].effectiveCostPrice,
                        isBackorder: isBackorder,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Stock-aware variant row — chunk 8b-1.
///
/// Watches `stockStateProvider(variant.id)` and renders one of four
/// states:
///  1. In stock (available > 0, no committed) — fully interactive,
///     no helper line.
///  2. In stock with reservations (available > 0, committed > 0) —
///     coral helper "X dispo · Y réservé".
///  3. Out of stock + backorder enabled — coral helper "Pas en stock
///     — sera commandé en backorder", interactive, picks with
///     `isBackorder: true`.
///  4. Out of stock without backorder — disabled (opacity 0.4 +
///     AbsorbPointer), red helper "Stock épuisé".
///
/// When the live stock state has no signal (all zeros + no committed
/// orders + no backordered), falls back to `variant.stockQuantity`
/// (legacy field) for the displayed count — preserves UI for real
/// backend data not yet covered by the mock state map.
class _VariantRow extends ConsumerWidget {
  const _VariantRow({required this.variant, required this.onPick});

  final ProductVariant variant;
  final void Function({required bool isBackorder}) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final stateAsync = ref.watch(stockStateProvider(variant.id));
    final state = stateAsync.valueOrNull;

    final hasLiveData =
        state != null &&
        (state.onHand > 0 ||
            state.committedOrders.isNotEmpty ||
            state.backordered > 0);

    final available = hasLiveData
        ? state.available
        : (stateAsync.isLoading ? null : variant.stockQuantity);
    final committed = hasLiveData ? state.committed : 0;
    final backorderEnabled = variant.backorderEnabled ?? false;

    // Resolve case
    final isOut = available != null && available <= 0;
    final isOutWithBackorder = isOut && backorderEnabled;
    final isOutHard = isOut && !backorderEnabled;
    final hasReservations = !isOut && (committed > 0);

    // Sync re-check at tap time. The build-time check above may have
    // used stale or null state if the user tapped while loading;
    // re-reading the provider here picks up the freshest snapshot.
    void handlePick() {
      final fresh = ref.read(stockStateProvider(variant.id)).valueOrNull;
      if (_isHardBlocked(fresh, variant)) {
        // Race fallback: row was tappable at build, but state moved
        // to Case 4 between build and tap. Fire a selection haptic
        // so the seller's tap feels acknowledged even though no pop
        // follows — alternative to a disruptive toast.
        HapticFeedback.selectionClick();
        return;
      }
      onPick(isBackorder: _decideIsBackorder(fresh, variant));
    }

    final tapHandler = isOutHard ? null : handlePick;

    final body = Container(
      padding: EdgeInsets.all(context.spacing.space3),
      decoration: BoxDecoration(
        color: isOutHard ? c.surface2 : c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      style: context.typography.bodySmall.copyWith(
                        color: c.fg3,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MillimesFormatter.format(variant.effectiveSellPrice),
                    style: context.typography.bodyMd.copyWith(
                      color: c.fg1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: context.spacing.space1),
                  // Pill shows AVAILABLE (sellable now), not onHand
                  // (physical). The "X dispo · Y réservé" helper line
                  // below carries the reservation detail when it
                  // matters. Keeping pill content single-number avoids
                  // visual noise at the row's tight right column.
                  _StockPill(
                    quantity: available,
                    backorderable: isOutWithBackorder,
                    isLoading: stateAsync.isLoading,
                  ),
                ],
              ),
            ],
          ),
          if (hasReservations) ...[
            SizedBox(height: context.spacing.space1),
            Text(
              '$available dispo · $committed réservé',
              style: context.typography.caption.copyWith(color: c.coralFg),
            ),
          ] else if (isOutWithBackorder) ...[
            SizedBox(height: context.spacing.space1),
            Text(
              'Pas en stock — sera commandé en backorder',
              style: context.typography.caption.copyWith(color: c.coralFg),
            ),
          ] else if (isOutHard) ...[
            SizedBox(height: context.spacing.space1),
            Text(
              'Stock épuisé',
              style: context.typography.caption.copyWith(color: c.redFg),
            ),
          ],
        ],
      ),
    );

    return _ScaleTap(
      onTap: tapHandler,
      child: Opacity(
        opacity: isOutHard ? 0.4 : 1.0,
        child: AbsorbPointer(absorbing: isOutHard, child: body),
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({
    required this.quantity,
    this.backorderable = false,
    this.isLoading = false,
  });

  /// `null` means "no data yet" (loading) — render a neutral placeholder.
  final int? quantity;
  final bool backorderable;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color bg;
    final Color fg;
    final String label;

    if (isLoading || quantity == null) {
      bg = c.surface2;
      fg = c.fg3;
      label = '…';
    } else if (quantity! <= 0 && backorderable) {
      bg = c.coralTint12;
      fg = c.coralFg;
      label = 'Backorder';
    } else if (quantity! <= 0) {
      bg = c.coralTint12;
      fg = c.coralFg;
      label = 'Rupture';
    } else if (quantity! <= 5) {
      bg = c.coralTint12;
      fg = c.coralFg;
      label = '$quantity en stock';
    } else {
      bg = c.greenTint12;
      fg = c.greenFg;
      label = '$quantity en stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.radius.radiusChip),
      ),
      child: Text(label, style: context.typography.tabPill.copyWith(color: fg)),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Empty / error / skeleton states
// ════════════════════════════════════════════════════════════
class _NoProductsState extends StatelessWidget {
  const _NoProductsState();

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
              "Ajoute d'abord des produits.",
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
            SizedBox(height: context.spacing.space4),
            _PickerCta(
              label: 'Ajouter un produit',
              onTap: () {
                Navigator.pop(context);
                context.push('/products/add');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsState extends StatelessWidget {
  const _NoSearchResultsState({required this.query});
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
            SizedBox(height: context.spacing.space3),
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

class _NoVariantsState extends StatelessWidget {
  const _NoVariantsState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 48, color: c.fg3),
            SizedBox(height: context.spacing.space3),
            Text(
              'Aucune variante active',
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
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
              message,
              textAlign: TextAlign.center,
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space4),
            _PickerCta(label: 'Réessayer', onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton({required this.scrollController});
  final ScrollController scrollController;

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
          )
          .animate(onPlay: (ctrl) => ctrl.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 1500),
            color: c.surface3,
          );
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.all(context.spacing.space4),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: context.spacing.space2),
      itemBuilder: (_, __) => Container(
        padding: EdgeInsets.all(context.spacing.space3),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          children: [
            Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(
                      context.radius.radiusInput,
                    ),
                  ),
                )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .shimmer(
                  duration: const Duration(milliseconds: 1500),
                  color: c.surface3,
                ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(w: 160, h: 16),
                  SizedBox(height: context.spacing.space1),
                  bar(w: 80, h: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Reusable bits
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

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.92,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.close_rounded, size: 18, color: c.fg1),
      ),
    );
  }
}

class _PickerCta extends StatelessWidget {
  const _PickerCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: c.fg1,
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        child: Text(
          label,
          style: context.typography.button.copyWith(color: c.surface0),
        ),
      ),
    );
  }
}

// TODO(extract): duplicates _ScaleTap in home + orders list — promote to
// lib/shared/widgets/scale_tap.dart in a follow-up prompt.
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
