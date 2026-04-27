import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/customer_provider.dart';
import '../../domain/customer_models.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      backgroundColor: context.appBackground,
      body: customerAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.refresh(customerDetailProvider(customerId)),
        ),
        data: (customer) => _CustomerDetailContent(customer: customer),
      ),
    );
  }
}

class _CustomerDetailContent extends StatelessWidget {
  const _CustomerDetailContent({required this.customer});
  final CustomerDetail customer;

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerEditSheet(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = customer.stats;

    return CustomScrollView(
      slivers: [
        // ── Hero Header ──────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.appBrand,
                  context.appBrand.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                  AppSpacing.screenHorizontal,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    // Back button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.white,
                              size: 14,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (customer.segment != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.white.withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  customer.segment!,
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (customer.segment != null)
                              const SizedBox(width: AppSpacing.xs),
                            GestureDetector(
                              onTap: () => _showEditSheet(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Avatar
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Center(
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: AppTypography.h1.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      customer.name,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Phone with copy
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: customer.phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Phone number copied')),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            customer.phone,
                            style: AppTypography.body.copyWith(
                              color:
                                  AppColors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color:
                                AppColors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _HeroStat(
                          label: 'Orders',
                          value: '${stats.totalOrders}',
                        ),
                        Container(
                            width: 1,
                            height: 32,
                            color: AppColors.white.withValues(alpha: 0.3)),
                        _HeroStat(
                          label: 'Total Spent',
                          value: MillimesFormatter.format(stats.totalSpent),
                        ),
                        Container(
                            width: 1,
                            height: 32,
                            color: AppColors.white.withValues(alpha: 0.3)),
                        _HeroStat(
                          label: 'Avg Order',
                          value: MillimesFormatter.format(
                              stats.avgOrderValue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Quick Actions ─────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.receipt_long_rounded,
                      label: 'New Order',
                      onTap: () => context.push('/orders/add'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: customer.phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Phone number copied')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Activity ──────────────────────────
              _SectionTitle(title: 'Activity'),
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
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'First order',
                      value: stats.firstOrderDate != null
                          ? DateFormatter.short(stats.firstOrderDate!)
                          : '—',
                    ),
                    Divider(height: AppSpacing.lg * 2, color: context.appBorder),
                    _InfoRow(
                      icon: Icons.update_rounded,
                      label: 'Last order',
                      value: stats.lastOrderDate != null
                          ? DateFormatter.relative(stats.lastOrderDate!)
                          : '—',
                    ),
                    Divider(height: AppSpacing.lg * 2, color: context.appBorder),
                    _InfoRow(
                      icon: Icons.trending_up_rounded,
                      label: 'Days since last order',
                      value: '${stats.daysSinceLastOrder} days',
                    ),
                    if (stats.avgDaysBetweenOrders != null) ...[
                      Divider(height: AppSpacing.lg * 2, color: context.appBorder),
                      _InfoRow(
                        icon: Icons.repeat_rounded,
                        label: 'Avg days between orders',
                        value:
                            '${stats.avgDaysBetweenOrders!.toStringAsFixed(0)} days',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Last Products ─────────────────────
              if (customer.lastProducts.isNotEmpty) ...[
                _SectionTitle(title: 'Last Purchased'),
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
                    children: customer.lastProducts
                        .asMap()
                        .entries
                        .map((entry) {
                      final i = entry.key;
                      final product = entry.value;
                      final isLast =
                          i == customer.lastProducts.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: context.appBrandLight,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.md),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18,
                                    color: context.appBrand,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.productName,
                                        style: AppTypography.body.copyWith(
                                          color: context.appTextPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        DateFormatter.relative(
                                            product.lastOrderedAt),
                                        style:
                                            AppTypography.caption.copyWith(
                                          color: context.appTextTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: product.inStock
                                        ? AppColors.successBg
                                        : AppColors.errorBg,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.full),
                                  ),
                                  child: Text(
                                    product.inStock
                                        ? 'In stock'
                                        : 'Out of stock',
                                    style: AppTypography.caption.copyWith(
                                      color: product.inStock
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                                height: 1, color: context.appBorder),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Notes ─────────────────────────────
              if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                _SectionTitle(title: 'Notes'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: context.isDark
                        ? Border.all(color: context.appBorder)
                        : null,
                    boxShadow: context.appCardShadow,
                  ),
                  child: Text(
                    customer.notes!,
                    style: AppTypography.body.copyWith(
                      color: context.appTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Default Discount ──────────────────
              if (customer.defaultDiscountAmount > 0) ...[
                _SectionTitle(title: 'Default Discount'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_rounded,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${MillimesFormatter.format(customer.defaultDiscountAmount)} discount',
                              style: AppTypography.body.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (customer.defaultDiscountExpiresAt !=
                                null)
                              Text(
                                'Expires ${DateFormatter.short(customer.defaultDiscountExpiresAt!)}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              const SizedBox(height: 60),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h3.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: context.isDark
              ? Border.all(color: context.appBorder)
              : null,
          boxShadow: context.appCardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.appBrand, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: context.appBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.h4.copyWith(color: context.appTextPrimary),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.appTextTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: context.appTextSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.body.copyWith(
            color: context.appTextPrimary,
            fontWeight: FontWeight.w500,
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
    return Column(
      children: [
        Container(height: 280, color: context.appSurfaceL2),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            children: [
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: context.appSurfaceL2,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 140,
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
          Text('Could not load client',
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

class _CustomerEditSheet extends ConsumerStatefulWidget {
  const _CustomerEditSheet({required this.customer});
  final CustomerDetail customer;

  @override
  ConsumerState<_CustomerEditSheet> createState() =>
      _CustomerEditSheetState();
}

class _CustomerEditSheetState
    extends ConsumerState<_CustomerEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _discountController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.customer.name);
    _phoneController =
        TextEditingController(text: widget.customer.phone);
    _notesController =
        TextEditingController(text: widget.customer.notes ?? '');
    _addressController =
        TextEditingController(text: widget.customer.address ?? '');
    _cityController =
        TextEditingController(text: widget.customer.city ?? '');
    _discountController = TextEditingController(
      text: widget.customer.defaultDiscountAmount > 0
          ? MillimesFormatter.toTnd(widget.customer.defaultDiscountAmount)
              .toStringAsFixed(0)
          : '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Name and phone are required');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = (await DioClient.getInstance()).dio;
      await dio.put(
        '/customers/${widget.customer.id}',
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          if (_notesController.text.trim().isNotEmpty)
            'notes': _notesController.text.trim(),
          if (_addressController.text.trim().isNotEmpty)
            'address': _addressController.text.trim(),
          if (_cityController.text.trim().isNotEmpty)
            'city': _cityController.text.trim(),
          'defaultDiscountAmount': ((double.tryParse(
                    _discountController.text.replaceAll(',', '.')) ??
                0) *
            1000).round(),
        },
      );
      ref.invalidate(customerDetailProvider(widget.customer.id));
      ref.invalidate(customerListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg,
              AppSpacing.xl, 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Client',
                  style: AppTypography.h3.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.appSurfaceL2,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _SheetLabel(label: 'Name *'),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.body.copyWith(
                        color: context.appTextPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Customer name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Phone
                  _SheetLabel(label: 'Phone *'),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.body.copyWith(
                        color: context.appTextPrimary),
                    decoration: const InputDecoration(
                      hintText: '+216 XX XXX XXX',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Address
                  _SheetLabel(label: 'Address'),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _addressController,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.body.copyWith(
                        color: context.appTextPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Street address (optional)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // City
                  _SheetLabel(label: 'City'),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _cityController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.body.copyWith(
                        color: context.appTextPrimary),
                    decoration: const InputDecoration(
                      hintText: 'City (optional)',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Default Discount
                  _SheetLabel(label: 'Default Discount (TND)'),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    style: AppTypography.body.copyWith(
                        color: context.appTextPrimary),
                    decoration: const InputDecoration(
                      hintText: '0',
                      suffixText: 'TND',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes
                  _SheetLabel(label: 'Notes'),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    style: AppTypography.body.copyWith(
                        color: context.appTextPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Preferences, size, notes...',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        _error!,
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appBrand,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            context.appBrand.withValues(alpha: 0.3),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
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
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.body.copyWith(
        color: context.appTextPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
