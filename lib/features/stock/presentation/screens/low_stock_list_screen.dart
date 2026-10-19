import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/french_plural.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';
import '../../domain/stock_models.dart';
import '../providers/stock_provider.dart';
import '../sheets/restock_sheet.dart';

/// Stock faible — list of variants whose available stock is at or
/// below the boutique low-stock threshold.
class LowStockListScreen extends ConsumerWidget {
  const LowStockListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final asyncList = ref.watch(lowStockProvider);

    return Scaffold(
      backgroundColor: c.surface0,
      appBar: AppBar(
        title: Text(
          'Stock faible',
          style: context.typography.h3.copyWith(color: c.fg1),
        ),
        backgroundColor: c.surface0,
        foregroundColor: c.fg1,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: c.fg1,
          onRefresh: () async => ref.invalidate(lowStockProvider),
          child: asyncList.when(
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, __) => Container(
                height: 64,
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius:
                      BorderRadius.circular(context.radius.radiusCard),
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
                      onPressed: () => ref.invalidate(lowStockProvider),
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
                          "Tu n'as pas de stock faible !",
                          style: context.typography.h4
                              .copyWith(color: c.fg1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tous tes variants sont au-dessus du seuil.',
                          textAlign: TextAlign.center,
                          style: context.typography.body
                              .copyWith(color: c.fg3),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _LowStockCard(entry: entries[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.entry});

  final LowStockEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: () => context.push('/products/${entry.productId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1, width: 1),
          borderRadius:
              BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: entry.thumbnailColor != null
                        ? Color(entry.thumbnailColor!)
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
                        entry.productName,
                        style: context.typography.bodyMd
                            .copyWith(color: c.fg1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.variantLabel} · ${entry.sku}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.caption
                            .copyWith(color: c.fg3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${frenchPlural(entry.currentAvailable, 'disponible', 'disponibles')} · '
                        'seuil ${entry.threshold}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typography.bodySmall
                            .copyWith(color: c.coralFg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DidoButton.secondary(
              label: 'Restocker',
              fullWidth: true,
              onPressed: () => showRestockSheet(
                context: context,
                variantId: entry.variantId,
                productName: entry.productName,
                variantSubtitle:
                    '${entry.variantLabel} · Stock actuel : '
                    '${entry.currentAvailable}',
                currentStock: entry.currentAvailable,
                currentWacMillimes: entry.currentWacMillimes ?? 0,
                thumbnailColor: entry.thumbnailColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
