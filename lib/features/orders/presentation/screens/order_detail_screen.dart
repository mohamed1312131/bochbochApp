import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_product_image.dart';
import '../../../../shared/widgets/profit_panel.dart';
import '../../domain/exchange_models.dart';
import '../../domain/issue_models.dart';
import '../../domain/order_models.dart';
import '../../domain/rto_models.dart';
import '../providers/order_provider.dart';
import '../providers/rto_provider.dart';
import '../widgets/rto_section.dart';
import 'delivery_issue_type_screen.dart';
import 'exchange_pick_item_screen.dart';
import 'partial_fulfill_split_screen.dart';
import '../../domain/partial_fulfill_models.dart';

bool _canStartExchange(String status) =>
    status == 'SHIPPED' ||
    status == 'DELIVERED' ||
    status == 'EXCHANGE_IN_PROGRESS';

bool _canReportIssue(String status) =>
    status == 'SHIPPED' || status == 'DELIVERED';

bool _canMarkRto(String status) => status == 'SHIPPED';

// Partial fulfillment (Feature 7). Entry surfaces on CONFIRMED orders
// that have more than one line — the split screen itself handles the
// single-item edge case gracefully (it just shows everything in one
// bucket), but there's no user value in surfacing the entry unless
// there's something to split.
bool _canPartialFulfill(String status, int itemCount) =>
    status == 'CONFIRMED' && itemCount > 1;

const _statusSteps = <_StatusStep>[
  _StatusStep('PENDING', 'En attente', Icons.hourglass_empty_rounded),
  _StatusStep('CONFIRMED', 'Confirmée', Icons.check_circle_outline),
  _StatusStep('SHIPPED', 'Expédiée', Icons.local_shipping_outlined),
  _StatusStep('DELIVERED', 'Livrée', Icons.home_outlined),
];

class _StatusStep {
  const _StatusStep(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;
}

List<String> _nextStatuses(String current) => switch (current) {
  'PENDING' => ['CONFIRMED', 'CANCELLED'],
  'CONFIRMED' => ['SHIPPED', 'CANCELLED'],
  'SHIPPED' => ['DELIVERED', 'CANCELLED'],
  _ => [],
};

String _forwardActionLabel(String currentStatus) => switch (currentStatus) {
  'PENDING' => 'Confirmer la commande',
  'CONFIRMED' => 'Marquer comme expédiée',
  'SHIPPED' => 'Marquer comme livrée',
  _ => '',
};

String _forwardStatus(String currentStatus) => switch (currentStatus) {
  'PENDING' => 'CONFIRMED',
  'CONFIRMED' => 'SHIPPED',
  'SHIPPED' => 'DELIVERED',
  _ => currentStatus,
};

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isUpdating = false;
  bool _isDeleting = false;

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateStatus(widget.orderId, newStatus);
      ref.read(orderListProvider.notifier).refresh();
      ref.invalidate(orderDetailProvider(widget.orderId));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : impossible de mettre à jour le statut'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _confirmCancel() async {
    final c = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Retour',
              style: context.typography.bodyMd.copyWith(color: c.fg2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Annuler la commande',
              style: context.typography.bodyMd.copyWith(
                color: c.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _updateStatus('CANCELLED');
    }
  }

  Future<void> _startMarkRto(Order order) async {
    final reason = await showRtoReasonPickerSheet(context);
    if (reason == null || !mounted) return;
    try {
      await ref
          .read(submitRtoProvider.notifier)
          .submit(
            orderId: order.id,
            reason: reason,
            targetStatus: RtoTargetStatus.inTransit,
          );
      if (!mounted) return;
      // Success snackbar comes from the RtoSection's listener once the
      // detail re-renders in RTO_IN_TRANSIT state. Here we just refresh.
      ref.invalidate(orderListProvider);
      ref.invalidate(orderDetailProvider(order.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text('Impossible de marquer la RTO.'),
        ),
      );
    }
  }

