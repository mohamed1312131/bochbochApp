import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_filter_chip.dart';
import '../../../stock/domain/stock_enums.dart';
import '../../../stock/domain/stock_models.dart';
import '../../../stock/domain/stock_movement.dart';
import '../../../stock/presentation/providers/stock_provider.dart';
import '../../../stock/presentation/widgets/stock_history_row.dart';
import '../../domain/product_models.dart';

/// Historique tab body for the product detail screen — FLUTTER_SPEC §7.6.
class ProductHistoryTab extends ConsumerStatefulWidget {
  const ProductHistoryTab({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductHistoryTab> createState() =>
      _ProductHistoryTabState();
}

class _ProductHistoryTabState extends ConsumerState<ProductHistoryTab> {
  StockMovementType? _filterType;
  StockAdjustmentReason? _filterReason;
  DateTimeRange? _filterDateRange;

  StockHistoryFilter get _filter => StockHistoryFilter(
        types: _filterType == null ? null : [_filterType!],
        reasons: _filterReason == null ? null : [_filterReason!],
        fromDate: _filterDateRange?.start,
        toDate: _filterDateRange?.end,
      );

  Future<void> _showTypePicker() async {
    final picked = await showDidoBottomSheet<_TypeChoice>(
      context: context,
      title: 'Type de mouvement',
      child: _PickerList<_TypeChoice>(
        items: [
          const _TypeChoice(label: 'Tout'),
          ...StockMovementType.values
              .map((t) => _TypeChoice(label: t.displayLabel, type: t)),
        ],
        labelOf: (c) => c.label,
      ),
    );
    if (picked != null) {
      setState(() => _filterType = picked.type);
    }
  }

  Future<void> _showReasonPicker() async {
    final picked = await showDidoBottomSheet<_ReasonChoice>(
      context: context,
      title: 'Raison',
      child: _PickerList<_ReasonChoice>(
        items: [
          const _ReasonChoice(label: 'Toutes raisons'),
          ...StockAdjustmentReason.values
              .map((r) => _ReasonChoice(label: r.label, reason: r)),
        ],
        labelOf: (c) => c.label,
      ),
    );
    if (picked != null) {
      setState(() => _filterReason = picked.reason);
    }
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initial = _filterDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() => _filterDateRange = picked);
    }
  }

  void _showCsvSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bientôt disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final variants =
        widget.product.variants.where((v) => v.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DidoFilterChip(
                  label: _filterType == null
                      ? 'Tout'
                      : _filterType!.displayLabel,
                  selected: _filterType != null,
                  showChevron: true,
                  onTap: _filterType != null
                      ? () => setState(() => _filterType = null)
                      : _showTypePicker,
                ),
                const SizedBox(width: 8),
                DidoFilterChip(
                  label: _filterReason == null
                      ? 'Toutes raisons'
                      : _filterReason!.label,
                  selected: _filterReason != null,
                  showChevron: true,
                  onTap: _filterReason != null
                      ? () => setState(() => _filterReason = null)
                      : _showReasonPicker,
                ),
                const SizedBox(width: 8),
                DidoFilterChip(
                  label: _filterDateRange == null
                      ? 'Cette semaine'
                      : 'Personnalisé',
                  selected: _filterDateRange != null,
                  showChevron: true,
                  onTap: _filterDateRange != null
                      ? () => setState(() => _filterDateRange = null)
                      : _showDateRangePicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final variant in variants) ...[
            if (variants.length > 1) ...[
              Text(
                (variant.isSimple ? 'Standard' : variant.attributeLabel)
                    .toUpperCase(),
                style: context.typography.label.copyWith(color: c.fg3),
              ),
              const SizedBox(height: 8),
            ],
            _VariantHistorySection(
              variantId: variant.id,
              filter: _filter,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _showCsvSnack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_outlined, size: 16, color: c.fg1),
                  const SizedBox(width: 6),
                  Text(
                    'Exporter en CSV',
                    style: context.typography.smallMd.copyWith(color: c.fg1),
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

class _VariantHistorySection extends ConsumerWidget {
  const _VariantHistorySection({
    required this.variantId,
    required this.filter,
  });

  final String variantId;
  final StockHistoryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final query = MovementsQuery(variantId: variantId, filter: filter);
    final movementsAsync = ref.watch(stockMovementsProvider(query));

    return movementsAsync.when(
      loading: () => Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius:
                    BorderRadius.circular(context.radius.radiusCard),
              ),
            ),
            if (i < 2) const SizedBox(height: 8),
          ],
        ],
      ),
      error: (_, __) => Text(
        'Erreur',
        style: context.typography.bodyMd.copyWith(color: c.redFg),
      ),
      data: (page) {
        final movements = page.data;
        if (movements.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Aucun mouvement de stock pour cette variante',
                textAlign: TextAlign.center,
                style: context.typography.body.copyWith(color: c.fg3),
              ),
            ),
          );
        }
        final buckets = _groupByDate(movements);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in buckets.entries) ...[
              Text(
                entry.key,
                style: context.typography.label.copyWith(color: c.fg3),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: c.border1, width: 1),
                  borderRadius:
                      BorderRadius.circular(context.radius.radiusCard),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++)
                      StockHistoryRow(
                        kind: _toRowKind(entry.value[i].type.displayKind),
                        label: entry.value[i].type.displayLabel,
                        delta: entry.value[i].qtyDelta,
                        subtitle: entry.value[i].displaySubtitle(),
                        quantityBefore: entry.value[i].qtyBefore,
                        quantityAfter: entry.value[i].qtyAfter,
                        hasPhoto: entry.value[i].photoUrl != null,
                        showBottomBorder: i != entry.value.length - 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

StockHistoryKind _toRowKind(StockHistoryDisplayKind k) => switch (k) {
      StockHistoryDisplayKind.sold => StockHistoryKind.sold,
      StockHistoryDisplayKind.restock => StockHistoryKind.restock,
      StockHistoryDisplayKind.broken => StockHistoryKind.broken,
      StockHistoryDisplayKind.gift => StockHistoryKind.gift,
    };

Map<String, List<StockMovement>> _groupByDate(List<StockMovement> movements) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));
  final buckets = <String, List<StockMovement>>{};
  for (final m in movements) {
    final mDate =
        DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
    String key;
    if (mDate.isAtSameMomentAs(today)) {
      key = "AUJOURD'HUI";
    } else if (mDate.isAtSameMomentAs(yesterday)) {
      key = 'HIER';
    } else if (mDate.isAfter(weekAgo)) {
      key = 'DERNIERS 7 JOURS';
    } else {
      key = 'PLUS ANCIEN';
    }
    buckets.putIfAbsent(key, () => []).add(m);
  }
  return buckets;
}

// ── Picker plumbing ───────────────────────────────────────────
class _TypeChoice {
  const _TypeChoice({required this.label, this.type});
  final String label;
  final StockMovementType? type;
}

class _ReasonChoice {
  const _ReasonChoice({required this.label, this.reason});
  final String label;
  final StockAdjustmentReason? reason;
}

class _PickerList<T> extends StatelessWidget {
  const _PickerList({required this.items, required this.labelOf});

  final List<T> items;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Container(height: 1, color: c.border1),
        itemBuilder: (_, i) {
          final item = items[i];
          return InkWell(
            onTap: () => Navigator.of(context).pop(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: Text(
                labelOf(item),
                style: context.typography.body.copyWith(color: c.fg1),
              ),
            ),
          );
        },
      ),
    );
  }
}
