import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../providers/product_provider.dart';
import '../../domain/product_models.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      backgroundColor: context.appBackground,
      body: productAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => _DetailError(
          onRetry: () => ref.refresh(productDetailProvider(productId)),
        ),
        data: (product) => _ProductDetailContent(product: product),
      ),
    );
  }
}

// ── Main Content ───────────────────────────────────────────
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text('Delete Product', style: AppTypography.h4),
        content: Text(
          'Are you sure? This cannot be undone.',
          style: AppTypography.body.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTypography.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref
            .read(productRepositoryProvider)
            .deleteProduct(widget.product.id);
        ref.read(productListProvider.notifier).removeProduct(widget.product.id);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images;
    final profitPerUnit = product.baseSellPrice - product.baseCostPrice;
    final profitMarginPct = product.baseCostPrice > 0
        ? (profitPerUnit / product.baseSellPrice * 100).toStringAsFixed(1)
        : '0';

    return CustomScrollView(
      slivers: [
        // ── Hero Image ──────────────────────────────
        SliverToBoxAdapter(
          child: Stack(
            children: [
              // Image
              SizedBox(
                height: 320,
                width: double.infinity,
                child: images.isNotEmpty
                    ? PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) =>
                            setState(() => _currentImageIndex = i),
                        itemBuilder: (_, i) => CachedNetworkImage(
                          imageUrl: images[i].url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: context.appSurfaceL2,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: context.appSurfaceL2,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: context.appTextTertiary,
                              size: 48,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: context.appSurfaceL2,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: context.appTextTertiary,
                          size: 64,
                        ),
                      ),
              ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: AppSpacing.screenHorizontal,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),

              // Edit button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: AppSpacing.screenHorizontal,
                child: GestureDetector(
                  onTap: () => context.push(
                    '/products/${product.id}/edit',
                    extra: product,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

              // Image indicators
              if (images.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentImageIndex == i ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == i
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.5),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Content ─────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Name + status ──────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: AppTypography.h2.copyWith(
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? AppColors.successBg
                          : AppColors.errorBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      product.isActive ? 'Active' : 'Inactive',
                      style: AppTypography.label.copyWith(
                        color: product.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),

              if (product.category != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.appBrandLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      product.category!,
                      style: AppTypography.label.copyWith(
                        color: context.appBrand,
                      ),
                    ),
                  ),
                ),
              ],

              if (product.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  product.description!,
                  style: AppTypography.body.copyWith(
                    color: context.appTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // ── Pricing ────────────────────────────
              _SectionTitle(title: 'Pricing'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: context.isDark
                      ? Border.all(color: context.appBorder)
                      : null,
                  boxShadow: context.appCardShadow,
                ),
                child: Column(
                  children: [
                    _PriceRow(
                      label: 'Cost Price',
                      value: MillimesFormatter.format(product.baseCostPrice),
                      valueColor: context.appTextPrimary,
                    ),
                    Divider(height: AppSpacing.md * 2, color: context.appBorder),
                    _PriceRow(
                      label: 'Sell Price',
                      value: MillimesFormatter.format(product.baseSellPrice),
                      valueColor: context.appTextPrimary,
                    ),
                    Divider(height: AppSpacing.md * 2, color: context.appBorder),
                    _PriceRow(
                      label: 'Profit per Sale',
                      value:
                          '+${MillimesFormatter.format(profitPerUnit)} ($profitMarginPct%)',
                      valueColor: AppColors.success,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Variants / Stock ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionTitle(title: 'Stock'),
                  Text(
                    'Total: ${product.totalStock} units',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: context.isDark
                      ? Border.all(color: context.appBorder)
                      : null,
                  boxShadow: context.appCardShadow,
                ),
                child: Column(
                  children: product.variants
                      .where((v) => v.isActive)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final i = entry.key;
                    final variant = entry.value;
                    final isLast = i ==
                        product.variants
                                .where((v) => v.isActive)
                                .length -
                            1;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      variant.isSimple
                                          ? 'Default'
                                          : variant.attributeLabel,
                                      style: AppTypography.body.copyWith(
                                        color: context.appTextPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      variant.sku,
                                      style: AppTypography.caption.copyWith(
                                        color: context.appTextTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StockChip(stock: variant.stockQuantity),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: context.appBorder,
                            indent: AppSpacing.md,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Action Buttons ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Create Post',
                      color: context.appBrand,
                      onTap: () => context.go('/ai-studio'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: AppColors.error,
                      onTap: () => _confirmDelete(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Reusable components ────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(
        color: context.appTextPrimary,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: context.appTextSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: valueColor,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final isOut = stock == 0;
    final isLow = stock <= 5 && !isOut;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isOut
            ? AppColors.errorBg
            : isLow
                ? AppColors.warningBg
                : AppColors.successBg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        isOut ? 'Out of stock' : '$stock units',
        style: AppTypography.label.copyWith(
          color: isOut
              ? AppColors.error
              : isLow
                  ? AppColors.warning
                  : AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 320,
          color: context.appSurfaceL2,
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 32,
                width: 200,
                decoration: BoxDecoration(
                  color: context.appSurfaceL2,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: context.appSurfaceL2,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: context.appSurfaceL2,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Error ──────────────────────────────────────────────────
class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: context.appTextTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Could not load product',
            style: AppTypography.h4.copyWith(color: context.appTextPrimary),
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