  void _startIssueReport(Order order) {
    // Build the client-side preview of items that will be restored.
    // Mirrors the backend rules: skip backorder, skip bundle (we
    // don't have isBundle on the OrderItem, so we approximate by
    // always including non-zero quantities. Backend has the
    // authoritative answer in the response.)
    final preview = <ExpectedRestoreLine>[];
    for (final item in order.items) {
      final qty = item.quantity - item.returnedQuantity;
      if (qty <= 0) continue;
      preview.add(
        ExpectedRestoreLine(productName: item.productName, quantity: qty),
      );
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliveryIssueTypeScreen(
          draft: IssueDraft(
            orderId: order.id,
            orderNumber: order.orderNumber,
            expectedStockRestore: preview,
          ),
        ),
      ),
    );
  }

  void _startPartialFulfill(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PartialFulfillSplitScreen(
          orderId: order.id,
          orderNumber: order.orderNumber,
          items: order.items,
          // Order.customer doesn't expose preferredContactChannel
          // (it's a separate customer detail load). Default to
          // WhatsApp; the real channel will be surfaced on the
          // post-submit confirmation snackbar.
          customer: PartialFulfillCustomer(
            id: order.customer.id,
            name: order.customer.name,
            phone: order.customer.phone,
            preferredContactChannel: 'WHATSAPP',
          ),
        ),
      ),
    );
  }

  void _startExchange(Order order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final original = firstItem == null
        ? null
        : ExchangeOriginalSnapshot(
            productName: firstItem.productName,
            attributes: {
              for (final entry
                  in (firstItem.variantAttributes ?? const {}).entries)
                entry.key: entry.value.toString(),
            },
            unitPrice: firstItem.unitPrice,
          );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExchangePickItemScreen(
          draft: ExchangeDraft(
            orderId: order.id,
            orderNumber: order.orderNumber,
            original: original,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final c = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la commande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: context.typography.bodyMd.copyWith(color: c.fg2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Supprimer',
              style: context.typography.bodyMd.copyWith(
                color: c.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await ref.read(orderRepositoryProvider).deleteOrder(widget.orderId);
      ref.read(orderListProvider.notifier).removeOrder(widget.orderId);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur : impossible de supprimer la commande'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        child: orderAsync.when(
          loading: () => _DetailSkeleton(onBack: () => context.pop()),
          error: (_, __) => _DetailError(
            onBack: () => context.pop(),
            onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
          ),
          data: (order) => _OrderContent(
            order: order,
            isUpdating: _isUpdating,
            isDeleting: _isDeleting,
            onForward: () => _updateStatus(_forwardStatus(order.status)),
            onCancel: _confirmCancel,
            onDelete: _confirmDelete,
            onExchange: () => _startExchange(order),
            onReportIssue: () => _startIssueReport(order),
            onMarkRto: () => _startMarkRto(order),
            onReattemptDelivery: () => _updateStatus('SHIPPED'),
            onPartialFulfill: () => _startPartialFulfill(order),
          ),
        ),
      ),
    );
  }
}

class _OrderContent extends StatelessWidget {
  const _OrderContent({
    required this.order,
    required this.isUpdating,
    required this.isDeleting,
    required this.onForward,
    required this.onCancel,
    required this.onDelete,
    required this.onExchange,
    required this.onReportIssue,
    required this.onMarkRto,
    required this.onReattemptDelivery,
    required this.onPartialFulfill,
  });

