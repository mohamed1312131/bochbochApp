import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../providers/dashboard_provider.dart';
import '../../domain/dashboard_models.dart';
import '../providers/profit_provider.dart';
import '../../domain/profit_models.dart';
import '../../../customers/domain/customer_models.dart';
import 'insights_screen.dart';

// ── User name provider ─────────────────────────────────────
final _userNameProvider = FutureProvider.autoDispose<String>((ref) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return await storage.read(key: 'user_full_name') ?? '';
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0; // 0 = Today, 1 = Insights

  String _greeting() {
    // Tunisia is UTC+1, no DST. Compute hour in Tunisia time so the greeting
    // does not depend on device locale.
    final hour = DateTime.now().toUtc().add(const Duration(hours: 1)).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(_userNameProvider);

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
                  userAsync.when(
                    data: (name) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()} 👋',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.appTextSecondary,
                          ),
                        ),
                        Text(
                          name.split(' ').first,
                          style: AppTypography.h1.copyWith(
                            color: context.appTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(width: 100, height: 40),
                    error: (_, __) => Text('Home',
                        style: AppTypography.h1
                            .copyWith(color: context.appTextPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: userAsync.maybeWhen(
                      data: (name) => Container(
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
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : 'U',
                            style: AppTypography.h4.copyWith(
                              color: context.appBrand,
                            ),
                          ),
                        ),
                      ),
                      orElse: () => const SizedBox(width: 44, height: 44),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Selector ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.appSurfaceL2,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Today',
                      icon: Icons.today_rounded,
                      selected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _TabButton(
                      label: 'Insights',
                      icon: Icons.insights_rounded,
                      selected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Content ────────────────────────────
            Expanded(
              child: _selectedTab == 0
                  ? _TodayView(ref: ref)
                  : const _InsightsView(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today View ────────────────────────────────────────────
class _TodayView extends StatelessWidget {
  const _TodayView({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            sliver: dashboardAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: _DashboardSkeleton(),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _ErrorCard(message: e.toString()),
              ),
              data: (dashboard) => SliverList(
                delegate: SliverChildListDelegate([
                  // Hero revenue card
                  _HeroCard(dashboard: dashboard),
                  const SizedBox(height: AppSpacing.md),

                  // Quick actions
                  _QuickActions(),
                  const SizedBox(height: AppSpacing.md),

                  // Low stock
                  if (dashboard.alerts.lowStockCount > 0) ...[
                    _AlertsCard(alerts: dashboard.alerts),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Backend-driven insights from dashboardProvider
                  if (dashboard.insights.isNotEmpty) ...[
                    _TodayInsightsCard(insights: dashboard.insights),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insights View ─────────────────────────────────────────
class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    return const _InsightsContent();
  }
}

class _InsightsContent extends ConsumerStatefulWidget {
  const _InsightsContent();

  @override
  ConsumerState<_InsightsContent> createState() => _InsightsContentState();
}

class _InsightsContentState extends ConsumerState<_InsightsContent> {
  String _period = 'month';

  final _periods = [
    ('today', 'Today'),
    ('week', 'Week'),
    ('month', 'Month'),
  ];

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(profitSummaryProvider(_period));
    final trendAsync = ref.watch(profitTrendProvider(_period));
    final byProductAsync = ref.watch(productProfitProvider(_period));
    final bestDayAsync = ref.watch(bestDayProvider(_period));
    final topCustomersAsync = ref.watch(topCustomersProvider);

    return Column(
      children: [
        // ── Period Selector ──────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _periods.map((p) {
                    final isSelected = _period == p.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _period = p.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.appBrand
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          p.$2,
                          style: AppTypography.label.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : context.appTextSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Scrollable content ─────────────────
        Expanded(
          child: RefreshIndicator(
            color: context.appBrand,
            onRefresh: () async {
              ref.invalidate(profitSummaryProvider(_period));
              ref.invalidate(profitTrendProvider(_period));
              ref.invalidate(productProfitProvider(_period));
              ref.invalidate(bestDayProvider(_period));
              ref.invalidate(topCustomersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                100,
              ),
              children: [
                // ── Summary Card ──────────────
                summaryAsync.when(
                  loading: () => _InsSkeleton(height: 160),
                  error: (e, _) => _InsRetryCard(
                    onRetry: () => ref.invalidate(
                        profitSummaryProvider(_period)),
                  ),
                  data: (summary) => _InsSummaryCard(summary: summary),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Revenue Trend ─────────────
                trendAsync.when(
                  loading: () => _InsSkeleton(height: 200),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (trend) => _InsTrendChart(trend: trend),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Best Day ──────────────────
                bestDayAsync.when(
                  loading: () => _InsSkeleton(height: 160),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) => _InsBestDayCard(data: data),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Top Products ──────────────
                byProductAsync.when(
                  loading: () => _InsSkeleton(height: 140),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (products) => products.isEmpty
                      ? const SizedBox.shrink()
                      : _InsTopProductsCard(products: products),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Top Clients ───────────────
                topCustomersAsync.when(
                  loading: () => _InsSkeleton(height: 140),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (customers) => customers.isEmpty
                      ? const SizedBox.shrink()
                      : _InsTopClientsCard(customers: customers),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── AI Insights ───────────────
                summaryAsync.maybeWhen(
                  data: (summary) => summary.insights.isEmpty
                      ? const SizedBox.shrink()
                      : _InsAiCard(insights: summary.insights),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab Button ────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  const _TabButton({
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.appSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: selected ? context.appCardShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? context.appBrand
                    : context.appTextTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.body.copyWith(
                  color: selected
                      ? context.appBrand
                      : context.appTextTertiary,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Today tab widgets (unchanged)
// ══════════════════════════════════════════════════════════

// ── Hero Card ──────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.dashboard});
  final DashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final today = dashboard.today;
    final isProfit = today.realProfit > 0;
    final isLoss = today.realProfit < 0;
    final hasOrders = today.orderCount > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF05687B), Color(0xFF023D49)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF05687B).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today you made 💰',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    hasOrders
                        ? '${today.orderCount} ${today.orderCount == 1 ? 'sale' : 'sales'}'
                        : 'No sales yet',
                    style: AppTypography.label.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Big revenue number
            Text(
              MillimesFormatter.format(today.grossRevenue),
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: -1.5,
              ),
            ),
            Text(
              'revenue',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Divider
            Container(
              height: 1,
              color: AppColors.white.withValues(alpha: 0.15),
            ),

            const SizedBox(height: AppSpacing.md),

            // Profit + orders row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real Profit',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            MillimesFormatter.format(today.realProfit),
                            style: AppTypography.h4.copyWith(
                              color: isProfit
                                  ? const Color(0xFF4ADE80)
                                  : isLoss
                                      ? const Color(0xFFFC8181)
                                      : AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isProfit
                                ? Icons.trending_up_rounded
                                : isLoss
                                    ? Icons.trending_down_rounded
                                    : Icons.remove_rounded,
                            size: 16,
                            color: isProfit
                                ? const Color(0xFF4ADE80)
                                : isLoss
                                    ? const Color(0xFFFC8181)
                                    : AppColors.white
                                        .withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.white.withValues(alpha: 0.15),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orders',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${today.orderCount}',
                          style: AppTypography.h4.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Empty state nudge
            if (!hasOrders) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Log your first sale to see real profit',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/orders/add'),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: context.appBrand,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Log Sale',
                    style: AppTypography.body.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (FeatureFlags.aiEnabled) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/ai-studio'),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: context.appBrandLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: context.appBrand.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: context.appBrand,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Create Post',
                      style: AppTypography.body.copyWith(
                        color: context.appBrand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Alerts Card ────────────────────────────────────────────
class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});
  final DashboardAlerts alerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Low Stock Alert',
                    style: AppTypography.h4.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Center(
                    child: Text(
                      '${alerts.lowStockCount}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.appBorder),
          ...alerts.lowStockProducts.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.productName,
                          style: AppTypography.body.copyWith(
                            color: context.appTextPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          p.variantSku,
                          style: AppTypography.caption.copyWith(
                            color: context.appTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.stockQuantity <= 1
                          ? AppColors.errorBg
                          : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${p.stockQuantity} left',
                      style: AppTypography.label.copyWith(
                        color: p.stockQuantity <= 1
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/products'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Center(
                child: Text(
                  'Restock Items →',
                  style: AppTypography.label.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today Insights Card ───────────────────────────────────
// Backend-driven: renders dashboard.insights from dashboardProvider.
class _TodayInsightsCard extends StatelessWidget {
  const _TodayInsightsCard({required this.insights});
  final List<String> insights;

  bool _isArabic(String text) {
    return RegExp('[؀-ۿ]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF05687B), Color(0xFF023D49)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  "Today's Insights",
                  style: AppTypography.h4.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.appBorder),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: insights.take(3).map((insight) {
                final isArabic = _isArabic(insight);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          insight,
                          textDirection: isArabic
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: AppTypography.body.copyWith(
                            color: context.appTextPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonBox(height: 220),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBox(height: 52),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBox(height: 120),
        const SizedBox(height: AppSpacing.md),
        _SkeletonBox(height: 160),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceL1,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}

// ── Error Card ─────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.error,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Could not load dashboard',
            style: AppTypography.h4.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to retry',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Insights tab widgets (from insights_screen.dart)
// ══════════════════════════════════════════════════════════

// ── Insights Summary Card ─────────────────────────────────
class _InsSummaryCard extends StatelessWidget {
  const _InsSummaryCard({required this.summary});
  final ProfitSummary summary;

  @override
  Widget build(BuildContext context) {
    final isProfit = summary.realProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.appBrand,
            context.appBrand.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                summary.periodLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${summary.orderCount} orders',
                  style: AppTypography.label.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            MillimesFormatter.format(summary.netRevenue),
            style: AppTypography.h1.copyWith(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'revenue',
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 1,
            color: AppColors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real Profit',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          MillimesFormatter.format(summary.realProfit),
                          style: AppTypography.h4.copyWith(
                            color: isProfit
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFCA5A5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isProfit
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isProfit
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.white.withValues(alpha: 0.2)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Margin',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '${summary.profitMarginPct.toStringAsFixed(1)}%',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.white.withValues(alpha: 0.2)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Returns',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '${summary.returnCount}',
                      style: AppTypography.h4.copyWith(
                        color: summary.returnCount > 0
                            ? const Color(0xFFFCA5A5)
                            : AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Insights Trend Chart ──────────────────────────────────
class _InsTrendChart extends StatelessWidget {
  const _InsTrendChart({required this.trend});
  final ProfitTrend trend;

  @override
  Widget build(BuildContext context) {
    final points = trend.dataPoints.length > 14
        ? trend.dataPoints.sublist(trend.dataPoints.length - 14)
        : trend.dataPoints;

    final maxRevenue = points
        .map((p) => p.grossRevenue)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    final hasData = points.any((p) => p.grossRevenue > 0);

    return Container(
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
          Text(
            'Revenue Trend',
            style: AppTypography.h4.copyWith(
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            trend.periodLabel,
            style: AppTypography.caption.copyWith(
              color: context.appTextTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasData)
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  'No sales data yet',
                  style: AppTypography.body.copyWith(
                    color: context.appTextTertiary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  maxY: maxRevenue * 1.2,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: context.appBorder,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (points.length / 4).ceilToDouble(),
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final label = points[idx].label;
                          final short = label.length > 6
                              ? label.substring(0, 6)
                              : label;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              short,
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                                color: context.appTextTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(points.length, (i) {
                    final p = points[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: p.grossRevenue.toDouble(),
                          color: p.grossRevenue > 0
                              ? context.appBrand
                              : context.appBorder,
                          width: points.length > 10 ? 8 : 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Insights Best Day Card ────────────────────────────────
class _InsBestDayCard extends StatelessWidget {
  const _InsBestDayCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final bestDay = data['bestDay'] as String?;
    final dataByDay = data['dataByDay'] as List;
    final maxRevenue = dataByDay
        .map((d) => (d['revenue'] as int?) ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    if (bestDay == null) return const SizedBox.shrink();

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best Day',
                style: AppTypography.h4
                    .copyWith(color: context.appTextPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: context.appBrandLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '🏆 $bestDay',
                  style: AppTypography.label.copyWith(
                    color: context.appBrand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dataByDay.map((d) {
              final day = d['day'] as String;
              final revenue = (d['revenue'] as int?) ?? 0;
              final short = day.substring(0, 3);
              final isMax = revenue == maxRevenue && revenue > 0;
              final barHeight = maxRevenue > 0
                  ? (revenue / maxRevenue * 80).toDouble()
                  : 4.0;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: barHeight.clamp(4.0, 80.0),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isMax
                            ? context.appBrand
                            : context.appBrand.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      short,
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        color: isMax
                            ? context.appBrand
                            : context.appTextTertiary,
                        fontWeight: isMax
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Post on ${_prevDay(bestDay)} evening to maximize $bestDay sales',
            style: AppTypography.caption.copyWith(
              color: context.appTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _prevDay(String day) {
    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday'
    ];
    final idx = days.indexOf(day);
    return days[(idx - 1 + 7) % 7];
  }
}

// ── Insights Top Products Card ────────────────────────────
class _InsTopProductsCard extends StatelessWidget {
  const _InsTopProductsCard({required this.products});
  final List<ProductProfit> products;

  @override
  Widget build(BuildContext context) {
    final top = products.take(3).toList();
    final medals = ['🥇', '🥈', '🥉'];

    return Container(
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
          Text(
            'Top Products',
            style: AppTypography.h4
                .copyWith(color: context.appTextPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          ...top.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final isLast = i == top.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(
                        medals[i],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.productName,
                              style: AppTypography.body.copyWith(
                                color: context.appTextPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${p.unitsSold} sold · ${p.profitMarginPct.toStringAsFixed(0)}% margin',
                              style: AppTypography.caption.copyWith(
                                color: context.appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${MillimesFormatter.format(p.profit)}',
                        style: AppTypography.body.copyWith(
                          color: p.profit > 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(height: 1, color: context.appBorder),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Insights Top Clients Card ─────────────────────────────
class _InsTopClientsCard extends StatelessWidget {
  const _InsTopClientsCard({required this.customers});
  final List<CustomerLean> customers;

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];

    return Container(
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
          Text(
            'Top Clients',
            style: AppTypography.h4
                .copyWith(color: context.appTextPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          ...customers.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final isLast = i == customers.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(
                        medals[i],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.appBrandLight,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Center(
                          child: Text(
                            c.name[0].toUpperCase(),
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
                            Text(
                              c.name,
                              style: AppTypography.body.copyWith(
                                color: context.appTextPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${c.totalOrders} order${c.totalOrders == 1 ? '' : 's'}',
                              style: AppTypography.caption.copyWith(
                                color: context.appTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        MillimesFormatter.format(c.totalSpent),
                        style: AppTypography.body.copyWith(
                          color: context.appBrand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(height: 1, color: context.appBorder),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Insights AI Card ──────────────────────────────────────
class _InsAiCard extends StatelessWidget {
  const _InsAiCard({required this.insights});
  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.appBrand,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.white, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'AI Insights',
                style: AppTypography.h4
                    .copyWith(color: context.appTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...insights.asMap().entries.map((entry) {
            final i = entry.key;
            final insight = entry.value;
            final isLast = i == insights.length - 1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.appSurfaceL2,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    insight,
                    style: AppTypography.body.copyWith(
                      color: context.appTextPrimary,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                if (!isLast) const SizedBox(height: AppSpacing.xs),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Insights Skeleton ─────────────────────────────────────
class _InsSkeleton extends StatelessWidget {
  const _InsSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.appSurfaceL2,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}

// ── Insights Retry Card ───────────────────────────────────
class _InsRetryCard extends StatelessWidget {
  const _InsRetryCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Center(
          child: Text(
            'Tap to retry',
            style: AppTypography.body
                .copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
