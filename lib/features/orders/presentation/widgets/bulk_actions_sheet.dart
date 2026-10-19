import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../providers/bulk_actions_provider.dart';
import '../providers/order_provider.dart';

/// FLUTTER_SPEC §3.10 / NEW_FEATURES_SPEC §1.7 — bulk-action chooser
/// for the multi-select mode on the order list.
///
/// Returns `true` from the sheet when the action succeeded and the
/// caller should exit multi-select mode + clear the selection.
Future<bool> showBulkActionsSheet({
  required BuildContext context,
  required List<String> orderIds,
}) async {
  final ok = await showDidoBottomSheet<bool>(
    context: context,
    title: '${orderIds.length} commande${orderIds.length > 1 ? 's' : ''} sélectionnée${orderIds.length > 1 ? 's' : ''}',
    child: _BulkActionsBody(orderIds: orderIds),
  );
  return ok ?? false;
}

class _BulkActionsBody extends ConsumerStatefulWidget {
  const _BulkActionsBody({required this.orderIds});
  final List<String> orderIds;

  @override
  ConsumerState<_BulkActionsBody> createState() => _BulkActionsBodyState();
}

class _BulkActionsBodyState extends ConsumerState<_BulkActionsBody> {
  bool _busy = false;

  Future<void> _runShipNow() async {
    await _runAction(
      () => ref
          .read(bulkActionsProvider.notifier)
          .bulkUpdateStatus(
            orderIds: widget.orderIds,
            newStatus: 'SHIPPED',
          ),
      successLabel:
          'commande${widget.orderIds.length > 1 ? 's' : ''} expédiée${widget.orderIds.length > 1 ? 's' : ''}',
    );
  }

  Future<void> _runCancel() async {
    final c = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler les commandes ?'),
        content: Text(
          '${widget.orderIds.length} commande${widget.orderIds.length > 1 ? 's' : ''} '
          'sera${widget.orderIds.length > 1 ? 'ient' : ''} annulée${widget.orderIds.length > 1 ? 's' : ''} '
          'et le stock sera réapprovisionné.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Annuler + réapprovisionner',
              style: TextStyle(
                color: c.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _runAction(
      () => ref.read(bulkActionsProvider.notifier).bulkCancel(
            orderIds: widget.orderIds,
          ),
      successLabel: 'commande${widget.orderIds.length > 1 ? 's' : ''} annulée${widget.orderIds.length > 1 ? 's' : ''}',
    );
  }

  Future<void> _runAction(
    Future<dynamic> Function() op, {
    required String successLabel,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await op();
      if (result == null) {
        // Provider already set the error state — read it and surface.
        final err = ref.read(bulkActionsProvider).error;
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: context.colors.red,
            content: Text(err ?? "L'opération groupée a échoué."),
          ),
        );
        return;
      }
      // Refresh the order list so flags / statuses update immediately.
      ref.read(orderListProvider.notifier).refresh();
      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: context.colors.fg1,
          content: Text(
            '${result.updated} $successLabel.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _stub(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label bientôt disponible.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionRow(
            icon: Icons.print_outlined,
            label: 'Imprimer les bons de livraison',
            onTap: _busy ? null : () => _stub("L'impression"),
          ),
          _Divider(),
          _ActionRow(
            icon: Icons.local_shipping_outlined,
            label: 'Marquer comme expédié',
            onTap: _busy ? null : _runShipNow,
          ),
          _Divider(),
          _ActionRow(
            icon: Icons.cancel_outlined,
            label: 'Annuler + réapprovisionner',
            destructive: true,
            onTap: _busy ? null : _runCancel,
          ),
          _Divider(),
          _ActionRow(
            icon: Icons.file_download_outlined,
            label: 'Exporter (CSV)',
            onTap: _busy ? null : () => _stub("L'export CSV"),
          ),
          SizedBox(height: context.spacing.space4),
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler la sélection',
              style: context.typography.button.copyWith(color: c.fg2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = destructive ? c.red : c.fg1;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Text(
                label,
                style: context.typography.bodyMd.copyWith(color: fg),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.fg3),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.colors.border1);
  }
}
