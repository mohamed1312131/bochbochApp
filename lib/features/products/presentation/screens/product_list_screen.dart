import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../providers/product_provider.dart';
import '../../domain/product_models.dart';

// ── User name provider ─────────────────────────────────────
final _productScreenUserProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return {
    'name': await storage.read(key: 'user_full_name') ?? '',
  };
});

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

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

  String _greeting() {
    final hour = DateTime.now().toUtc().add(const Duration(hours: 1)).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, ) {
    final productsAsync = ref.watch(productListProvider);
    final userAsync = ref.watch(_productScreenUserProvider);
    final firstName = userAsync.maybeWhen(
      data: (info) => info['name']?.split(' ').first ?? '',
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xl,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()} 👋',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Products',
                        style: AppTypography.h1.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Add button
                      GestureDetector(
                        onTap: () => context.push('/products/add'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.appBrand,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Profile avatar
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.appBrandLight,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: context.appBrand.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : 'U',
                              style: AppTypography.h4.copyWith(
                                color: context.appBrand,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search Bar ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.appBorder),
                  boxShadow: context.appCardShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.body.copyWith(
                    color: context.appTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: AppTypography.body.copyWith(
                      color: context.appTextTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: context.appTextTertiary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Content ───────────────────────────────────
            Expanded(
              child: productsAsync.when(
                loading: () => const _ProductGridSkeleton(),
                error: (e, _) => _ErrorState(
                  onRetry: () =>
                      ref.read(productListProvider.notifier).refresh(),
                ),
                data: (products) {
                  // Client-side search filter
                  final filtered = _searchQuery.isEmpty
                      ? products
                      : products
                          .where((p) =>
                              p.name
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              (p.category
                                      ?.toLowerCase()
                                      .contains(_searchQuery) ??
                                  false))
                          .toList();

                  if (products.isEmpty) return _EmptyState();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: context.appTextTertiary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No products found',
                            style: AppTypography.h4.copyWith(
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Try a different search term',
                            style: AppTypography.body.copyWith(
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: context.appBrand,
                    onRefresh: () =>
                        ref.read(productListProvider.notifier).refresh(),
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        0,
                        AppSpacing.screenHorizontal,
                        100,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.cardGap,
                        crossAxisSpacing: AppSpacing.cardGap,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _ProductCard(product: filtered[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final ProductLean product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOutOfStock = product.totalStock == 0;
final isLowStock = product.totalStock <= 5 && !isOutOfStock;

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: context.isDark
              ? Border.all(color: context.appBorder)
              : null,
          boxShadow: context.appCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Product image
                    product.primaryImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.primaryImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: context.appSurfaceL2,
                              child: Icon(
                                Icons.image_outlined,
                                color: context.appTextTertiary,
                                size: 32,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: context.appSurfaceL2,
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: context.appTextTertiary,
                                size: 32,
                              ),
                            ),
                          )
                        : Container(
                            color: context.appSurfaceL2,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: context.appTextTertiary,
                              size: 32,
                            ),
                          ),

                    // Gradient overlay at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black38,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Stock badge — top right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _StockBadge(
                        stock: product.totalStock,
                        isLowStock: isLowStock,
                        isOutOfStock: isOutOfStock,
                      ),
                    ),

                    // Variants badge — top left
                    if (product.isMultiVariant)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'Variants',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info ───────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name
                    Text(
                      product.name,
                      style: AppTypography.label.copyWith(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Category pill
                    if (product.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.appBrandLight,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          product.category!,
                          style: AppTypography.caption.copyWith(
                            color: context.appBrand,
                          ),
                        ),
                      ),
                    // Price + profit row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          MillimesFormatter.format(product.baseSellPrice),
                          style: AppTypography.bodySmall.copyWith(
                            color: context.appBrand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '+${MillimesFormatter.format(product.baseSellPrice - product.baseCostPrice)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stock Badge ────────────────────────────────────────────
class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.stock,
    required this.isLowStock,
    required this.isOutOfStock,
  });

  final int stock;
  final bool isLowStock;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;

    if (isOutOfStock) {
      bg = AppColors.error;
      label = 'Out';
    } else if (isLowStock) {
      bg = AppColors.warning;
      label = '$stock left';
    } else {
      bg = AppColors.success;
      label = '$stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.appBrandLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: context.appBrand,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Add your first product',
              style: AppTypography.h3.copyWith(
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your catalog lives here',
              style: AppTypography.body.copyWith(
                color: context.appTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => context.push('/products/add'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: context.appBrand,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  '+ Add Product',
                  style: AppTypography.body.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: context.appTextTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Could not load products',
            style: AppTypography.h4.copyWith(
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check your connection and try again',
            style: AppTypography.body.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: context.appBrand,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'Try Again',
                style: AppTypography.body.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────
class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.cardGap,
        crossAxisSpacing: AppSpacing.cardGap,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: context.appSurfaceL2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}