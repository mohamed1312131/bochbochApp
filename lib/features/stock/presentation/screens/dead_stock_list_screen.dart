import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_filter_chip.dart';
import '../widgets/stock_dead_stock_card.dart';
import '../providers/stock_provider.dart';

/// Stock dormant — full list of dormant variants with promo / discount
/// affordances. Filter chips toggle between 60+ and 30+ jours.
class DeadStockListScreen extends ConsumerStatefulWidget {
  const DeadStockListScreen({super.key});

  @override
  ConsumerState<DeadStockListScreen> createState() =>
      _DeadStockListScreenState();
}

class _DeadStockListScreenState extends ConsumerState<DeadStockListScreen> {
  // TODO(stock-backend): replace with deadStockProvider.family({dormantDays})
  // when backend supports a custom dormant-days parameter. For now the
  // mock returns a fixed 60-day cohort.
  int _filterDays = 60;

  void _showSoonSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final asyncList = ref.watch(deadStockProvider);

    return Scaffold(
      backgroundColor: c.surface0,
      appBar: AppBar(
        title: Text(
          'Stock dormant',
          style: context.typography.h3.copyWith(color: c.fg1),
        ),
        backgroundColor: c.surface0,
        foregroundColor: c.fg1,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  DidoFilterChip(
                    label: '60+ jours',
                    selected: _filterDays == 60,
                    onTap: () => setState(() => _filterDays = 60),
                  ),
                  const SizedBox(width: 8),
                  DidoFilterChip(
                    label: '30+ jours',
                    selected: _filterDays == 30,
                    onTap: () => setState(() => _filterDays = 30),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: asyncList.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, __) => Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(
                          context.radius.radiusCard),
                    ),
                  ),
                ),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 48, color: c.fg3),
                        const SizedBox(height: 12),
                        Text(
                          'Impossible de charger',
                          style:
                              context.typography.h4.copyWith(color: c.fg1),
                        ),
                        const SizedBox(height: 16),
                        DidoButton.secondary(
                          label: 'Réessayer',
                          fullWidth: false,
                          onPressed: () =>
                              ref.invalidate(deadStockProvider),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 48, color: c.greenFg),
                            const SizedBox(height: 12),
                            Text(
                              'Pas de stock dormant !',
                              style: context.typography.h4
                                  .copyWith(color: c.fg1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final entry = entries[i];
                      return StockDeadStockCard(
                        productName: entry.productName,
                        unitsLine: '${entry.units} unités',
                        categoryLine: entry.category != null
                            ? '${entry.daysSinceLastSale} j · ${entry.category}'
                            : '${entry.daysSinceLastSale} j sans vente',
                        amount: MillimesFormatter.format(entry.value),
                        thumbnailColor: entry.thumbnailColor != null
                            ? Color(entry.thumbnailColor!)
                            : null,
                        onPromote: () => _showSoonSnack(
                            "Bientôt disponible — l'IA va générer un post promo"),
                        onDiscount: () => _showSoonSnack(
                            'Bientôt disponible — flux de réduction prix'),
                        onTap: () =>
                            context.push('/products/${entry.productId}'),
                      );
                    },
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
