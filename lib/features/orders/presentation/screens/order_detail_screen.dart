import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/order_provider.dart';
import '../../domain/order_models.dart';

final _orderDetailProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, id) async {
  return ref.read(orderRepositoryProvider).getOrder(id);
});

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: context.appBackground,
      body: orderAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.refresh(_orderDetailProvider(orderId)),
        ),
        data: (order) => _OrderDetailContent(
          order: order,
          onStatusChanged: () =>
              ref.refresh(_orderDetailProvider(orderId)),
        ),
      ),
    );
  }
}

class _OrderDetailContent extends ConsumerWidget {
  const _OrderDetailContent({
    required this.order,
    required this.onStatusChanged,
  });

  final Order order;
  final VoidCallback onStatusChanged;

  List<String> _nextStatuses(String current) => switch (current) {
        'PENDING' => ['CONFIRMED', 'CANCELLED'],
        'CONFIRMED' => ['SHIPPED', 'CANCELLED'],
        'SHIPPED' => ['DELIVERED', 'CANCELLED'],
        _ => [],
      };

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref.read(orderRepositoryProvider).updateStatus(order.id, newStatus);
      ref.read(orderListProvider.notifier).refresh();
      onStatusChanged();
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text('Delete Order', style: AppTypography.h4),
        content: Text(
          'Are you sure? This cannot be undone.',
          style: AppTypography.body
              .copyWith(color: context.appTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTypography.body
                    .copyWith(color: context.appTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: AppTypography.body.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ref.read(orderRepositoryProvider).deleteOrder(order.id);
        ref.read(orderListProvider.notifier).removeOrder(order.id);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextStatuses = _nextStatuses(order.status);
    final isProfit = order.orderProfit > 0;
    final isLoss = order.orderProfit < 0;

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              MediaQuery.of(context).padding.top + AppSpacing.md,
              AppSpacing.screenHorizontal,
              AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.appSurfaceL2,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      order.orderNumber,
                      style: AppTypography.h4.copyWith(
                        color: context.appTextPrimary,
                      ),
                    ),
                    Text(
                      DateFormatter.short(order.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(context, ref),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Status Timeline ───────────────────
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline steps
                    _OrderTimeline(currentStatus: order.status),

                    // Status update buttons
                    if (nextStatuses.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Divider(color: context.appBorder, height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Update status:',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.appTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: nextStatuses.map((status) {
                          final isCancel = status == 'CANCELLED';
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: GestureDetector(
                              onTap: () => _updateStatus(context, ref, status),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isCancel
                                      ? AppColors.errorBg
                                      : context.appBrand,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: Text(
                                  status,
                                  style: AppTypography.label.copyWith(
                                    color: isCancel
                                        ? AppColors.error
                                        : AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Customer ──────────────────────────
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
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.appBrandLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Center(
                        child: Text(
                          order.customer.name[0].toUpperCase(),
                          style: AppTypography.h4.copyWith(
                            color: context.appBrand,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customer.name,
                            style: AppTypography.body.copyWith(
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            order.customer.phone,
                            style: AppTypography.bodySmall.copyWith(
                              color: context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: order.customer.phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Phone number copied')),
                        );
                      },
                      child: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: context.appTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Items ─────────────────────────────
              Text(
                'Items',
                style: AppTypography.h4.copyWith(
                  color: context.appTextPrimary,
                ),
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
                  children: order.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final isLast = i == order.items.length - 1;
                    final itemProfit =
                        (item.unitPrice - item.unitCost) * item.quantity;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              // Product image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: item.primaryImageUrl != null
                                      ? Image.network(
                                          item.primaryImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: context.appSurfaceL2,
                                            child: Icon(
                                              Icons.inventory_2_outlined,
                                              color: context.appTextTertiary,
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: context.appSurfaceL2,
                                          child: Icon(
                                            Icons.inventory_2_outlined,
                                            color: context.appTextTertiary,
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: AppTypography.body.copyWith(
                                        color: context.appTextPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (item.attributeLabel.isNotEmpty)
                                      Text(
                                        item.attributeLabel,
                                        style:
                                            AppTypography.caption.copyWith(
                                          color: context.appTextTertiary,
                                        ),
                                      ),
                                    Text(
                                      '${MillimesFormatter.format(item.unitPrice)} × ${item.quantity}',
                                      style:
                                          AppTypography.caption.copyWith(
                                        color: context.appTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    MillimesFormatter.format(item.subtotal),
                                    style: AppTypography.body.copyWith(
                                      color: context.appTextPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.full),
                                    ),
                                    child: Text(
                                      '+${MillimesFormatter.format(itemProfit)}',
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
                        if (!isLast)
                          Divider(height: 1, color: context.appBorder),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Financial Summary ──────────────────
              Text(
                'Summary',
                style: AppTypography.h4.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
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
                    _SummaryRow(
                      label: 'Gross Revenue',
                      value: MillimesFormatter.format(order.grossRevenue),
                      context: context,
                    ),
                    if (order.discountAmount > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _SummaryRow(
                        label: 'Discount',
                        value:
                            '- ${MillimesFormatter.format(order.discountAmount)}',
                        valueColor: AppColors.error,
                        context: context,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    _SummaryRow(
                      label: 'Net Revenue',
                      value: MillimesFormatter.format(order.netRevenue),
                      context: context,
                    ),
                    Divider(
                        height: AppSpacing.lg * 2,
                        color: context.appBorder),
                    _SummaryRow(
                      label: 'Product Cost',
                      value:
                          '- ${MillimesFormatter.format(order.totalCost)}',
                      valueColor: context.appTextSecondary,
                      context: context,
                    ),
                    if (order.shippingCost > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _SummaryRow(
                        label: 'Shipping',
                        value:
                            '- ${MillimesFormatter.format(order.shippingCost)}',
                        valueColor: context.appTextSecondary,
                        context: context,
                      ),
                    ],
                    Divider(
                        height: AppSpacing.lg * 2,
                        color: context.appBorder),
                    _SummaryRow(
                      label: 'Real Profit',
                      value: MillimesFormatter.format(order.orderProfit),
                      valueColor: isProfit
                          ? AppColors.success
                          : isLoss
                              ? AppColors.error
                              : context.appTextSecondary,
                      isBold: true,
                      context: context,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.context,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final BuildContext context;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext _) {
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
            color: valueColor ?? context.appTextPrimary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: context.appSurfaceL2,
              borderRadius: BorderRadius.circular(AppRadius.md),
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
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: context.appSurfaceL2,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: context.appSurfaceL2,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
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
          Text('Could not load order',
              style:
                  AppTypography.h4.copyWith(color: context.appTextPrimary)),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.appBrand,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text('Try Again',
                  style: AppTypography.body.copyWith(
                      color: AppColors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.currentStatus});
  final String currentStatus;

  static const _steps = [
    ('PENDING', 'Pending', Icons.hourglass_empty_rounded),
    ('CONFIRMED', 'Confirmed', Icons.check_circle_outline_rounded),
    ('SHIPPED', 'Shipped', Icons.local_shipping_rounded),
    ('DELIVERED', 'Delivered', Icons.home_rounded),
  ];

  int get _currentIndex {
    if (currentStatus == 'CANCELLED') return -1;
    return _steps.indexWhere((s) => s.$1 == currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _currentIndex;
    final isCancelled = currentStatus == 'CANCELLED';

    if (isCancelled) {
      return Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Icon(Icons.cancel_outlined,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancelled',
                style: AppTypography.body.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'This order was cancelled',
                style: AppTypography.caption.copyWith(
                  color: context.appTextTertiary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        // Connector line
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isCompleted = stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? context.appBrand
                  : context.appBorder,
            ),
          );
        }

        // Step circle
        final stepIdx = i ~/ 2;
        final step = _steps[stepIdx];
        final isCompleted = stepIdx <= currentIdx;
        final isCurrent = stepIdx == currentIdx;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? context.appBrand
                    : context.appSurfaceL2,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: isCurrent
                    ? Border.all(
                        color: context.appBrand,
                        width: 2,
                      )
                    : null,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color:
                              context.appBrand.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                step.$3,
                size: 18,
                color: isCompleted
                    ? AppColors.white
                    : context.appTextTertiary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.$2,
              style: AppTypography.caption.copyWith(
                color: isCompleted
                    ? context.appBrand
                    : context.appTextTertiary,
                fontWeight: isCurrent
                    ? FontWeight.w700
                    : FontWeight.w400,
                fontSize: 9,
              ),
            ),
          ],
        );
      }),
    );
  }
}