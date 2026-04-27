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
import '../../../../core/utils/date_formatter.dart';
import '../providers/order_provider.dart';
import '../../domain/order_models.dart';

final _orderScreenUserProvider =
    FutureProvider.autoDispose<String>((ref) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return await storage.read(key: 'user_full_name') ?? '';
});

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String _searchQuery = '';
  String _dateFilter = 'today';

  bool get _hasActiveFilter =>
      _selectedStatus != null || _dateFilter != 'today';

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
      ref.read(orderListProvider.notifier).loadMore();
    }
  }

  bool _matchesDateFilter(OrderLean order) {
    final now = DateTime.now();
    final date = order.createdAt;
    return switch (_dateFilter) {
      'today' => date.year == now.year &&
          date.month == now.month &&
          date.day == now.day,
      '3days' => date.isAfter(now.subtract(const Duration(days: 3))),
      'week' => date.isAfter(now.subtract(const Duration(days: 7))),
      'month' => date.year == now.year && date.month == now.month,
      _ => true,
    };
  }

  String _greeting() {
    final hour = DateTime.now().toUtc().add(const Duration(hours: 1)).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrderFilterSheet(
        initialDate: _dateFilter,
        initialStatus: _selectedStatus,
        onApply: (date, status) {
          setState(() {
            _dateFilter = date;
            _selectedStatus = status;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderListProvider);
    final userAsync = ref.watch(_orderScreenUserProvider);
    final firstName = userAsync.maybeWhen(
      data: (name) => name.split(' ').first,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xl,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        'Orders',
                        style: AppTypography.h1.copyWith(
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/orders/add'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.appBrand,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: AppColors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
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
                              color:
                                  context.appBrand.withValues(alpha: 0.2),
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

            // ── Search + Filter ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.appTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search orders...',
                          hintStyle: AppTypography.bodySmall.copyWith(
                            color: context.appTextTertiary,
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: context.appTextTertiary, size: 18),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (value) => setState(
                            () => _searchQuery = value.toLowerCase()),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Filter button
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _hasActiveFilter
                            ? context.appBrand
                            : context.appSurface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: _hasActiveFilter
                              ? context.appBrand
                              : context.appBorder,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: _hasActiveFilter
                                ? AppColors.white
                                : context.appTextSecondary,
                          ),
                          if (_hasActiveFilter)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Active filter pills ────────────────
            if (_hasActiveFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded,
                        size: 14, color: context.appTextTertiary),
                    const SizedBox(width: 6),
                    if (_dateFilter != 'today' && _dateFilter != 'all')
                      _ActivePill(
                        label: _dateLabelMap[_dateFilter] ?? _dateFilter,
                        onRemove: () =>
                            setState(() => _dateFilter = 'today'),
                      ),
                    if (_selectedStatus != null) ...[
                      const SizedBox(width: 6),
                      _ActivePill(
                        label: _selectedStatus!,
                        onRemove: () =>
                            setState(() => _selectedStatus = null),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _dateFilter = 'today';
                        _selectedStatus = null;
                      }),
                      child: Text(
                        'Clear all',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Content ────────────────────────────
            Expanded(
              child: ordersAsync.when(
                loading: () => const _OrderListSkeleton(),
                error: (e, _) => _ErrorState(
                  onRetry: () =>
                      ref.read(orderListProvider.notifier).refresh(),
                ),
                data: (orders) {
                  final filtered = orders.where((o) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        o.customerName
                            .toLowerCase()
                            .contains(_searchQuery);
                    final matchesDate = _matchesDateFilter(o);
                    final matchesStatus = _selectedStatus == null ||
                        o.status == _selectedStatus;
                    return matchesSearch && matchesDate && matchesStatus;
                  }).toList();

                  if (orders.isEmpty) return const _EmptyState();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48,
                              color: context.appTextTertiary),
                          const SizedBox(height: AppSpacing.md),
                          Text('No orders found',
                              style: AppTypography.h4.copyWith(
                                  color: context.appTextPrimary)),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () => setState(() {
                              _dateFilter = 'today';
                              _selectedStatus = null;
                            }),
                            child: Text(
                              'Clear filters',
                              style: AppTypography.body.copyWith(
                                color: context.appBrand,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final totalRevenue = filtered.fold<int>(
                      0, (sum, o) => sum + o.netRevenue);
                  final totalProfit = filtered.fold<int>(
                      0, (sum, o) => sum + o.orderProfit);

                  return Column(
                    children: [
                      // Summary bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.appSurface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border:
                                Border.all(color: context.appBorder),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filtered.length} order${filtered.length == 1 ? '' : 's'}',
                                style: AppTypography.label.copyWith(
                                  color: context.appTextSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    MillimesFormatter.format(totalRevenue),
                                    style: AppTypography.label.copyWith(
                                      color: context.appTextPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(' · ',
                                      style: AppTypography.label.copyWith(
                                          color:
                                              context.appTextTertiary)),
                                  Text(
                                    '+${MillimesFormatter.format(totalProfit)}',
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Expanded(
                        child: RefreshIndicator(
                          color: context.appBrand,
                          onRefresh: () => ref
                              .read(orderListProvider.notifier)
                              .refresh(),
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenHorizontal,
                              0,
                              AppSpacing.screenHorizontal,
                              100,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xs),
                            itemBuilder: (context, index) => _OrderCard(
                              order: filtered[index],
                              onStatusChanged: () => ref
                                  .read(orderListProvider.notifier)
                                  .refresh(),
                            ),
                          ),
                        ),
                      ),
                    ],
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

const _dateLabelMap = {
  'today': 'Today',
  '3days': 'Last 3 days',
  'week': 'Last week',
  'month': 'This month',
  'all': 'All time',
};

// ── Filter Sheet ───────────────────────────────────────────
class _OrderFilterSheet extends StatefulWidget {
  const _OrderFilterSheet({
    required this.initialDate,
    required this.initialStatus,
    required this.onApply,
  });

  final String initialDate;
  final String? initialStatus;
  final Function(String date, String? status) onApply;

  @override
  State<_OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<_OrderFilterSheet> {
  late String _date;
  late String? _status;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _status = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date section
              Text('Date Range',
                  style: AppTypography.h4
                      .copyWith(color: context.appTextPrimary)),
              const SizedBox(height: AppSpacing.sm),
              ...[
                ('today', 'Today'),
                ('3days', 'Last 3 days'),
                ('week', 'Last week'),
                ('month', 'This month'),
                ('all', 'All time'),
              ].map((entry) => _RadioTile(
                    label: entry.$2,
                    selected: _date == entry.$1,
                    onTap: () => setState(() => _date = entry.$1),
                  )),

              const SizedBox(height: AppSpacing.lg),

              // Status section
              Text('Status',
                  style: AppTypography.h4
                      .copyWith(color: context.appTextPrimary)),
              const SizedBox(height: AppSpacing.sm),
              ...[
                (null, 'All'),
                ('PENDING', 'Pending'),
                ('CONFIRMED', 'Confirmed'),
                ('SHIPPED', 'Shipped'),
                ('DELIVERED', 'Delivered'),
                ('CANCELLED', 'Cancelled'),
              ].map((entry) => _RadioTile(
                    label: entry.$2,
                    selected: _status == entry.$1,
                    onTap: () => setState(() => _status = entry.$1),
                  )),

              const SizedBox(height: AppSpacing.xl),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_date, _status);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appBrand,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    'Apply Filter',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? context.appBrand
                      : context.appBorder,
                  width: selected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: selected
                    ? context.appTextPrimary
                    : context.appTextSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.appBrandLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: context.appBrand,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 12, color: context.appBrand),
          ),
        ],
      ),
    );
  }
}

// ── Order Card ─────────────────────────────────────────────
class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.onStatusChanged});
  final OrderLean order;
  final VoidCallback onStatusChanged;

  Color _statusColor(String status) => switch (status) {
        'PENDING' => AppColors.warning,
        'CONFIRMED' => AppColors.info,
        'SHIPPED' => const Color(0xFF8B5CF6),
        'DELIVERED' => AppColors.success,
        'CANCELLED' => AppColors.error,
        _ => AppColors.textTertiary,
      };

  Color _statusBg(String status) => switch (status) {
        'PENDING' => AppColors.warningBg,
        'CONFIRMED' => AppColors.infoBg,
        'SHIPPED' => const Color(0xFFF3F0FF),
        'DELIVERED' => AppColors.successBg,
        'CANCELLED' => AppColors.errorBg,
        _ => AppColors.surfaceL1,
      };

  String? _nextStatus(String current) => switch (current) {
        'PENDING' => 'CONFIRMED',
        'CONFIRMED' => 'SHIPPED',
        'SHIPPED' => 'DELIVERED',
        _ => null,
      };

  Future<void> _quickUpdateStatus(
      BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateStatus(order.id, newStatus);
      onStatusChanged();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCancelled = order.status == 'CANCELLED';
    final isProfit = order.orderProfit > 0 && !isCancelled;
    final isLoss = order.orderProfit < 0 && !isCancelled;
    final next = _nextStatus(order.status);

    return Dismissible(
      key: Key(order.id),
      direction: next != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        if (next == null) return false;
        await _quickUpdateStatus(context, ref, next);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.appBrand,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.white, size: 24),
            const SizedBox(height: 4),
            Text(next ?? '',
                style: AppTypography.label.copyWith(
                    color: AppColors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => context.push('/orders/${order.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.appBrandLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Center(
                  child: Text(
                    order.customerName[0].toUpperCase(),
                    style: AppTypography.body.copyWith(
                      color: context.appBrand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.customerName,
                            style: AppTypography.body.copyWith(
                              color: context.appTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusBg(order.status),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            order.status,
                            style: AppTypography.caption.copyWith(
                              color: _statusColor(order.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerPhone} · ${order.orderNumber}',
                      style: AppTypography.caption.copyWith(
                        color: context.appTextTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          MillimesFormatter.format(order.netRevenue),
                          style: AppTypography.bodySmall.copyWith(
                            color: context.appTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              MillimesFormatter.format(order.orderProfit),
                              style: AppTypography.bodySmall.copyWith(
                                color: isCancelled
                                    ? context.appTextTertiary
                                    : isProfit
                                        ? AppColors.success
                                        : isLoss
                                            ? AppColors.error
                                            : context.appTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' · ${DateFormatter.relative(order.createdAt)}',
                              style: AppTypography.caption.copyWith(
                                color: context.appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (next != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_left_rounded,
                    size: 16, color: context.appTextTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty / Error / Skeleton ───────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              child: Icon(Icons.receipt_long_outlined,
                  size: 40, color: context.appBrand),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('No orders yet',
                style: AppTypography.h3
                    .copyWith(color: context.appTextPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Log your first sale in seconds',
                style: AppTypography.body
                    .copyWith(color: context.appTextSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => context.push('/orders/add'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appBrand,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text('+ Log Sale',
                    style: AppTypography.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600)),
              ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: context.appTextTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('Could not load orders',
              style: AppTypography.h4
                  .copyWith(color: context.appTextPrimary)),
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
                      color: AppColors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderListSkeleton extends StatelessWidget {
  const _OrderListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, __) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: context.appSurfaceL2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}