import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/order_models.dart';
import '../../domain/partial_fulfill_models.dart';
import '../providers/order_provider.dart';
import '../providers/partial_fulfill_provider.dart';

/// Screen 2 of the Partial Fulfillment flow (FLUTTER_SPEC §2.8).
///
/// Displays the same split as Screen 1, plus a date picker for the
/// optional restock estimate. The "Terminer" CTA submits the
/// `SHIP_NOW` action — the actual DB write happens here, not on the
/// previous screen.
///
/// On success:
///   - invalidate order detail + list providers
///   - pop 2 screens (Confirm → Split → OrderDetail)
///   - show snackbar
class PartialFulfillConfirmScreen extends ConsumerStatefulWidget {
  const PartialFulfillConfirmScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.shippedItems,
    required this.backorderedItems,
  });

  final String orderId;
  final String? orderNumber;
  final List<OrderItem> shippedItems;
  final List<OrderItem> backorderedItems;

  @override
  ConsumerState<PartialFulfillConfirmScreen> createState() =>
      _PartialFulfillConfirmScreenState();
}

class _PartialFulfillConfirmScreenState
    extends ConsumerState<PartialFulfillConfirmScreen> {
  DateTime? _restockDate;

  Future<void> _pickRestockDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _restockDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('fr', 'TN'),
    );
    if (picked != null) {
      setState(() => _restockDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    ref.listen<SubmitPartialFulfillState>(submitPartialFulfillProvider,
        (prev, next) {
      if (prev?.status == next.status) return;
      if (next.status == SubmitPartialFulfillStatus.success) {
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        ref.invalidate(orderListProvider);
        ref.invalidate(orderDetailProvider(widget.orderId));

        // Pop 2 screens: Confirm → Split → OrderDetail.
        var popped = 0;
        navigator.popUntil((_) => ++popped > 2);

        final shippedCount = widget.shippedItems.length;
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: c.fg1,
            content: Text(
              shippedCount > 1
                  ? '$shippedCount articles expédiés.'
                  : '$shippedCount article expédié.',
            ),
          ),
        );
      } else if (next.status == SubmitPartialFulfillStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: c.red,
            content: Text(
              next.error ?? 'Échec de l\'expédition partielle. Réessayer.',
            ),
          ),
        );
      }
    });

    final state = ref.watch(submitPartialFulfillProvider);
    final loading = state.status == SubmitPartialFulfillStatus.loading;

    return Scaffold(
      backgroundColor: c.surface1,
      appBar: AppBar(title: const Text('Expédition partielle')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.spacing.space4,
                context.spacing.space3,
                context.spacing.space4,
                context.spacing.space4,
              ),
              children: [
                _SuccessCard(shippedCount: widget.shippedItems.length),
                SizedBox(height: context.spacing.space5),
                if (widget.shippedItems.isNotEmpty) ...[
                  _SectionLabel(text: 'EXPÉDIÉ MAINTENANT'),
                  SizedBox(height: context.spacing.space2),
                  _ItemsCard(
                    items: widget.shippedItems,
                    badgeLabel: null,
                  ),
                  SizedBox(height: context.spacing.space5),
                ],
                if (widget.backorderedItems.isNotEmpty) ...[
                  _SectionLabel(text: 'EN ATTENTE DE RESTOCK'),
                  SizedBox(height: context.spacing.space2),
                  _ItemsCard(
                    items: widget.backorderedItems,
                    badgeLabel: 'En attente',
                  ),
                  SizedBox(height: context.spacing.space5),
                  _RestockDateField(
                    selected: _restockDate,
                    onTap: _pickRestockDate,
                    onClear: _restockDate == null
                        ? null
                        : () => setState(() => _restockDate = null),
                  ),
                ],
              ],
            ),
          ),
          _Footer(
            loading: loading,
            onSubmit: loading
                ? null
                : () =>
                    ref.read(submitPartialFulfillProvider.notifier).submit(
                          orderId: widget.orderId,
                          action: PartialFulfillAction.shipNow,
                          estimatedRestockDate: _restockDate,
                        ),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.shippedCount});
  final int shippedCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.greenFg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.check, size: 28, color: c.surface0),
          ),
          SizedBox(height: context.spacing.space3),
          Text(
            shippedCount > 1
                ? '$shippedCount articles prêts'
                : '$shippedCount article prêt',
            style: context.typography.h3.copyWith(color: c.fg1),
          ),
          SizedBox(height: 2),
          Text(
            'Le bordereau est prêt.',
            style: context.typography.body.copyWith(color: c.fg2),
          ),
          SizedBox(height: context.spacing.space3),
          DidoButton.secondary(
            label: 'Imprimer le bordereau',
            icon: Icons.print_outlined,
            onPressed: () {
              // `printing` package not in pubspec — defer with snackbar
              // so we don't add a dependency without consent.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Impression bientôt disponible.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(left: context.spacing.space2),
      child: Text(text, style: context.typography.label.copyWith(color: c.fg3)),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items, required this.badgeLabel});
  final List<OrderItem> items;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: c.border1.withValues(alpha: 0.5),
              ),
            _Row(item: items[i], badgeLabel: badgeLabel),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.badgeLabel});
  final OrderItem item;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final attrs = item.attributeLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(8),
              image: item.primaryImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(item.primaryImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: item.primaryImageUrl == null
                ? Icon(Icons.inventory_2_outlined, size: 18, color: c.fg3)
                : null,
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: context.typography.bodyMd.copyWith(color: c.fg1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  attrs.isEmpty
                      ? 'Qté ${item.quantity}'
                      : '$attrs · Qté ${item.quantity}',
                  style: context.typography.bodySmall.copyWith(color: c.fg2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badgeLabel != null) ...[
            SizedBox(width: context.spacing.space2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(context.radius.radiusChip),
              ),
              child: Text(
                badgeLabel!,
                style: context.typography.label.copyWith(color: c.fg2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestockDateField extends StatelessWidget {
  const _RestockDateField({
    required this.selected,
    required this.onTap,
    required this.onClear,
  });
  final DateTime? selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: context.spacing.space2),
          child: Text(
            'Restock estimé · optionnel',
            style: context.typography.label.copyWith(color: c.fg3),
          ),
        ),
        SizedBox(height: context.spacing.space2),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface0,
              border: Border.all(color: c.border1),
              borderRadius: BorderRadius.circular(context.radius.radiusCard),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: c.fg2),
                SizedBox(width: context.spacing.space3),
                Expanded(
                  child: Text(
                    selected == null
                        ? 'Choisir une date'
                        : _formatDate(selected!),
                    style: context.typography.body.copyWith(
                      color: selected == null ? c.fg3 : c.fg1,
                    ),
                  ),
                ),
                if (onClear != null)
                  InkWell(
                    onTap: onClear,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: c.fg3),
                    ),
                  )
                else
                  Icon(Icons.keyboard_arrow_down, size: 18, color: c.fg2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.loading, required this.onSubmit});
  final bool loading;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.spacing.space4,
          context.spacing.space3,
          context.spacing.space4,
          context.spacing.space4,
        ),
        decoration: BoxDecoration(
          color: c.surface0,
          border: Border(top: BorderSide(color: c.border1)),
        ),
        child: DidoButton.primary(
          label: 'Terminer',
          loading: loading,
          enabled: onSubmit != null,
          onPressed: onSubmit,
        ),
      ),
    );
  }
}
