import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/french_plural.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_tab_strip.dart';
import '../../domain/stock_models.dart';
import '../widgets/stock_sortie_pertes_card.dart';
import '../providers/stock_provider.dart';

/// Pertes & sorties — full breakdown screen with two tabs.
/// `initialTab` 0 = Pertes (red total), 1 = Sortie hors-vente.
class ShrinkageScreen extends ConsumerStatefulWidget {
  const ShrinkageScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<ShrinkageScreen> createState() => _ShrinkageScreenState();
}

class _ShrinkageScreenState extends ConsumerState<ShrinkageScreen> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);
  }

  void _showCsvSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bientôt disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface0,
      appBar: AppBar(
        title: Text(
          'Pertes & sorties',
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: DidoTabStrip(
                tabs: const ['Pertes', 'Sortie hors-vente'],
                activeIndex: _activeTab,
                onTabTap: (i) => setState(() => _activeTab = i),
              ),
            ),
            Expanded(
              child: _activeTab == 0
                  ? _PertesTab(onCsv: _showCsvSnack)
                  : _SortieTab(onCsv: _showCsvSnack),
            ),
          ],
        ),
      ),
    );
  }
}

class _PertesTab extends ConsumerWidget {
  const _PertesTab({required this.onCsv});
  final VoidCallback onCsv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final asyncBreakdown = ref.watch(shrinkageProvider);
    return asyncBreakdown.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Erreur. Réessaye.',
          style: context.typography.bodyMd.copyWith(color: c.redFg),
        ),
      ),
      data: (b) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StockSortiePertesCard(
              rows: [
                for (final r in b.byReason)
                  StockBreakdownRow(
                    label: r.reasonLabel,
                    count: frenchPlural(r.units, 'unité', 'unités'),
                    amount: MillimesFormatter.format(r.amount),
                  ),
              ],
              total: StockBreakdownRow(
                label: 'Total',
                count: '${b.totalUnits} unités',
                amount: MillimesFormatter.format(b.totalAmount),
              ),
              totalAmountColor: c.redFg,
            ),
            const SizedBox(height: 24),
            Text(
              'TOP PRODUITS PERDUS',
              style: context.typography.label.copyWith(color: c.fg3),
            ),
            const SizedBox(height: 8),
            if (b.byProduct.isEmpty)
              _EmptyByProduct(message: 'Aucun produit pour cette période')
            else
              _ByProductList(items: b.byProduct, amountColor: c.redFg),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: onCsv,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_outlined, size: 16, color: c.fg1),
                    const SizedBox(width: 6),
                    Text(
                      'Exporter en CSV',
                      style:
                          context.typography.smallMd.copyWith(color: c.fg1),
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

class _SortieTab extends ConsumerWidget {
  const _SortieTab({required this.onCsv});
  final VoidCallback onCsv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final asyncBreakdown = ref.watch(offSaleOutflowProvider);
    return asyncBreakdown.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Erreur. Réessaye.',
          style: context.typography.bodyMd.copyWith(color: c.redFg),
        ),
      ),
      data: (b) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StockSortiePertesCard(
              rows: [
                for (final r in b.byReason)
                  StockBreakdownRow(
                    label: r.reasonLabel,
                    count: frenchPlural(r.units, 'unité', 'unités'),
                    amount: MillimesFormatter.format(r.amount),
                  ),
              ],
              total: StockBreakdownRow(
                label: 'Total',
                count: '${b.totalUnits} unités',
                amount: MillimesFormatter.format(b.totalAmount),
              ),
              totalAmountColor: c.fg1,
            ),
            const SizedBox(height: 24),
            Text(
              'TOP PRODUITS OFFERTS / ÉCHANTILLONNÉS',
              style: context.typography.label.copyWith(color: c.fg3),
            ),
            const SizedBox(height: 8),
            if (b.byProduct.isEmpty)
              _EmptyByProduct(message: 'Aucun produit pour cette période')
            else
              _ByProductList(items: b.byProduct, amountColor: c.fg1),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: onCsv,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_outlined, size: 16, color: c.fg1),
                    const SizedBox(width: 6),
                    Text(
                      'Exporter en CSV',
                      style:
                          context.typography.smallMd.copyWith(color: c.fg1),
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

class _ByProductList extends StatelessWidget {
  const _ByProductList({required this.items, required this.amountColor});

  final List<StockBreakdownByProduct> items;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1, width: 1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: items[i].thumbnailColor != null
                          ? Color(items[i].thumbnailColor!)
                          : c.surface3,
                      borderRadius: BorderRadius.circular(
                          context.radius.radiusTile),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typography.bodyMd
                              .copyWith(color: c.fg1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].reasonLabel,
                          style: context.typography.caption
                              .copyWith(color: c.fg3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    MillimesFormatter.format(items[i].amount),
                    style: context.typography.bodyMdNum
                        .copyWith(color: amountColor),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              Container(height: 1, color: c.border1),
          ],
        ],
      ),
    );
  }
}

class _EmptyByProduct extends StatelessWidget {
  const _EmptyByProduct({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: context.typography.body.copyWith(color: c.fg3),
        ),
      ),
    );
  }
}
