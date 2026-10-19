import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_state_row.dart';

/// Stock state sheet — FLUTTER_SPEC §7.3.
///
/// Read-only inspector of a variant's `onHand / available / committed
/// / backordered` breakdown.
Future<void> showStockStateSheet({
  required BuildContext context,
  required String variantId,
  required String productName,
  required String variantLabel,
}) {
  return showDidoBottomSheet<void>(
    context: context,
    title: 'État du stock — $productName $variantLabel',
    child: _StockStateSheetBody(variantId: variantId),
  );
}

class _StockStateSheetBody extends ConsumerWidget {
  const _StockStateSheetBody({required this.variantId});

  final String variantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final stateAsync = ref.watch(stockStateProvider(variantId));

    return stateAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Erreur. Réessaye.',
          style: context.typography.bodyMd.copyWith(color: c.redFg),
        ),
      ),
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StockStateRow(
            label: 'EN STOCK PHYSIQUE',
            quantity: state.onHand,
            kind: StockStateKind.neutral,
            description: 'Ce que tu as physiquement chez toi',
          ),
          StockStateRow(
            label: 'DISPONIBLE',
            quantity: state.available,
            kind: StockStateKind.available,
            description: 'Vendable maintenant',
          ),
          StockStateRow(
            label: 'RÉSERVÉ AUX COMMANDES',
            quantity: state.committed,
            kind: StockStateKind.reserved,
            description: 'Promis à des clients',
            subItems: state.committedOrders.isEmpty
                ? null
                : state.committedOrders
                    .map((o) =>
                        '${o.orderNumber} — ${o.customerName} (${o.qty})')
                    .toList(),
          ),
          StockStateRow(
            label: 'BACKORDER',
            quantity: state.backordered,
            kind: StockStateKind.backorder,
            description: 'Promis mais pas en stock',
            showBottomBorder: false,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: context.typography.button.copyWith(color: c.fg1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
