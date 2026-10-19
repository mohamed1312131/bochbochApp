import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../domain/order_models.dart';
import '../../domain/rto_models.dart';
import '../providers/order_provider.dart';
import '../providers/rto_provider.dart';

/// Coral warning banner shown at the top of OrderDetailScreen when
/// the order is in RTO_IN_TRANSIT or RTO_RECEIVED state.
///
/// In RTO_IN_TRANSIT, exposes two actions:
///   - Confirmer réception RTO → POST /:id/rto with status=RTO_RECEIVED
///   - Reprogrammer la livraison → PATCH /:id/status to SHIPPED
///
/// In RTO_RECEIVED, terminal state — banner is informational only.
class RtoSection extends ConsumerWidget {
  const RtoSection({
    super.key,
    required this.order,
    required this.isUpdating,
    required this.onReattemptDelivery,
  });

  final Order order;
  final bool isUpdating;
  final VoidCallback onReattemptDelivery;

  Future<void> _confirmReceived(WidgetRef ref, BuildContext context) async {
    if (order.rtoReason == null) {
      // Defensive — should never happen since IN_TRANSIT was set with a reason.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text('Raison RTO manquante.'),
        ),
      );
      return;
    }
    await ref.read(submitRtoProvider.notifier).submit(
          orderId: order.id,
          reason: RtoReason.fromWire(order.rtoReason!),
          targetStatus: RtoTargetStatus.received,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isInTransit = order.status == 'RTO_IN_TRANSIT';
    final isReceived = order.status == 'RTO_RECEIVED';
    if (!isInTransit && !isReceived) return const SizedBox.shrink();

    final reasonLabel = order.rtoReason != null
        ? RtoReason.fromWire(order.rtoReason!).label
        : '—';

    ref.listen<SubmitRtoState>(submitRtoProvider, (prev, next) {
      if (prev?.status == next.status) return;
      if (next.status == SubmitRtoStatus.success) {
        final r = next.createdResult;
        final messenger = ScaffoldMessenger.of(context);

        ref.invalidate(orderListProvider);
        ref.invalidate(orderDetailProvider(order.id));
        // Refresh customer detail too — codRefusalCount changed.
        if (r?.customer != null) {
          ref.invalidate(customerDetailProvider(r!.customer!.id));
        }

        final restored = r?.stockRestored.length ?? 0;
        final autoDisabled = r?.customer?.autoDisabledNow ?? false;
        final parts = <String>['RTO confirmé.'];
        if (restored > 0) {
          parts.add(
            '$restored article${restored > 1 ? "s" : ""} remis en stock.',
          );
        }
        if (autoDisabled) {
          parts.add('COD désactivé pour ce client (3 refus).');
        }
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: autoDisabled ? c.coralFg : c.fg1,
            content: Text(parts.join(' ')),
          ),
        );
      } else if (next.status == SubmitRtoStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: c.red,
            content: Text(next.error ?? 'Échec de la confirmation RTO.'),
          ),
        );
      }
    });

    final submitState = ref.watch(submitRtoProvider);
    final loading = submitState.status == SubmitRtoStatus.loading;
    final disabled = isUpdating || loading;

    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.coralTint12,
        border: Border(
          left: BorderSide(color: c.coral, width: 3),
        ),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.coral,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.assignment_return_outlined,
                    size: 18, color: c.surface0),
              ),
              SizedBox(width: context.spacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInTransit ? 'RTO en transit' : 'RTO reçu',
                      style:
                          context.typography.h4.copyWith(color: c.coralFg),
                    ),
                    SizedBox(height: 2),
                    Text(
                      isReceived && order.rtoReceivedAt != null
                          ? '$reasonLabel · Reçu le ${DateFormatter.short(order.rtoReceivedAt!)}'
                          : reasonLabel,
                      style: context.typography.bodySmall.copyWith(
                        color: c.coralFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isInTransit) ...[
            SizedBox(height: context.spacing.space4),
            DidoButton.primary(
              label: 'Confirmer réception RTO',
              icon: Icons.inventory_2_outlined,
              loading: loading,
              enabled: !disabled,
              onPressed: disabled ? null : () => _confirmReceived(ref, context),
            ),
            SizedBox(height: context.spacing.space2),
            DidoButton.secondary(
              label: 'Reprogrammer la livraison',
              icon: Icons.replay_rounded,
              enabled: !disabled,
              onPressed: disabled ? null : onReattemptDelivery,
            ),
          ],
          // COD refusal count — fetched from the customer profile if
          // available. Skipped silently if the order has no linked
          // customer (rare but possible for manual orders).
          _CodRefusalCountLine(customerId: order.customer.id),
        ],
      ),
    );
  }
}

class _CodRefusalCountLine extends ConsumerWidget {
  const _CodRefusalCountLine({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final asyncCustomer = ref.watch(customerDetailProvider(customerId));
    return asyncCustomer.maybeWhen(
      data: (customer) {
        final n = customer.codRefusalCount;
        if (n <= 0) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: context.spacing.space3),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: c.coralFg),
              SizedBox(width: context.spacing.space2),
              Text(
                '${n}e refus COD de ce client',
                style:
                    context.typography.bodySmall.copyWith(color: c.coralFg),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Bottom sheet to pick an RTO reason and start the IN_TRANSIT flow.
/// Returns the selected [RtoReason] on confirm, or null on dismiss.
Future<RtoReason?> showRtoReasonPickerSheet(BuildContext context) {
  return showModalBottomSheet<RtoReason>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const _RtoReasonPickerSheet(),
  );
}

class _RtoReasonPickerSheet extends StatefulWidget {
  const _RtoReasonPickerSheet();

  @override
  State<_RtoReasonPickerSheet> createState() => _RtoReasonPickerSheetState();
}

class _RtoReasonPickerSheetState extends State<_RtoReasonPickerSheet> {
  RtoReason? _selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: c.surface0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(
          context.spacing.space4,
          context.spacing.space2,
          context.spacing.space4,
          context.spacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: c.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Marquer RTO en transit',
                style: context.typography.h3.copyWith(color: c.fg1),
              ),
            ),
            SizedBox(height: context.spacing.space2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pourquoi le colis revient ?',
                style: context.typography.body.copyWith(color: c.fg2),
              ),
            ),
            SizedBox(height: context.spacing.space4),
            for (final r in RtoReason.values) ...[
              _ReasonRow(
                reason: r,
                selected: _selected == r,
                onTap: () => setState(() => _selected = r),
              ),
              if (r != RtoReason.values.last)
                SizedBox(height: context.spacing.space2),
            ],
            SizedBox(height: context.spacing.space5),
            DidoButton.primary(
              label: 'Marquer RTO en transit',
              enabled: _selected != null,
              onPressed:
                  _selected == null ? null : () => Navigator.pop(context, _selected),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });
  final RtoReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? c.brandTealTint08 : c.surface0,
          border: Border.all(
            color: selected ? c.brandTeal : c.border1,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason.label,
                style: context.typography.bodyMd.copyWith(color: c.fg1),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: c.surface0,
                border: Border.all(
                  color: selected ? c.brandTeal : c.border2,
                  width: selected ? 1.5 : 1,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.brandTeal,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
