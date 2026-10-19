import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/french_plural.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/providers/user_name_provider.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../boutiques/presentation/boutique_providers.dart';
import '../../../profit/domain/profit_models.dart';
import '../../../profit/presentation/providers/profit_provider.dart';
import '../../../stock/domain/stock_models.dart';
import '../../../stock/presentation/providers/stock_provider.dart';
import '../../../stock/presentation/widgets/stock_dead_stock_card.dart';
import '../../../stock/presentation/widgets/stock_sortie_pertes_card.dart';

// Day-of-week aggregate provider (unchanged endpoint)
final _bestDayProvider =
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

enum _Period { today, week, month }

extension on _Period {
  String get apiValue => switch (this) {
        _Period.today => 'today',
        _Period.week => 'week',
        _Period.month => 'month',
      };
  String get tabLabel => switch (this) {
        _Period.today => 'Aujourd’hui',
        _Period.week => 'Semaine',
        _Period.month => 'Mois',
      };
  String get summaryLabel => switch (this) {
        _Period.today => 'Aujourd’hui',
        _Period.week => 'Cette semaine',
        _Period.month => 'Ce mois',
      };
}

String _granularityLabel(String granularity) => switch (granularity) {
      'hourly' => 'Par heure',
      'daily' => 'Par jour',
      'weekly' => 'Par semaine',
      _ => '',
    };

const _dayShort = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