  final Order order;
  final bool isUpdating;
  final bool isDeleting;
  final VoidCallback onForward;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onExchange;
  final VoidCallback onReportIssue;
  final VoidCallback onMarkRto;
  final VoidCallback onReattemptDelivery;
  final VoidCallback onPartialFulfill;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            orderNumber: order.orderNumber,
            createdAt: order.createdAt,
            onDelete: isDeleting ? null : onDelete,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            context.spacing.space2,
            context.spacing.space4,
            context.spacing.space8,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              if (order.status == 'RTO_IN_TRANSIT' ||
                  order.status == 'RTO_RECEIVED') ...[
                RtoSection(
                  order: order,
                  isUpdating: isUpdating,
                  onReattemptDelivery: onReattemptDelivery,
                ),
                SizedBox(height: context.spacing.space4),
              ],
              _StatusSection(
                order: order,
                isUpdating: isUpdating,
                onForward: onForward,
                onCancel: onCancel,
                onExchange: onExchange,
                onReportIssue: onReportIssue,
                onMarkRto: onMarkRto,
                onPartialFulfill: onPartialFulfill,
              ),
              SizedBox(height: context.spacing.space6),
              _CustomerSection(customer: order.customer),
              SizedBox(height: context.spacing.space6),
              _ItemsSection(items: order.items),
              SizedBox(height: context.spacing.space6),
              ProfitPanel(data: order.profitBreakdown),
              SizedBox(height: context.spacing.space6),
              _SummarySection(order: order),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                SizedBox(height: context.spacing.space6),
                _NotesSection(notes: order.notes!),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Header
// ════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header({
    required this.orderNumber,
    required this.createdAt,
    required this.onDelete,
  });

  final String orderNumber;
  final DateTime createdAt;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.space4,
        context.spacing.space3,
        context.spacing.space4,
        context.spacing.space3,
      ),
      child: Row(
        children: [
          _ScaleTap(
            pressedScale: 0.92,
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: c.fg1,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  orderNumber,
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.short(createdAt),
                  style: context.typography.bodySmall.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          _ScaleTap(
            pressedScale: 0.92,
            onTap: onDelete,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.coralTint12,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: c.coralFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Status section
// ════════════════════════════════════════════════════════════
class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.order,
    required this.isUpdating,
    required this.onForward,
    required this.onCancel,
    required this.onExchange,
    required this.onReportIssue,
    required this.onMarkRto,
    required this.onPartialFulfill,
  });

  final Order order;
  final bool isUpdating;
  final VoidCallback onForward;
  final VoidCallback onCancel;
  final VoidCallback onExchange;
  final VoidCallback onReportIssue;
  final VoidCallback onMarkRto;
  final VoidCallback onPartialFulfill;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isCancelled = order.status == 'CANCELLED';
    final next = _nextStatuses(order.status);
    final canExchange = _canStartExchange(order.status);
    final canReportIssue = _canReportIssue(order.status);
    final canMarkRto = _canMarkRto(order.status);
    final canPartialFulfill = _canPartialFulfill(
      order.status,
      order.items.length,
    );

    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        children: [
          if (isCancelled)
            const _CancelledRow()
          else
            _OrderTimeline(currentStatus: order.status),
          if (next.isNotEmpty ||
              canExchange ||
              canReportIssue ||
              canMarkRto ||
              canPartialFulfill) ...[
            SizedBox(height: context.spacing.space4),
            Container(height: 1, color: c.border1),
            SizedBox(height: context.spacing.space4),
            _StatusActions(
              currentStatus: order.status,
              itemCount: order.items.length,
              isUpdating: isUpdating,
              onForward: onForward,
              onCancel: onCancel,
              onExchange: onExchange,
              onReportIssue: onReportIssue,
              onMarkRto: onMarkRto,
              onPartialFulfill: onPartialFulfill,
            ),
          ],
        ],
      ),
    );
  }
}

