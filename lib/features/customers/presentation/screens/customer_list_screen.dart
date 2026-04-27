import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../providers/customer_provider.dart';
import '../../domain/customer_models.dart';

enum _SortOption { recentOrder, mostSpent, mostOrders }

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _segmentFilter;
  _SortOption _sort = _SortOption.recentOrder;

  final _segments = [null, 'VIP', 'LOYAL', 'NEW', 'AT_RISK', 'RETURNER'];

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
      ref.read(customerListProvider.notifier).loadMore();
    }
  }

  Color _segmentColor(String? segment) => switch (segment) {
        'VIP' => const Color(0xFFD97706),
        'LOYAL' => AppColors.success,
        'AT_RISK' => AppColors.error,
        'NEW' => AppColors.info,
        'RETURNER' => const Color(0xFF8B5CF6),
        _ => AppColors.textTertiary,
      };

  Color _segmentBg(String? segment) => switch (segment) {
        'VIP' => const Color(0xFFFEF3C7),
        'LOYAL' => AppColors.successBg,
        'AT_RISK' => AppColors.errorBg,
        'NEW' => AppColors.infoBg,
        'RETURNER' => const Color(0xFFF3F0FF),
        _ => AppColors.surfaceL1,
      };

  List<CustomerLean> _applyFiltersAndSort(List<CustomerLean> customers) {
    var result = customers.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery) ||
          c.phone.contains(_searchQuery);
      final matchesSegment =
          _segmentFilter == null || c.segment == _segmentFilter;
      return matchesSearch && matchesSegment;
    }).toList();

    result.sort((a, b) => switch (_sort) {
          _SortOption.recentOrder => (b.lastOrderDate ?? DateTime(0))
              .compareTo(a.lastOrderDate ?? DateTime(0)),
          _SortOption.mostSpent => b.totalSpent.compareTo(a.totalSpent),
          _SortOption.mostOrders =>
            b.totalOrders.compareTo(a.totalOrders),
        });

    return result;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text('Sort by',
                  style: AppTypography.h4
                      .copyWith(color: context.appTextPrimary)),
              const SizedBox(height: AppSpacing.sm),
              _SortTile(
                label: 'Most Recent Order',
                icon: Icons.access_time_rounded,
                selected: _sort == _SortOption.recentOrder,
                onTap: () {
                  setState(() => _sort = _SortOption.recentOrder);
                  Navigator.pop(ctx);
                },
              ),
              _SortTile(
                label: 'Most Spent',
                icon: Icons.monetization_on_outlined,
                selected: _sort == _SortOption.mostSpent,
                onTap: () {
                  setState(() => _sort = _SortOption.mostSpent);
                  Navigator.pop(ctx);
                },
              ),
              _SortTile(
                label: 'Most Orders',
                icon: Icons.receipt_long_outlined,
                selected: _sort == _SortOption.mostOrders,
                onTap: () {
                  setState(() => _sort = _SortOption.mostOrders);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

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
                  Text(
                    'Clients',
                    style: AppTypography.h1.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      // Sort button
                      GestureDetector(
                        onTap: _showSortSheet,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.appSurface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: Icon(
                            Icons.sort_rounded,
                            size: 18,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Total badge
                      customersAsync.maybeWhen(
                        data: (customers) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.appBrandLight,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '${customers.length}',
                            style: AppTypography.label.copyWith(
                              color: context.appBrand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.appBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.bodySmall
                      .copyWith(color: context.appTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    hintStyle: AppTypography.bodySmall
                        .copyWith(color: context.appTextTertiary),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: context.appTextTertiary, size: 18),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Segment filter (only if segments exist) ────
            customersAsync.maybeWhen(
              data: (customers) {
                final hasSegments = customers.any((c) => c.segment != null);
                if (!hasSegments) return const SizedBox.shrink();
                return Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenHorizontal),
                        child: Row(
                          children: _segments.map((segment) {
                            final isSelected = _segmentFilter == segment;
                            final label = segment ?? 'All';
                            final color = segment != null
                                ? _segmentColor(segment)
                                : context.appBrand;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _segmentFilter = segment),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : context.appSurface,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full),
                                    border: Border.all(
                                      color:
                                          isSelected ? color : context.appBorder,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: AppTypography.label.copyWith(
                                      fontSize: 11,
                                      color: isSelected
                                          ? AppColors.white
                                          : context.appTextSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // ── List ───────────────────────────────
            Expanded(
              child: customersAsync.when(
                loading: () => const _CustomerListSkeleton(),
                error: (e, _) => _ErrorState(
                  onRetry: () =>
                      ref.read(customerListProvider.notifier).refresh(),
                ),
                data: (customers) {
                  final filtered = _applyFiltersAndSort(customers);

                  if (customers.isEmpty) return const _EmptyState();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: context.appTextTertiary),
                          const SizedBox(height: AppSpacing.md),
                          Text('No clients found',
                              style: AppTypography.h4.copyWith(
                                  color: context.appTextPrimary)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: context.appBrand,
                    onRefresh: () =>
                        ref.read(customerListProvider.notifier).refresh(),
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
                      itemBuilder: (context, index) => _CustomerCard(
                        customer: filtered[index],
                        segmentColor: _segmentColor(filtered[index].segment),
                        segmentBg: _segmentBg(filtered[index].segment),
                      ),
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

// ── Customer Card — minimal, clean ─────────────────────────
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.segmentColor,
    required this.segmentBg,
  });

  final CustomerLean customer;
  final Color segmentColor;
  final Color segmentBg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/customers/${customer.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
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
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.appBrandLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Center(
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: AppTypography.h4.copyWith(
                    color: context.appBrand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: AppTypography.body.copyWith(
                      color: context.appTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.phone,
                    style: AppTypography.caption.copyWith(
                      color: context.appTextTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Right: spent + segment
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MillimesFormatter.format(customer.totalSpent),
                  style: AppTypography.body.copyWith(
                    color: context.appBrand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (customer.segment != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: segmentBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      customer.segment!,
                      style: AppTypography.caption.copyWith(
                        color: segmentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  )
                else
                  Text(
                    '${customer.totalOrders} order${customer.totalOrders == 1 ? '' : 's'}',
                    style: AppTypography.caption.copyWith(
                      color: context.appTextTertiary,
                    ),
                  ),
              ],
            ),

            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: context.appTextTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Sort tile ──────────────────────────────────────────────
class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? context.appBrand : context.appTextTertiary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: selected
                      ? context.appBrand
                      : context.appTextPrimary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded,
                  size: 18, color: context.appBrand),
          ],
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
              child: Icon(Icons.people_outline_rounded,
                  size: 40, color: context.appBrand),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('No clients yet',
                style: AppTypography.h3
                    .copyWith(color: context.appTextPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Clients are added automatically\nwhen you log orders',
              style: AppTypography.body
                  .copyWith(color: context.appTextSecondary),
              textAlign: TextAlign.center,
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
          Text('Could not load clients',
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

class _CustomerListSkeleton extends StatelessWidget {
  const _CustomerListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, __) => Container(
        height: 68,
        decoration: BoxDecoration(
          color: context.appSurfaceL2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}