const _dayLongFr = {
  'Sunday': 'Dimanche',
  'Monday': 'Lundi',
  'Tuesday': 'Mardi',
  'Wednesday': 'Mercredi',
  'Thursday': 'Jeudi',
  'Friday': 'Vendredi',
  'Saturday': 'Samedi',
};

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _Period _period = _Period.month;

  Future<void> _refresh() async {
    final p = _period.apiValue;
    ref.invalidate(profitSummaryProvider(p));
    ref.invalidate(profitTrendProvider(p));
    ref.invalidate(productProfitProvider(p));
    ref.invalidate(_bestDayProvider(p));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = _period.apiValue;
    final summaryAsync = ref.watch(profitSummaryProvider(p));
    final trendAsync = ref.watch(profitTrendProvider(p));
    final productsAsync = ref.watch(productProfitProvider(p));
    final bestDayAsync = ref.watch(_bestDayProvider(p));

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
                  'Stats',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
              ),
            ),
            _PeriodTabs(
              current: _period,
              onSelected: (p) => setState(() => _period = p),
            ),
            SizedBox(height: context.spacing.space3),
            Expanded(
              child: summaryAsync.when(
                loading: () => const _StatsSkeleton(),
                error: (_, __) => _ErrorState(onRetry: _refresh),
                data: (summary) => RefreshIndicator(
                  color: c.fg1,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      context.spacing.screenEdge,
                      0,
                      context.spacing.screenEdge,
                      context.spacing.space8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryCard(
                          summary: summary,
                          periodLabel: _period.summaryLabel,
                        ),
                        SizedBox(height: context.spacing.space6),
                        _RevenueTrendCard(asyncTrend: trendAsync),
                        SizedBox(height: context.spacing.space6),
                        _BestDayCard(asyncBestDay: bestDayAsync),
                        SizedBox(height: context.spacing.space6),
                        _TopProductsCard(asyncProducts: productsAsync),
                        if (summary.insights.isNotEmpty) ...[
                          SizedBox(height: context.spacing.space6),
                          _AIInsightsCard(insights: summary.insights),
                        ],
                        SizedBox(height: context.spacing.space6),
                        const _StockValueCard(),
                        SizedBox(height: context.spacing.space6),
                        const _BestSellersCard(),
                        SizedBox(height: context.spacing.space6),
                        const _SlowMoversCard(),
                        SizedBox(height: context.spacing.space6),
                        const _OffSaleAndShrinkageSection(),
                        SizedBox(height: context.spacing.space6),
                        const _DormantStockCard(),
                      ],
                    ),
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

// ════════════════════════════════════════════════════════════
// Header pieces (duplicated — TODO(extract))
// ════════════════════════════════════════════════════════════
class _BoutiqueChip extends ConsumerWidget {
  const _BoutiqueChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final boutiqueAsync = ref.watch(currentBoutiqueProvider);
    final boutique = boutiqueAsync.valueOrNull;
    final name = boutique?.name ?? '—';
    final initial = (name.isNotEmpty && name != '—')
        ? name.characters.first.toUpperCase()
        : '·';

    return _ScaleTap(
      // No boutique-switcher screen exists yet; tap is inert.
      onTap: null,
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
                initial,
                style: context.typography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.surface0,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Text(
              name,
              style: context.typography.bodyMd.copyWith(color: c.fg1),
            ),
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
            // Unread-notification dot hidden until a notifications
            // provider exists (was hardcoded `true`).
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Period tabs (underline)
// ════════════════════════════════════════════════════════════
class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.current, required this.onSelected});
  final _Period current;
  final ValueChanged<_Period> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.screenEdge),
      child: Row(
        children: [
          for (final p in _Period.values) ...[
            _PeriodTab(
              label: p.tabLabel,
              selected: current == p,
              onTap: () => onSelected(p),
            ),
            SizedBox(width: context.spacing.space4),
          ],
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.spacing.space2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? c.fg1 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: context.typography.h4.copyWith(
            color: selected ? c.fg1 : c.fg3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Summary card
// ════════════════════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.periodLabel});
  final ProfitSummary summary;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final orderDelta = _orderDelta(summary);

    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MillimesFormatter.format(summary.grossRevenue),
            style: context.typography.h1.copyWith(
              color: c.fg1,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.spacing.space1),
          Row(
            children: [
              Text(
                periodLabel,
                style: context.typography.bodySmall
                    .copyWith(color: c.fg3),
              ),
              SizedBox(width: context.spacing.space2),
              if (summary.revenueChangePercent != null)
                _DeltaBadge(delta: summary.revenueChangePercent!),
            ],
          ),
          SizedBox(height: context.spacing.space4),
          Container(height: 1, color: c.border1),
          SizedBox(height: context.spacing.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SubStat(
                  label: 'Bénéfice',
                  value: MillimesFormatter.format(summary.realProfit),
                  delta: summary.profitChangePercent,
                ),
              ),
              Expanded(
                child: _SubStat(
                  label: 'Commandes',
                  value: '${summary.orderCount}',
                  delta: orderDelta,
                ),
              ),
              Expanded(
                child: _SubStat(
                  label: 'Marge',
                  value: '${summary.profitMarginPct.toStringAsFixed(1)}%',
                  delta: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int? _orderDelta(ProfitSummary s) {
    final prev = s.prevOrderCount;
    if (prev == null || prev == 0) return null;
    return ((s.orderCount - prev) / prev * 100).round();
  }
}

class _SubStat extends StatelessWidget {
  const _SubStat({
    required this.label,
    required this.value,
    required this.delta,
  });

  final String label;
  final String value;
  final int? delta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.bodySmall.copyWith(color: c.fg3),
        ),
        SizedBox(height: context.spacing.space1),
        Text(
          value,
          style: context.typography.h4.copyWith(
            color: c.fg1,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (delta != null) ...[
          SizedBox(height: context.spacing.space1),
          _DeltaText(delta: delta!),
        ],
      ],
    );
  }
}

class _DeltaText extends StatelessWidget {
  const _DeltaText({required this.delta});
  final int delta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final up = delta >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 10,
          color: up ? c.greenFg : c.coralFg,
        ),
        const SizedBox(width: 2),
        Text(
          '${delta.abs()}%',
          style: context.typography.bodySmall.copyWith(
            color: up ? c.greenFg : c.coralFg,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta});
  final int delta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final up = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: up ? c.greenTint12 : c.coralTint12,
        borderRadius: BorderRadius.circular(context.radius.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: up ? c.greenFg : c.coralFg,
          ),
          const SizedBox(width: 2),
          Text(
            '${delta.abs()}%',
            style: context.typography.tabPill.copyWith(
              color: up ? c.greenFg : c.coralFg,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Revenue trend card
// ════════════════════════════════════════════════════════════
class _RevenueTrendCard extends StatelessWidget {
  const _RevenueTrendCard({required this.asyncTrend});
  final AsyncValue<ProfitTrend> asyncTrend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: asyncTrend.when(
        loading: () => SizedBox(
          height: 220,
          child: _ShimmerBlock(radius: context.radius.radiusInput),
        ),
        error: (_, __) => _CardEmpty(
          icon: Icons.show_chart_rounded,
          message: 'Impossible de charger l’évolution',
        ),
        data: (trend) {
          final points = trend.dataPoints.length > 30
              ? trend.dataPoints
                  .sublist(trend.dataPoints.length - 30)
              : trend.dataPoints;
          final hasData = points.any((p) => p.grossRevenue > 0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Évolution',
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  const Spacer(),
                  Text(
                    _granularityLabel(trend.granularity),
                    style: context.typography.bodySmall
                        .copyWith(color: c.fg3),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.space3),
              if (!hasData)
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: context.spacing.space6),
                  child: _CardEmpty(
                    icon: Icons.bar_chart_rounded,
                    message: 'Aucune donnée pour cette période',
                  ),
                )
              else ...[
                SizedBox(
                  height: 180,
                  child: _RevenueBarChart(points: points),
                ),
                SizedBox(height: context.spacing.space2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      points.first.label,
                      style: context.typography.bodySmall
                          .copyWith(color: c.fg3),
                    ),
                    Text(
                      points.last.label,
                      style: context.typography.bodySmall
                          .copyWith(color: c.fg3),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.points});
  final List<TrendDataPoint> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxRevenue = points
        .map((p) => p.grossRevenue)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();

    final barWidth = points.length > 20
        ? 6.0
        : points.length > 10
            ? 10.0
            : 14.0;

    return BarChart(
      BarChartData(
        maxY: maxRevenue * 1.2,
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => c.fg1,
            tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            tooltipMargin: 6,
            getTooltipItem: (group, _, __, ___) {
              final p = points[group.x];
              return BarTooltipItem(
                '${p.label}\n${MillimesFormatter.format(p.grossRevenue)}',
                context.typography.bodySmall.copyWith(
                  color: c.surface0,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].grossRevenue.toDouble(),
                  color: points[i].grossRevenue > 0 ? c.fg1 : c.surface3,
                  width: barWidth,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Best day card
// ════════════════════════════════════════════════════════════
class _BestDayCard extends StatelessWidget {
  const _BestDayCard({required this.asyncBestDay});
  final AsyncValue<Map<String, dynamic>> asyncBestDay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: asyncBestDay.when(
        loading: () => SizedBox(
          height: 200,
          child: _ShimmerBlock(radius: context.radius.radiusInput),
        ),
        error: (_, __) => _CardEmpty(
          icon: Icons.calendar_today_outlined,
          message: 'Impossible de charger les jours',
        ),
        data: (data) {
          final bestDayEn = data['bestDay'] as String?;
          final dataByDay = data['dataByDay'] as List;
          final maxRevenue = dataByDay
              .map((d) => (d['revenue'] as int?) ?? 0)
              .fold<int>(0, (a, b) => a > b ? a : b);

          final bestDayFr = bestDayEn == null
              ? null
              : (_dayLongFr[bestDayEn] ?? bestDayEn);

          final bestDayRevenue = data['bestDayRevenue'] as int? ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meilleur jour',
                style: context.typography.h4.copyWith(color: c.fg1),
              ),
              SizedBox(height: context.spacing.space1),
              Text(
                bestDayFr == null
                    ? 'Pas encore de ventes cette période'
                    : '$bestDayFr — ${MillimesFormatter.format(bestDayRevenue)}',
                style: context.typography.bodySmall
                    .copyWith(color: c.fg3),
              ),
              SizedBox(height: context.spacing.space4),
              if (maxRevenue == 0)
                _CardEmpty(
                  icon: Icons.calendar_today_outlined,
                  message: 'Pas encore de ventes cette période',
                )
              else
                SizedBox(
                  height: 140,
                  child: _BestDayBarChart(
                    dataByDay: dataByDay,
                    bestDay: bestDayEn,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BestDayBarChart extends StatelessWidget {
  const _BestDayBarChart({
    required this.dataByDay,
    required this.bestDay,
  });

  final List dataByDay;
  final String? bestDay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxRevenue = dataByDay
        .map((d) => (d['revenue'] as int?) ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxRevenue * 1.2,
        minY: 0,
        gridData: const FlGridData(show: false),
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
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _dayShort.length) {
                  return const SizedBox.shrink();
                }
                final dayEn = dataByDay[i]['day'] as String;
                final isBest = dayEn == bestDay;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _dayShort[i],
                    style: context.typography.bodySmall.copyWith(
                      color: isBest ? c.fg1 : c.fg3,
                      fontWeight:
                          isBest ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => c.fg1,
            tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            tooltipMargin: 6,
            getTooltipItem: (group, _, __, ___) {
              final d = dataByDay[group.x];
              final dayEn = d['day'] as String;
              final dayFr = _dayLongFr[dayEn] ?? dayEn;
              final revenue = (d['revenue'] as int?) ?? 0;
              final orderCount = (d['orderCount'] as int?) ?? 0;
              return BarTooltipItem(
                '$dayFr\n${MillimesFormatter.format(revenue)}\n$orderCount commandes',
                context.typography.bodySmall.copyWith(
                  color: c.surface0,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < dataByDay.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ((dataByDay[i]['revenue'] as int?) ?? 0)
                      .toDouble(),
                  color: (dataByDay[i]['day'] as String) == bestDay
                      ? c.fg1
                      : c.fg3,
                  width: 18,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Top products card
// ════════════════════════════════════════════════════════════
class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.asyncProducts});
  final AsyncValue<List<ProductProfit>> asyncProducts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: asyncProducts.when(
        loading: () => SizedBox(
          height: 140,
          child: _ShimmerBlock(radius: context.radius.radiusInput),
        ),
        error: (_, __) => _CardEmpty(
          icon: Icons.inventory_2_outlined,
          message: 'Impossible de charger les produits',
        ),
        data: (products) {
          final top = products.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top produits',
                style: context.typography.h4.copyWith(color: c.fg1),
              ),
              SizedBox(height: context.spacing.space3),
              if (top.isEmpty)
                Text(
                  'Aucune vente pour cette période.',
                  style: context.typography.bodyMd.copyWith(color: c.fg3),
                )
              else
                for (var i = 0; i < top.length; i++) ...[
                  _TopProductRow(rank: i + 1, product: top[i]),
                  if (i < top.length - 1)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: context.spacing.space2),
                      child: Container(height: 1, color: c.border1),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({required this.rank, required this.product});
  final int rank;
  final ProductProfit product;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$rank',
            style: context.typography.h3.copyWith(
              color: c.fg3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: context.spacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.h4.copyWith(color: c.fg1),
              ),
              const SizedBox(height: 2),
              Text(
                '${product.unitsSold} vendus · marge ${product.profitMarginPct.toStringAsFixed(0)}%',
                style: context.typography.bodySmall
                    .copyWith(color: c.fg3),
              ),
            ],
          ),
        ),
        SizedBox(width: context.spacing.space2),
        Text(
          '+${MillimesFormatter.format(product.profit)}',
          style: context.typography.bodyMd.copyWith(
            color: c.greenFg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// AI insights card
// ════════════════════════════════════════════════════════════
class _AIInsightsCard extends StatelessWidget {
  const _AIInsightsCard({required this.insights});
  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 18, color: c.fg1),
              SizedBox(width: context.spacing.space2),
              Text(
                'Aperçu IA',
                style: context.typography.h4.copyWith(color: c.fg1),
              ),
            ],
          ),
          SizedBox(height: context.spacing.space3),
          for (var i = 0; i < insights.length; i++) ...[
            _InsightBullet(text: insights[i]),
            if (i < insights.length - 1)
              SizedBox(height: context.spacing.space2),
          ],
        ],
      ),
    );
  }
}

class _InsightBullet extends StatelessWidget {
  const _InsightBullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: c.fg2,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: context.spacing.space2),
        Expanded(
          child: Text(
            text,
            style: context.typography.bodyMd.copyWith(
              color: c.fg2,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Empty / error / skeleton helpers
// ════════════════════════════════════════════════════════════
class _CardEmpty extends StatelessWidget {
  const _CardEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: c.fg3),
          SizedBox(height: context.spacing.space2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.typography.bodyMd.copyWith(color: c.fg3),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
          duration: const Duration(milliseconds: 1500),
          color: c.surface3,
        );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        context.spacing.screenEdge,
        0,
        context.spacing.screenEdge,
        context.spacing.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkeletonCard(height: 160),
          SizedBox(height: context.spacing.space6),
          _SkeletonCard(height: 240),
          SizedBox(height: context.spacing.space6),
          _SkeletonCard(height: 220),
          SizedBox(height: context.spacing.space6),
          _SkeletonCard(height: 180),
          SizedBox(height: context.spacing.space6),
          _SkeletonCard(height: 140),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: _ShimmerBlock(radius: context.radius.radiusCard),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;

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
              'Impossible de charger les statistiques',
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

// ════════════════════════════════════════════════════════════
// Stock — Valeur du stock card
// ════════════════════════════════════════════════════════════
class _StockValueCard extends ConsumerWidget {
  const _StockValueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final asyncValue = ref.watch(stockValueProvider);
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: asyncValue.when(
        loading: () => SizedBox(
          height: 80,
          child: _ShimmerBlock(radius: context.radius.radiusInput),
        ),
        error: (_, __) => _CardEmpty(
          icon: Icons.inventory_outlined,
          message: 'Impossible de charger la valeur du stock',
        ),
        data: (report) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Valeur du stock',
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valeur totale',
                        style: context.typography.label.copyWith(color: c.fg3),
                      ),
                      SizedBox(height: context.spacing.space1),
                      Text(
                        MillimesFormatter.format(report.totalValue),
                        style: context.typography.h1Product
                            .copyWith(color: c.fg1),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Unités',
                      style: context.typography.label.copyWith(color: c.fg3),
                    ),
                    SizedBox(height: context.spacing.space1),
                    Text(
                      '${report.totalUnits}',
                      style:
                          context.typography.tileNum.copyWith(color: c.fg1),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: context.spacing.space3),
            Container(height: 1, color: c.border1),
            SizedBox(height: context.spacing.space2),
            _LinkRow(
              label: 'Voir détail',
              onTap: () => _showSoonSnack(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.typography.button.copyWith(color: c.fg1),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: c.fg1),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Stock — Top ventes / Produits lents (shared list shell)
// ════════════════════════════════════════════════════════════
class _BestSellersCard extends ConsumerWidget {
  const _BestSellersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final asyncList = ref.watch(bestSellersProvider);
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: asyncList.when(
        loading: () => SizedBox(
          height: 200,
          child: _ShimmerBlock(radius: context.radius.radiusInput),
        ),
        error: (_, __) => _CardEmpty(
          icon: Icons.trending_up_rounded,
          message: 'Impossible de charger les top ventes',
        ),
        data: (entries) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top ventes',
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space3),
            if (entries.isEmpty)
              Text(
                'Aucune vente cette période.',
                style: context.typography.bodyMd.copyWith(color: c.fg3),
              )
            else
              for (var i = 0; i < entries.length; i++) ...[
                _StockRankRow(
                  index: i + 1,
                  productName: entries[i].productName,
                  secondaryLine: '${entries[i].unitsSold} unités',
                  rightText: MillimesFormatter.format(entries[i].revenue),
                  rightColor: c.fg1,
                  thumbnailColor: entries[i].thumbnailColor,
                ),
                if (i < entries.length - 1)
                  SizedBox(height: context.spacing.space2),
              ],
          ],
        ),
      ),
    );
  }
}

class _SlowMoversCard extends ConsumerWidget {
  const _SlowMoversCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final asyncList = ref.watch(slowMoversProvider);
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: asyncList.when(
        loading: () => SizedBox(
          height: 200,
          child: _ShimmerBlock(radius: context.radius.radiusInput),
        ),
        error: (_, __) => _CardEmpty(
          icon: Icons.trending_down_rounded,
          message: 'Impossible de charger les produits lents',
        ),
        data: (entries) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produits lents',
              style: context.typography.h4.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space3),
            if (entries.isEmpty)
              Text(
                'Aucun produit lent.',
                style: context.typography.bodyMd.copyWith(color: c.fg3),
              )
            else
              for (var i = 0; i < entries.length; i++) ...[
                _StockRankRow(
                  index: i + 1,
                  productName: entries[i].productName,
                  secondaryLine:
                      frenchPlural(entries[i].unitsSold, 'vendu', 'vendus'),
                  rightText: '${entries[i].unitsRemaining} en stock',
                  rightColor: c.fg2,
                  thumbnailColor: entries[i].thumbnailColor,
                ),
                if (i < entries.length - 1)
                  SizedBox(height: context.spacing.space2),
              ],
          ],
        ),
      ),
    );
  }
}

class _StockRankRow extends StatelessWidget {
  const _StockRankRow({
    required this.index,
    required this.productName,
    required this.secondaryLine,
    required this.rightText,
    required this.rightColor,
    this.thumbnailColor,
  });

  final int index;
  final String productName;
  final String secondaryLine;
  final String rightText;
  final Color rightColor;
  final int? thumbnailColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$index.',
            style: context.typography.bodyMd.copyWith(color: c.fg3),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: thumbnailColor != null
                ? Color(thumbnailColor!)
                : c.surface3,
            borderRadius:
                BorderRadius.circular(context.radius.radiusTile),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.bodyMd.copyWith(color: c.fg1),
              ),
              const SizedBox(height: 2),
              Text(
                secondaryLine,
                style:
                    context.typography.bodySmall.copyWith(color: c.fg3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          rightText,
          style: context.typography.bodyMdNum.copyWith(color: rightColor),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Stock — Sortie hors-vente · Pertes (stacked, single header)
// ════════════════════════════════════════════════════════════
class _OffSaleAndShrinkageSection extends ConsumerWidget {
  const _OffSaleAndShrinkageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final offSaleAsync = ref.watch(offSaleOutflowProvider);
    final shrinkageAsync = ref.watch(shrinkageProvider);

    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sortie hors-vente · Pertes ce mois',
            style: context.typography.h4.copyWith(color: c.fg1),
          ),
          SizedBox(height: context.spacing.space3),
          _BreakdownBlock(
            subtitle: 'Sortie hors-vente',
            asyncBreakdown: offSaleAsync.whenData(
              (b) => _Breakdown(
                rows: b.byReason,
                totalUnits: b.totalUnits,
                totalAmount: b.totalAmount,
              ),
            ),
            totalAmountColor: c.fg1,
            onLinkTap: () => context.push('/stock/shrinkage?tab=1'),
          ),
          SizedBox(height: context.spacing.space5),
          _BreakdownBlock(
            subtitle: 'Pertes',
            asyncBreakdown: shrinkageAsync.whenData(
              (b) => _Breakdown(
                rows: b.byReason,
                totalUnits: b.totalUnits,
                totalAmount: b.totalAmount,
              ),
            ),
            totalAmountColor: c.redFg,
            onLinkTap: () => context.push('/stock/shrinkage'),
          ),
        ],
      ),
    );
  }
}

class _Breakdown {
  const _Breakdown({
    required this.rows,
    required this.totalUnits,
    required this.totalAmount,
  });
  final List<StockBreakdownByReason> rows;
  final int totalUnits;
  final int totalAmount;
}

class _BreakdownBlock extends StatelessWidget {
  const _BreakdownBlock({
    required this.subtitle,
    required this.asyncBreakdown,
    required this.totalAmountColor,
    required this.onLinkTap,
  });

  final String subtitle;
  final AsyncValue<_Breakdown> asyncBreakdown;
  final Color totalAmountColor;
  final VoidCallback onLinkTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          subtitle.toUpperCase(),
          style: context.typography.label.copyWith(color: c.fg3),
        ),
        SizedBox(height: context.spacing.space2),
        asyncBreakdown.when(
          loading: () => SizedBox(
            height: 120,
            child: _ShimmerBlock(radius: context.radius.radiusInput),
          ),
          error: (_, __) => _CardEmpty(
            icon: Icons.error_outline,
            message: 'Impossible de charger',
          ),
          data: (b) {
            final breakdownRows = <StockBreakdownRow>[
              for (final r in b.rows)
                StockBreakdownRow(
                  label: r.reasonLabel,
                  count: frenchPlural(r.units, 'unité', 'unités'),
                  amount: MillimesFormatter.format(r.amount),
                ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StockSortiePertesCard(
                  rows: breakdownRows,
                  total: StockBreakdownRow(
                    label: 'Total',
                    count: '${b.totalUnits} unités',
                    amount: MillimesFormatter.format(b.totalAmount),
                  ),
                  totalAmountColor: totalAmountColor,
                ),
                SizedBox(height: context.spacing.space2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _LinkRow(
                    label: 'Voir détail',
                    onTap: onLinkTap,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Stock — Dormant stock (top 3 + "Voir tous (N)")
// ════════════════════════════════════════════════════════════
class _DormantStockCard extends ConsumerWidget {
  const _DormantStockCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final asyncList = ref.watch(deadStockProvider);
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: asyncList.when(
        loading: () => SizedBox(
          height: 200,
          child: _ShimmerBlock(radius: context.radius.radiusInput),
        ),
        error: (_, __) => _CardEmpty(
          icon: Icons.inventory_2_outlined,
          message: 'Impossible de charger le stock dormant',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock dormant',
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space3),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: context.spacing.space4),
                    child: Text(
                      'Aucun produit dormant',
                      style:
                          context.typography.bodyMd.copyWith(color: c.fg3),
                    ),
                  ),
                ),
              ],
            );
          }
          final top = entries.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock dormant',
                style: context.typography.h4.copyWith(color: c.fg1),
              ),
              SizedBox(height: context.spacing.space3),
              for (var i = 0; i < top.length; i++) ...[
                StockDeadStockCard(
                  productName: top[i].productName,
                  unitsLine: '${top[i].units} unités',
                  categoryLine: top[i].category != null
                      ? '${top[i].daysSinceLastSale} j · ${top[i].category}'
                      : '${top[i].daysSinceLastSale} j sans vente',
                  amount: MillimesFormatter.format(top[i].value),
                  thumbnailColor: top[i].thumbnailColor != null
                      ? Color(top[i].thumbnailColor!)
                      : null,
                ),
                if (i < top.length - 1)
                  SizedBox(height: context.spacing.space2),
              ],
              SizedBox(height: context.spacing.space2),
              Align(
                alignment: Alignment.centerLeft,
                child: _LinkRow(
                  label: 'Voir tous (${entries.length})',
                  onTap: () => context.push('/stock/dead'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _showSoonSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Bientôt disponible')),
  );
}

// ════════════════════════════════════════════════════════════
// Tap feedback (TODO(extract))
// ════════════════════════════════════════════════════════════
class _ScaleTap extends StatefulWidget {
  const _ScaleTap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;

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
        scale: _pressed ? 0.98 : 1.0,
        duration: context.motion.tap,
        curve: context.motion.easeOut,
        child: widget.child,
      ),
    );
  }
}
