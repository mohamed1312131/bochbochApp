import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../core/api/dio_client.dart';
import '../../../customers/data/customer_repository.dart';
import '../../../customers/domain/customer_models.dart';
import '../providers/profit_provider.dart';
import '../../domain/profit_models.dart';

// ── Best Day provider ──────────────────────────────────────
final bestDayProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, period) async {
    final dio = (await DioClient.getInstance()).dio;
    final response = await dio.get(
      '/profit/best-day',
      queryParameters: {'period': period},
    );
    return response.data as Map<String, dynamic>;
  },
);

// ── Top customers provider ─────────────────────────────────
final topCustomersProvider =
    FutureProvider.autoDispose<List<CustomerLean>>((ref) async {
  final repo = CustomerRepository();
  final result = await repo.getCustomers(limit: 5);
  final sorted = [...result.data]
    ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
  return sorted.take(3).toList();
});

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
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
                    'Insights',
                    style: AppTypography.h1.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                  // Period selector
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
                      loading: () => _Skeleton(height: 160),
                      error: (e, _) => _ErrorCard(
                        onRetry: () => ref.invalidate(
                            profitSummaryProvider(_period)),
                      ),
                      data: (summary) => _SummaryCard(summary: summary),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Revenue Trend ─────────────
                    trendAsync.when(
                      loading: () => _Skeleton(height: 200),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (trend) => _TrendChart(trend: trend),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Best Day ──────────────────
                    bestDayAsync.when(
                      loading: () => _Skeleton(height: 160),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (data) => _BestDayCard(data: data),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Top Products ──────────────
                    byProductAsync.when(
                      loading: () => _Skeleton(height: 140),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (products) => products.isEmpty
                          ? const SizedBox.shrink()
                          : _TopProductsCard(products: products),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Top Clients ───────────────
                    topCustomersAsync.when(
                      loading: () => _Skeleton(height: 140),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (customers) => customers.isEmpty
                          ? const SizedBox.shrink()
                          : _TopClientsCard(customers: customers),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── AI Insights ───────────────
                    summaryAsync.maybeWhen(
                      data: (summary) => summary.insights.isEmpty
                          ? const SizedBox.shrink()
                          : _InsightsCard(insights: summary.insights),
                      orElse: () => const SizedBox.shrink(),
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

// ── Summary Card ───────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});
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

// ── Trend Chart ────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend});
  final ProfitTrend trend;

  @override
  Widget build(BuildContext context) {
    // Filter to only show last 14 data points for readability
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
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= points.length) {
                            return const SizedBox.shrink();
                          }
                          // Show only first, middle, and last label
                          final showLabel = idx == 0 ||
                              idx == points.length - 1 ||
                              idx == points.length ~/ 2 ||
                              idx == points.length ~/ 4 ||
                              idx == (points.length * 3) ~/ 4;
                          if (!showLabel) return const SizedBox.shrink();
                          final label = points[idx].label;
                          // Extract just the day number e.g. "Apr 12" → "12"
                          final short = label.contains(' ')
                              ? label.split(' ').last
                              : label;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
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
                          width: points.length > 20 ? 6 : points.length > 10 ? 10 : 16,
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

// ── Best Day Card ──────────────────────────────────────────
class _BestDayCard extends StatelessWidget {
  const _BestDayCard({required this.data});
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

// ── Top Products Card ──────────────────────────────────────
class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});
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

// ── Top Clients Card ───────────────────────────────────────
class _TopClientsCard extends StatelessWidget {
  const _TopClientsCard({required this.customers});
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

// ── AI Insights Card ───────────────────────────────────────
class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});
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

// ── Reusable ───────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
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
