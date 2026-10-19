import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/exchange_models.dart';
import '../providers/exchange_provider.dart';
import '../providers/order_provider.dart';

/// Screen 3 of the exchange flow — review + submit.
///
/// On success: invalidates the order list + detail providers so the
/// new EXCHANGE_IN_PROGRESS status surfaces, pops the 3 exchange
/// screens off the stack, and surfaces a snackbar (with a stock
/// warning if the target variant was out of stock).
class ExchangeConfirmScreen extends ConsumerStatefulWidget {
  const ExchangeConfirmScreen({
    super.key,
    required this.draft,
    required this.costsSkipped,
  });

  final ExchangeDraft draft;
  final bool costsSkipped;

  @override
  ConsumerState<ExchangeConfirmScreen> createState() =>
      _ExchangeConfirmScreenState();
}

class _ExchangeConfirmScreenState
    extends ConsumerState<ExchangeConfirmScreen> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // React to submit lifecycle.
    ref.listen<SubmitExchangeState>(submitExchangeProvider, (prev, next) {
      if (prev?.status == next.status) return;
      if (next.status == SubmitExchangeStatus.success) {
        final orderId = widget.draft.orderId;
        final stockWarning = next.createdResult?.stockWarning ?? false;
        // Capture before pop — the BuildContext is removed mid-flow.
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        // Refresh the visible order + the order list.
        ref.invalidate(orderListProvider);
        ref.invalidate(orderDetailProvider(orderId));

        // Pop the 3 exchange screens (Confirm → Costs → Pick) so the
        // user lands back on the OrderDetailScreen below them.
        var popped = 0;
        navigator.popUntil((_) => ++popped > 3);

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: stockWarning ? c.coralFg : c.fg1,
            content: Text(
              stockWarning
                  ? 'Échange enregistré — attention, le nouvel article est en rupture de stock.'
                  : 'Échange enregistré',
            ),
          ),
        );
      } else if (next.status == SubmitExchangeStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: c.red,
            content: Text(next.error ?? 'Échec de l\'échange. Réessayer.'),
          ),
        );
      }
    });

    final state = ref.watch(submitExchangeProvider);
    final loading = state.status == SubmitExchangeStatus.loading;

    return Scaffold(
      backgroundColor: c.surface1,
      appBar: AppBar(title: const Text('Confirmer l\'échange')),
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
                _SwapCard(draft: widget.draft),
                SizedBox(height: context.spacing.space4),
                Padding(
                  padding: EdgeInsets.only(left: context.spacing.space2),
                  child: Text(
                    'FRAIS ENREGISTRÉS',
                    style: context.typography.label.copyWith(color: c.fg3),
                  ),
                ),
                SizedBox(height: context.spacing.space2),
                widget.costsSkipped
                    ? _NoCostsBox()
                    : _CostsCard(draft: widget.draft),
                SizedBox(height: context.spacing.space4),
                _StatusInfoStrip(orderNumber: widget.draft.orderNumber),
              ],
            ),
          ),
          _Footer(
            loading: loading,
            onSubmit: () =>
                ref.read(submitExchangeProvider.notifier).submit(widget.draft),
          ),
        ],
      ),
    );
  }
}

// ── Swap card ─────────────────────────────────────────────
class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.draft});
  final ExchangeDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final original = draft.original;
    final target = draft.target!;

    return Container(
      padding: EdgeInsets.all(context.spacing.space3),
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÉCHANGE',
            style: context.typography.label.copyWith(color: c.fg3),
          ),
          SizedBox(height: context.spacing.space2),
          if (original != null) ...[
            _SwapRow(
              icon: Icons.swap_horiz_rounded,
              name: original.productName,
              meta: [
                if (original.attributesLabel.isNotEmpty)
                  original.attributesLabel,
                MillimesFormatter.format(original.unitPrice),
              ].join(' · '),
              strikethrough: true,
              fadeName: true,
            ),
            SizedBox(height: context.spacing.space2),
            Center(
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: c.fg3,
              ),
            ),
            SizedBox(height: context.spacing.space2),
          ],
          _SwapRow(
            icon: Icons.add_circle_outline_rounded,
            name: target.productName,
            meta: [
              if (target.attributesLabel.isNotEmpty) target.attributesLabel,
              MillimesFormatter.format(target.sellPrice),
              '${target.onHandQuantity} en stock',
            ].join(' · '),
            strikethrough: false,
            fadeName: false,
          ),
        ],
      ),
    );
  }
}

class _SwapRow extends StatelessWidget {
  const _SwapRow({
    required this.icon,
    required this.name,
    required this.meta,
    required this.strikethrough,
    required this.fadeName,
  });

  final IconData icon;
  final String name;
  final String meta;
  final bool strikethrough;
  final bool fadeName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: c.fg3),
        ),
        SizedBox(width: context.spacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: context.typography.bodyMd.copyWith(
                  color: fadeName ? c.fg2 : c.fg1,
                  decoration: strikethrough ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.spacing.space1),
              Text(
                meta,
                style: context.typography.bodySmall.copyWith(color: c.fg3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── No-costs empty state ──────────────────────────────────
class _NoCostsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      alignment: Alignment.center,
      child: Text(
        'Aucun frais enregistré',
        style: context.typography.body.copyWith(color: c.fg3),
      ),
    );
  }
}

// ── Costs card ────────────────────────────────────────────
class _CostsCard extends StatelessWidget {
  const _CostsCard({required this.draft});
  final ExchangeDraft draft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lines = <_CostLine>[
      if (draft.returnShippingCost != null && draft.returnShippingCost != 0)
        _CostLine('Frais de retour', draft.returnShippingCost!),
      if (draft.redeliveryCost != null && draft.redeliveryCost != 0)
        _CostLine('Frais de réexpédition', draft.redeliveryCost!),
      if (draft.priceDifference != null && draft.priceDifference != 0)
        _CostLine('Différence de prix', draft.priceDifference!, signed: true),
    ];
    if (lines.isEmpty) return _NoCostsBox();
    return Container(
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            _CostRow(line: lines[i]),
            if (i < lines.length - 1)
              Container(height: 1, color: c.border1),
          ],
        ],
      ),
    );
  }
}

class _CostLine {
  const _CostLine(this.label, this.millimes, {this.signed = false});
  final String label;
  final int millimes;
  final bool signed;
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.line});
  final _CostLine line;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isNeg = line.millimes < 0;
    final formatted = MillimesFormatter.format(line.millimes.abs());
    final value = line.signed && line.millimes > 0
        ? '+$formatted'
        : isNeg
            ? '−$formatted'
            : formatted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.label,
              style: context.typography.body.copyWith(color: c.fg2),
            ),
          ),
          Text(
            value,
            style: context.typography.bodyMdNum.copyWith(color: c.fg1),
          ),
        ],
      ),
    );
  }
}

// ── Status info strip (teal tint) ─────────────────────────
class _StatusInfoStrip extends StatelessWidget {
  const _StatusInfoStrip({required this.orderNumber});
  final String? orderNumber;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = orderNumber != null ? '#$orderNumber' : '';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.brandTealTint08,
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: c.brandTeal),
          SizedBox(width: context.spacing.space2),
          Expanded(
            child: Text(
              'La commande $label passera en « Échange en cours ».',
              style: context.typography.bodySmall.copyWith(color: c.brandTeal),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({required this.loading, required this.onSubmit});
  final bool loading;
  final VoidCallback onSubmit;
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
          label: 'Confirmer l\'échange',
          onPressed: loading ? null : onSubmit,
          loading: loading,
        ),
      ),
    );
  }
}
