import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/issue_models.dart';
import '../providers/issue_provider.dart';
import '../providers/order_provider.dart';

/// Screen 2 of the Lost/Damaged flow — pick a resolution and submit.
///
/// On success:
///   - invalidate the order detail + list providers (status flip surfaces)
///   - pop the 2 issue screens (Resolution → Type → OrderDetail)
///   - show snackbar with restored-item count
class DeliveryResolutionScreen extends ConsumerStatefulWidget {
  const DeliveryResolutionScreen({super.key, required this.draft});
  final IssueDraft draft;

  @override
  ConsumerState<DeliveryResolutionScreen> createState() =>
      _DeliveryResolutionScreenState();
}

class _DeliveryResolutionScreenState
    extends ConsumerState<DeliveryResolutionScreen> {
  late IssueDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
  }

  void _select(IssueResolution r) {
    setState(() => _draft = _draft.copyWith(resolution: r));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final orderLabel = _draft.orderNumber ?? _draft.orderId;
    final canSubmit = _draft.resolution != null;

    ref.listen<SubmitIssueState>(submitIssueProvider, (prev, next) {
      if (prev?.status == next.status) return;
      if (next.status == SubmitIssueStatus.success) {
        final restoredCount = next.createdResult?.stockRestored.length ?? 0;
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        ref.invalidate(orderListProvider);
        ref.invalidate(orderDetailProvider(_draft.orderId));

        // Pop 2 screens: Resolution + Type → back to OrderDetail.
        var popped = 0;
        navigator.popUntil((_) => ++popped > 2);

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: c.fg1,
            content: Text(
              restoredCount > 0
                  ? 'Réclamation enregistrée — $restoredCount article${restoredCount > 1 ? "s" : ""} remis en stock.'
                  : 'Réclamation enregistrée.',
            ),
          ),
        );
      } else if (next.status == SubmitIssueStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: c.red,
            content: Text(
              next.error ?? 'Échec de la réclamation. Réessayer.',
            ),
          ),
        );
      }
    });

    final state = ref.watch(submitIssueProvider);
    final loading = state.status == SubmitIssueStatus.loading;

    return Scaffold(
      backgroundColor: c.surface1,
      appBar: AppBar(title: const Text('Résolution')),
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
                _IssueSummaryStrip(
                  type: _draft.issueType!,
                  orderLabel: orderLabel,
                ),
                SizedBox(height: context.spacing.space4),
                _StockRestoredBanner(lines: _draft.expectedStockRestore),
                SizedBox(height: context.spacing.space5),
                Padding(
                  padding: EdgeInsets.only(left: context.spacing.space2),
                  child: Text(
                    'CHOISIR LA RÉSOLUTION',
                    style: context.typography.label.copyWith(color: c.fg3),
                  ),
                ),
                SizedBox(height: context.spacing.space2),
                _ResolutionCard(
                  resolution: IssueResolution.resend,
                  icon: Icons.refresh_rounded,
                  description:
                      'Préparer un nouveau colis avec les mêmes articles.',
                  selected: _draft.resolution == IssueResolution.resend,
                  onTap: () => _select(IssueResolution.resend),
                ),
                SizedBox(height: context.spacing.space3),
                _ResolutionCard(
                  resolution: IssueResolution.refund,
                  icon: Icons.payments_outlined,
                  description:
                      'Remboursement intégral par virement ou crédit COD.',
                  selected: _draft.resolution == IssueResolution.refund,
                  onTap: () => _select(IssueResolution.refund),
                ),
                SizedBox(height: context.spacing.space3),
                _ResolutionCard(
                  resolution: IssueResolution.storeCredit,
                  icon: Icons.account_balance_wallet_outlined,
                  description:
                      'Crédit utilisable sur sa prochaine commande.',
                  selected: _draft.resolution == IssueResolution.storeCredit,
                  onTap: () => _select(IssueResolution.storeCredit),
                ),
              ],
            ),
          ),
          _Footer(
            loading: loading,
            canSubmit: canSubmit,
            onSubmit: () =>
                ref.read(submitIssueProvider.notifier).submit(_draft),
          ),
        ],
      ),
    );
  }
}

// ── Issue summary strip ───────────────────────────────────
class _IssueSummaryStrip extends StatelessWidget {
  const _IssueSummaryStrip({
    required this.type,
    required this.orderLabel,
  });
  final IssueType type;
  final String orderLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: c.coralTint12,
        border: Border(
          left: BorderSide(color: c.coral, width: 3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, size: 18, color: c.coralFg),
          SizedBox(width: context.spacing.space2),
          Expanded(
            child: Text(
              '${type.label} · Commande #$orderLabel',
              style:
                  context.typography.bodyMd.copyWith(color: c.coralFg),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stock restored banner ─────────────────────────────────
class _StockRestoredBanner extends StatelessWidget {
  const _StockRestoredBanner({required this.lines});
  final List<ExpectedRestoreLine> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space3),
      decoration: BoxDecoration(
        color: c.greenTint12,
        border: Border.all(color: c.greenFg),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c.greenFg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.check, size: 16, color: c.surface0),
              ),
              SizedBox(width: context.spacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Le stock sera mis à jour',
                      style: context.typography.h4.copyWith(color: c.greenFg),
                    ),
                    SizedBox(height: 2),
                    Text(
                      lines.isEmpty
                          ? 'Aucun article à remettre en stock'
                          : 'Articles remis en stock automatiquement',
                      style: context.typography.caption
                          .copyWith(color: c.greenFg),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            SizedBox(height: context.spacing.space3),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: c.surface0.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < lines.length; i++) ...[
                    if (i > 0)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: c.greenFg.withValues(alpha: 0.15),
                      ),
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.inventory_2_outlined,
                              size: 14, color: c.fg2),
                        ),
                        SizedBox(width: context.spacing.space2),
                        Expanded(
                          child: Text(
                            lines[i].productName,
                            style: context.typography.bodySmall
                                .copyWith(color: c.fg1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '+${lines[i].quantity}',
                          style: context.typography.bodyMdNum
                              .copyWith(color: c.greenFg),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Resolution card ───────────────────────────────────────
class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({
    required this.resolution,
    required this.icon,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IssueResolution resolution;
  final IconData icon;
  final String description;
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
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: c.fg1),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolution.label,
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  SizedBox(height: context.spacing.space1),
                  Text(
                    description,
                    style:
                        context.typography.bodySmall.copyWith(color: c.fg3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({
    required this.loading,
    required this.canSubmit,
    required this.onSubmit,
  });
  final bool loading;
  final bool canSubmit;
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
          label: 'Confirmer la résolution',
          loading: loading,
          enabled: canSubmit && !loading,
          onPressed: canSubmit && !loading ? onSubmit : null,
        ),
      ),
    );
  }
}