class _CancelledRow extends StatelessWidget {
  const _CancelledRow();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.coralTint12,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.cancel_outlined, size: 20, color: c.coralFg),
        ),
        SizedBox(width: context.spacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Annulée',
                style: context.typography.h4.copyWith(color: c.coralFg),
              ),
              const SizedBox(height: 2),
              Text(
                'Cette commande a été annulée',
                style: context.typography.bodySmall.copyWith(color: c.fg3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.currentStatus});
  final String currentStatus;

  int get _currentIndex =>
      _statusSteps.indexWhere((s) => s.value == currentStatus);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final currentIdx = _currentIndex;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_statusSteps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isCompleted = stepIdx < currentIdx;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 19),
              child: Container(
                height: 2,
                color: isCompleted ? c.fg1 : c.border1,
              ),
            ),
          );
        }

        final stepIdx = i ~/ 2;
        final step = _statusSteps[stepIdx];
        final isCompleted = stepIdx <= currentIdx;
        final isCurrent = stepIdx == currentIdx;

        final innerCircle = Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted ? c.fg1 : c.surface2,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            step.icon,
            size: 16,
            color: isCompleted ? c.surface0 : c.fg3,
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isCurrent
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.fg1, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: innerCircle,
                  )
                : SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(child: innerCircle),
                  ),
            const SizedBox(height: 6),
            Text(
              step.label,
              style: context.typography.tabPill.copyWith(
                color: isCompleted ? c.fg1 : c.fg3,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.currentStatus,
    required this.itemCount,
    required this.isUpdating,
    required this.onForward,
    required this.onCancel,
    required this.onExchange,
    required this.onReportIssue,
    required this.onMarkRto,
    required this.onPartialFulfill,
  });

  final String currentStatus;
  final int itemCount;
  final bool isUpdating;
  final VoidCallback onForward;
  final VoidCallback onCancel;
  final VoidCallback onExchange;
  final VoidCallback onReportIssue;
  final VoidCallback onMarkRto;
  final VoidCallback onPartialFulfill;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canCancel = _nextStatuses(currentStatus).contains('CANCELLED');
    final canExchange = _canStartExchange(currentStatus);
    final canReportIssue = _canReportIssue(currentStatus);
    final canMarkRto = _canMarkRto(currentStatus);
    final canPartialFulfill = _canPartialFulfill(currentStatus, itemCount);
    final hasForward = _forwardActionLabel(currentStatus).isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasForward)
          DidoButton.primary(
            label: _forwardActionLabel(currentStatus),
            loading: isUpdating,
            onPressed: onForward,
          ),
        if (canExchange) ...[
          if (hasForward) SizedBox(height: context.spacing.space2),
          DidoButton.secondary(
            label: 'Échange',
            icon: Icons.swap_horiz_rounded,
            onPressed: isUpdating ? null : onExchange,
          ),
        ],
        if (canReportIssue) ...[
          SizedBox(height: context.spacing.space2),
          DidoButton.secondary(
            label: 'Problème de livraison',
            icon: Icons.report_problem_outlined,
            onPressed: isUpdating ? null : onReportIssue,
          ),
        ],
        if (canMarkRto) ...[
          SizedBox(height: context.spacing.space2),
          DidoButton.secondary(
            label: 'Marquer RTO',
            icon: Icons.assignment_return_outlined,
            onPressed: isUpdating ? null : onMarkRto,
          ),
        ],
        if (canPartialFulfill) ...[
          SizedBox(height: context.spacing.space2),
          DidoButton.secondary(
            label: 'Expédition partielle',
            icon: Icons.splitscreen_outlined,
            onPressed: isUpdating ? null : onPartialFulfill,
          ),
        ],
        if (canCancel) ...[
          SizedBox(height: context.spacing.space3),
          Center(
            child: TextButton(
              onPressed: isUpdating ? null : onCancel,
              child: Text(
                'Annuler la commande',
                style: context.typography.bodyMd.copyWith(
                  color: c.fg3,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Customer section
// ════════════════════════════════════════════════════════════
class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.customer});
  final OrderCustomer customer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initial = customer.name.isNotEmpty
        ? customer.name[0].toUpperCase()
        : '?';
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: context.typography.h4.copyWith(
                color: c.fg1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone,
                  style: context.typography.bodySmall.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          _ScaleTap(
            pressedScale: 0.94,
            onTap: () {
              Clipboard.setData(ClipboardData(text: customer.phone));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Numéro copié')));
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.content_copy_outlined, size: 18, color: c.fg3),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Items section
// ════════════════════════════════════════════════════════════
class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});
  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Articles', style: context.typography.h4.copyWith(color: c.fg1)),
        SizedBox(height: context.spacing.space3),
        Container(
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _ItemRow(item: items[i]),
                if (i != items.length - 1)
                  Container(height: 1, color: c.border1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profit = (item.unitPrice - item.unitCost) * item.quantity;
    final priceLine =
        '${MillimesFormatter.format(item.unitPrice)} × ${item.quantity}';
    final variant = item.attributeLabel;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space4,
        vertical: context.spacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(context.radius.radiusCard),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: item.primaryImageUrl != null
                ? DidoProductImage(
                    imageUrl: item.primaryImageUrl!,
                    fit: BoxFit.cover,
                    width: 52,
                    height: 52,
                    errorBuilder: (_) => Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: c.fg3,
                    ),
                  )
                : Icon(Icons.inventory_2_outlined, size: 20, color: c.fg3),
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                const SizedBox(height: 2),
                Text(
                  variant.isEmpty ? priceLine : '$variant · $priceLine',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.bodySmall.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacing.space2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MillimesFormatter.format(item.subtotal),
                style: context.typography.bodyMd.copyWith(
                  color: c.fg1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (profit > 0) ...[
                const SizedBox(height: 4),
                _ProfitChip(profit: profit),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfitChip extends StatelessWidget {
  const _ProfitChip({required this.profit});
  final int profit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.greenTint12,
        borderRadius: BorderRadius.circular(context.radius.radiusChip),
      ),
      child: Text(
        '+${MillimesFormatter.format(profit)}',
        style: context.typography.tabPill.copyWith(
          color: c.greenFg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Summary section
// ════════════════════════════════════════════════════════════
class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasAdSpend = order.adSpend > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récapitulatif',
          style: context.typography.h4.copyWith(color: c.fg1),
        ),
        SizedBox(height: context.spacing.space3),
        Container(
          padding: EdgeInsets.all(context.spacing.space4),
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusCard),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Chiffre d\'affaires',
                value: order.grossRevenue,
              ),
              if (order.discountAmount > 0)
                _SummaryRow(
                  label: 'Remise',
                  value: -order.discountAmount,
                  valueColor: c.coralFg,
                ),
              _SummaryRow(
                label: 'Revenu net',
                value: order.netRevenue,
                isBold: true,
              ),
              SizedBox(height: context.spacing.space3),
              Container(height: 1, color: c.border1),
              SizedBox(height: context.spacing.space3),
              _SummaryRow(
                label: 'Coût produit',
                value: -order.totalCost,
                valueColor: c.fg2,
              ),
              if (order.shippingCost > 0)
                _SummaryRow(
                  label: 'Livraison',
                  value: -order.shippingCost,
                  valueColor: c.fg2,
                ),
              if (hasAdSpend) ...[
                _SummaryRow(
                  label: 'Publicité',
                  value: -order.adSpend,
                  valueColor: c.fg2,
                ),
                SizedBox(height: context.spacing.space3),
                Container(height: 1, color: c.border1),
                SizedBox(height: context.spacing.space3),
                _SummaryRow(
                  label: 'Bénéfice réel',
                  value: order.realProfit,
                  isBold: true,
                  valueColor: order.realProfit >= 0 ? c.greenFg : c.coralFg,
                ),
              ] else ...[
                SizedBox(height: context.spacing.space3),
                Container(height: 1, color: c.border1),
                SizedBox(height: context.spacing.space3),
                _SummaryRow(
                  label: 'Bénéfice',
                  value: order.orderProfit,
                  isBold: true,
                  valueColor: order.orderProfit >= 0 ? c.greenFg : c.coralFg,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final int value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final formatted =
        (value < 0 ? '- ' : '') + MillimesFormatter.format(value.abs());
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isBold ? 4 : 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.typography.bodyMd.copyWith(
                color: isBold ? c.fg1 : c.fg2,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            formatted,
            style: context.typography.bodyMd.copyWith(
              color: valueColor ?? c.fg1,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Notes section
// ════════════════════════════════════════════════════════════
class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: context.typography.h4.copyWith(color: c.fg1)),
        SizedBox(height: context.spacing.space3),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.spacing.space4),
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusCard),
          ),
          child: Text(
            notes,
            style: context.typography.bodyMd.copyWith(
              color: c.fg2,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Skeleton + error
// ════════════════════════════════════════════════════════════
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget block(double height) {
      return Container(
            height: height,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(context.radius.radiusCard),
            ),
          )
          .animate(onPlay: (ctrl) => ctrl.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 1500),
            color: c.surface3,
          );
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.space4,
              context.spacing.space3,
              context.spacing.space4,
              context.spacing.space3,
            ),
            child: Row(
              children: [
                _ScaleTap(
                  pressedScale: 0.92,
                  onTap: onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: c.fg1,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.space4),
            child: Column(
              children: [
                block(140),
                SizedBox(height: context.spacing.space6),
                block(76),
                SizedBox(height: context.spacing.space6),
                block(180),
                SizedBox(height: context.spacing.space6),
                block(220),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onBack, required this.onRetry});
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            context.spacing.space3,
            context.spacing.space4,
            context.spacing.space3,
          ),
          child: Row(
            children: [
              _ScaleTap(
                pressedScale: 0.92,
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: c.fg1,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: c.fg3),
                  SizedBox(height: context.spacing.space3),
                  Text(
                    'Impossible de charger la commande',
                    textAlign: TextAlign.center,
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  SizedBox(height: context.spacing.space4),
                  DidoButton.secondary(
                    label: 'Réessayer',
                    onPressed: onRetry,
                    fullWidth: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Tap feedback (TODO(extract))
// ════════════════════════════════════════════════════════════
class _ScaleTap extends StatefulWidget {
  const _ScaleTap({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.98,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;
  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) {
              _set(true);
              HapticFeedback.lightImpact();
            },
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _set(false);
              widget.onTap!();
            },
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: context.motion.tap,
        curve: context.motion.easeOut,
        child: widget.child,
      ),
    );
  }
}
