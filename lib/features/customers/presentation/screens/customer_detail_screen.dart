import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_toggle_row.dart';
import '../../../../shared/widgets/segment_chip.dart';
import '../../domain/customer_address_models.dart';
import '../../domain/customer_models.dart';
import '../../domain/customer_note_models.dart';
import '../providers/customer_addresses_provider.dart';
import '../providers/customer_notes_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/address_sheet.dart';
import '../widgets/customer_chips.dart';
import '../widgets/new_note_sheet.dart';
import '../widgets/tag_picker_sheet.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        child: customerAsync.when(
          loading: () => _DetailSkeleton(onBack: () => context.pop()),
          error: (_, __) => _DetailError(
            onBack: () => context.pop(),
            onRetry: () =>
                ref.invalidate(customerDetailProvider(customerId)),
          ),
          data: (customer) => _CustomerDetailContent(customer: customer),
        ),
      ),
    );
  }
}

class _CustomerDetailContent extends StatelessWidget {
  const _CustomerDetailContent({required this.customer});
  final CustomerDetail customer;

  @override
  Widget build(BuildContext context) {
    final stats = customer.stats;
    final c = context.colors;
    final cityLine = [customer.city, customer.governorate]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return CustomScrollView(
      slivers: [
        // Section 8 — At-risk banner (above everything, conditional).
        if (stats.isAtRiskByCadence)
          SliverToBoxAdapter(
            child: _AtRiskBanner(
              daysSilent: stats.daysSinceLastOrder,
              avgCadence:
                  stats.avgDaysBetweenOrders?.round() ?? 0,
              ratio: stats.cadenceRatio ?? 0,
              channel: customer.preferredContactChannel,
            ),
          ),
        SliverToBoxAdapter(
          child: _Header(
            onBack: () => context.pop(),
            onEdit: () =>
                context.push('/customers/${customer.id}/edit'),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            0,
            context.spacing.space4,
            context.spacing.space8,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              // Section 1 — Name (with 🎂 if upcoming birthday) + segment chip.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          customer.name,
                          style:
                              context.typography.h1.copyWith(color: c.fg1),
                        ),
                        if (customer.isBirthdaySoon)
                          const Text(
                            '🎂',
                            style: TextStyle(fontSize: 18),
                          ),
                      ],
                    ),
                  ),
                  if (customer.segment != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SegmentChip(segment: customer.segment!),
                    ),
                ],
              ),
              SizedBox(height: context.spacing.space2),
              _PhoneRow(phone: customer.phone),
              if (stats.hasHighReturnRate) ...[
                SizedBox(height: context.spacing.space3),
                _HighReturnRateBadge(returnRate: stats.returnRate ?? 0),
              ],
              if (cityLine.isNotEmpty) ...[
                SizedBox(height: context.spacing.space2),
                Text(
                  cityLine,
                  style: context.typography.bodyMd.copyWith(color: c.fg3),
                ),
              ],
              SizedBox(height: context.spacing.space3),
              // Section 1 — header pills (RFM + Risk + Channel).
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RfmBadge(segment: customer.rfmSegment),
                  RiskBadge(
                    customer: customer,
                    onTap: () => openRiskSheet(
                      context: context,
                      customer: customer,
                    ),
                  ),
                  ChannelPill(channel: customer.preferredContactChannel),
                ],
              ),
              SizedBox(height: context.spacing.space6),
              // Section 2 — Lifetime KPIs.
              _LifetimeKpisStrip(stats: stats),
              SizedBox(height: context.spacing.space6),
              _ActionButtons(customer: customer),
              // Section 3 — COD success bar. Hidden when no orders.
              if (stats.codTotal > 0) ...[
                SizedBox(height: context.spacing.space6),
                _CodSuccessBar(
                  accepted: stats.codAccepted,
                  total: stats.codTotal,
                  codEnabled: customer.codEnabled,
                ),
              ],
              SizedBox(height: context.spacing.space6),
              // Section 4 — Toggles.
              _StatusTogglesSection(customer: customer),
              SizedBox(height: context.spacing.space6),
              // Section 5 — Tags.
              _TagsSection(customer: customer),
              SizedBox(height: context.spacing.space6),
              // Section 6 — Notes (F8).
              _CustomerNotesSection(customerId: customer.id),
              SizedBox(height: context.spacing.space6),
              // Section 7 — Informations (Birthday + Addresses).
              _InformationsSection(customer: customer),
              if (customer.lastProducts.isNotEmpty) ...[
                SizedBox(height: context.spacing.space6),
                _LastPurchasedSection(products: customer.lastProducts),
              ],
              if (customer.defaultDiscountAmount > 0) ...[
                SizedBox(height: context.spacing.space6),
                _DefaultDiscountBanner(
                  amount: customer.defaultDiscountAmount,
                  expiresAt: customer.defaultDiscountExpiresAt,
                ),
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
  const _Header({required this.onBack, required this.onEdit});
  final VoidCallback onBack;
  final VoidCallback onEdit;

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
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: c.fg1),
            ),
          ),
          const Spacer(),
          _ScaleTap(
            pressedScale: 0.92,
            onTap: onEdit,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.edit_outlined, size: 18, color: c.fg1),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Phone row (tap to copy)
// ════════════════════════════════════════════════════════════
class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: () {
        Clipboard.setData(ClipboardData(text: phone));
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro copié')),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            phone,
            style: context.typography.bodyMd.copyWith(color: c.fg2),
          ),
          SizedBox(width: context.spacing.space2),
          Icon(Icons.content_copy_outlined, size: 14, color: c.fg3),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// High return rate badge
// ════════════════════════════════════════════════════════════
class _HighReturnRateBadge extends StatelessWidget {
  const _HighReturnRateBadge({required this.returnRate});
  final double returnRate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.coralTint12,
        borderRadius: BorderRadius.circular(context.radius.radiusInput),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 14, color: c.coralFg),
          const SizedBox(width: 6),
          Text(
            'Taux de retour élevé (${returnRate.toStringAsFixed(0)}%)',
            style: context.typography.bodySmall.copyWith(
              color: c.coralFg,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════
// Action buttons
// ════════════════════════════════════════════════════════════
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.customer});
  final CustomerDetail customer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DidoButton.primary(
          label: 'Nouvelle commande',
          icon: Icons.receipt_long_outlined,
          onPressed: () => context.push(
            '/orders/add',
            extra: {'customer': customer},
          ),
        ),
        SizedBox(height: context.spacing.space2),
        DidoButton.secondary(
          label: 'Appeler',
          icon: Icons.phone_outlined,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: customer.phone));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Numéro copié')),
            );
          },
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Status toggles section (NEW_FEATURES_SPEC §3.4)
// ════════════════════════════════════════════════════════════
class _StatusTogglesSection extends ConsumerWidget {
  const _StatusTogglesSection({required this.customer});
  final CustomerDetail customer;

  Future<void> _setBlocked(WidgetRef ref, BuildContext context, bool value) async {
    try {
      await ref
          .read(customerDetailProvider(customer.id).notifier)
          .setToggles(isBlocked: value);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text('Impossible de mettre à jour le statut.'),
        ),
      );
    }
  }

  Future<void> _setRequirePrepayment(
    WidgetRef ref,
    BuildContext context,
    bool value,
  ) async {
    try {
      await ref
          .read(customerDetailProvider(customer.id).notifier)
          .setToggles(requirePrepayment: value);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text('Impossible de mettre à jour le statut.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut du client',
          style: context.typography.h4.copyWith(color: c.fg1),
        ),
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
              DidoToggleRow(
                label: 'Bloquer ce client',
                sub: 'Empêche la création de nouvelles commandes.',
                subWhenOn: 'Commandes bloquées',
                value: customer.isBlocked,
                destructive: true,
                onChanged: (v) => _setBlocked(ref, context, v),
              ),
              Container(
                height: 1,
                margin: EdgeInsets.only(left: context.spacing.space4),
                color: c.border1,
              ),
              DidoToggleRow(
                label: 'Exiger un prépaiement',
                sub: 'Aucun effet sur le COD pour l\'instant.',
                subWhenOn: 'COD désactivé pour ce client',
                value: customer.requirePrepayment,
                onChanged: (v) => _setRequirePrepayment(ref, context, v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Last purchased section
// ════════════════════════════════════════════════════════════
class _LastPurchasedSection extends StatelessWidget {
  const _LastPurchasedSection({required this.products});
  final List<CustomerLastProduct> products;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dernier achat',
          style: context.typography.h4.copyWith(color: c.fg1),
        ),
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
              for (var i = 0; i < products.length; i++) ...[
                _LastProductRow(product: products[i]),
                if (i != products.length - 1)
                  Container(
                    height: 1,
                    margin: EdgeInsets.only(left: context.spacing.space8),
                    color: c.border1,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LastProductRow extends StatelessWidget {
  const _LastProductRow({required this.product});
  final CustomerLastProduct product;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space4,
        vertical: context.spacing.space3,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(context.radius.radiusInput),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.inventory_2_outlined, size: 18, color: c.fg2),
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space1),
                Text(
                  DateFormatter.short(product.lastOrderedAt),
                  style: context.typography.bodySmall
                      .copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacing.space2),
          _BoolStockChip(inStock: product.inStock),
        ],
      ),
    );
  }
}

class _BoolStockChip extends StatelessWidget {
  const _BoolStockChip({required this.inStock});
  final bool inStock;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = inStock ? c.greenTint12 : c.coralTint12;
    final fg = inStock ? c.greenFg : c.coralFg;
    final label = inStock ? 'En stock' : 'Rupture';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.radius.radiusChip),
      ),
      child: Text(
        label,
        style: context.typography.tabPill.copyWith(color: fg),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Default discount banner
// ════════════════════════════════════════════════════════════
class _DefaultDiscountBanner extends StatelessWidget {
  const _DefaultDiscountBanner({
    required this.amount,
    required this.expiresAt,
  });

  final int amount;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space4),
      decoration: BoxDecoration(
        color: c.greenTint12,
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_offer_outlined, size: 20, color: c.greenFg),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remise de ${MillimesFormatter.format(amount)}',
                  style: context.typography.bodyMd.copyWith(
                    color: c.greenFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expiresAt != null) ...[
                  SizedBox(height: context.spacing.space1),
                  Text(
                    'Expire le ${DateFormatter.short(expiresAt!)}',
                    style: context.typography.bodySmall.copyWith(
                      color: c.greenFg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
    Widget block({required double w, required double h, double r = 4}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(r),
        ),
      ).animate(onPlay: (ctrl) => ctrl.repeat()).shimmer(
            duration: const Duration(milliseconds: 1500),
            color: c.surface3,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(onBack: onBack, onEdit: () {}),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            0,
            context.spacing.space4,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(w: 220, h: 28),
              SizedBox(height: context.spacing.space3),
              block(w: 140, h: 16),
              SizedBox(height: context.spacing.space6),
              block(
                w: double.infinity,
                h: 88,
                r: context.radius.radiusCard,
              ),
              SizedBox(height: context.spacing.space6),
              block(
                w: double.infinity,
                h: 48,
                r: context.radius.radiusInput,
              ),
              SizedBox(height: context.spacing.space6),
              block(
                w: double.infinity,
                h: 200,
                r: context.radius.radiusCard,
              ),
            ],
          ),
        ),
      ],
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
        _Header(onBack: onBack, onEdit: () {}),
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
                    'Impossible de charger le client',
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

// ════════════════════════════════════════════════════════════
// Customer Notes section (Feature 8)
// ════════════════════════════════════════════════════════════
class _CustomerNotesSection extends ConsumerWidget {
  const _CustomerNotesSection({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final notesAsync = ref.watch(customerNotesProvider(customerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Notes',
                style: context.typography.h4.copyWith(color: c.fg1),
              ),
            ),
            TextButton.icon(
              onPressed: () => showNoteSheet(
                context: context,
                customerId: customerId,
              ),
              icon: Icon(Icons.add, size: 18, color: c.brandTeal),
              label: Text(
                'Ajouter',
                style: context.typography.button.copyWith(color: c.brandTeal),
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.space2),
        notesAsync.when(
          loading: () => _NotesSkeleton(),
          error: (_, __) => _NotesError(
            onRetry: () =>
                ref.invalidate(customerNotesProvider(customerId)),
          ),
          data: (notes) {
            if (notes.isEmpty) {
              return _NotesEmpty(
                onAdd: () => showNoteSheet(
                  context: context,
                  customerId: customerId,
                ),
              );
            }
            final pinned = notes.where((n) => n.isPinned).toList();
            final others = notes.where((n) => !n.isPinned).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pinned.isNotEmpty) ...[
                  _PinnedNoteCard(note: pinned.first, customerId: customerId),
                  if (others.isNotEmpty)
                    SizedBox(height: context.spacing.space3),
                ],
                if (others.isNotEmpty)
                  _OthersNotesCard(notes: others, customerId: customerId),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NotesEmpty extends StatelessWidget {
  const _NotesEmpty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(context.radius.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          children: [
            Icon(Icons.sticky_note_2_outlined, size: 18, color: c.fg3),
            SizedBox(width: context.spacing.space2),
            Expanded(
              child: Text(
                'Aucune note pour ce client',
                style: context.typography.bodyMd.copyWith(color: c.fg3),
              ),
            ),
            Text(
              'Ajouter',
              style: context.typography.button.copyWith(color: c.brandTeal),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
    );
  }
}

class _NotesError extends StatelessWidget {
  const _NotesError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.coralTint12,
        border: Border.all(color: c.coralFg.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Impossible de charger les notes.',
              style: context.typography.bodyMd.copyWith(color: c.coralFg),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: context.typography.button.copyWith(color: c.coralFg),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedNoteCard extends StatelessWidget {
  const _PinnedNoteCard({required this.note, required this.customerId});
  final CustomerNote note;
  final String customerId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border(
          top: BorderSide(color: c.border1),
          right: BorderSide(color: c.border1),
          bottom: BorderSide(color: c.border1),
          left: BorderSide(color: c.brandTeal, width: 3),
        ),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin, size: 14, color: c.brandTeal),
              SizedBox(width: context.spacing.space2),
              Expanded(
                child: Text(
                  'ÉPINGLÉE · ${DateFormatter.short(note.createdAt)}',
                  style:
                      context.typography.label.copyWith(color: c.brandTeal),
                ),
              ),
              _NoteMoreButton(note: note, customerId: customerId),
            ],
          ),
          SizedBox(height: context.spacing.space2),
          Text(
            note.content,
            style: context.typography.bodyMd.copyWith(color: c.fg1),
          ),
        ],
      ),
    );
  }
}

class _OthersNotesCard extends StatelessWidget {
  const _OthersNotesCard({
    required this.notes,
    required this.customerId,
  });
  final List<CustomerNote> notes;
  final String customerId;

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
          for (var i = 0; i < notes.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: c.border1.withValues(alpha: 0.5),
              ),
            _NoteRow(note: notes[i], customerId: customerId),
          ],
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.customerId});
  final CustomerNote note;
  final String customerId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  style: context.typography.bodyMd.copyWith(color: c.fg1),
                ),
                SizedBox(height: 2),
                Text(
                  DateFormatter.short(note.createdAt),
                  style: context.typography.caption.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          _NoteMoreButton(note: note, customerId: customerId),
        ],
      ),
    );
  }
}

class _NoteMoreButton extends ConsumerWidget {
  const _NoteMoreButton({required this.note, required this.customerId});
  final CustomerNote note;
  final String customerId;

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final c = context.colors;
    final notifier =
        ref.read(customerNotesProvider(customerId).notifier);
    final messenger = ScaffoldMessenger.of(context);
    final action = await showModalBottomSheet<_NoteAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final sc = sheetCtx.colors;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sc.surface0,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    note.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin,
                    color: sc.fg1,
                  ),
                  title: Text(note.isPinned ? 'Détacher' : 'Épingler'),
                  onTap: () => Navigator.of(sheetCtx).pop(
                    note.isPinned ? _NoteAction.unpin : _NoteAction.pin,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: sc.fg1),
                  title: const Text('Modifier'),
                  onTap: () =>
                      Navigator.of(sheetCtx).pop(_NoteAction.edit),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: sc.red),
                  title: Text(
                    'Supprimer',
                    style: TextStyle(color: sc.red),
                  ),
                  onTap: () =>
                      Navigator.of(sheetCtx).pop(_NoteAction.delete),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == null) return;
    try {
      switch (action) {
        case _NoteAction.pin:
          await notifier.edit(note.id, isPinned: true);
          break;
        case _NoteAction.unpin:
          await notifier.edit(note.id, isPinned: false);
          break;
        case _NoteAction.edit:
          if (!context.mounted) return;
          await showNoteSheet(
            context: context,
            customerId: customerId,
            existing: note,
          );
          break;
        case _NoteAction.delete:
          await notifier.delete(note.id);
          break;
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: c.red,
          content: const Text('Échec de l\'opération. Réessayer.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.92,
      onTap: () => _openMenu(context, ref),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.surface2,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.more_horiz, size: 16, color: c.fg2),
      ),
    );
  }
}

enum _NoteAction { pin, unpin, edit, delete }

// ════════════════════════════════════════════════════════════
// Customer Addresses section (Feature 9)
// ════════════════════════════════════════════════════════════
class _CustomerAddressesSection extends ConsumerWidget {
  const _CustomerAddressesSection({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final addressesAsync = ref.watch(customerAddressesProvider(customerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresses',
          style: context.typography.h4.copyWith(color: c.fg1),
        ),
        SizedBox(height: context.spacing.space2),
        addressesAsync.when(
          loading: () => _AddrSkeleton(),
          error: (_, __) => _AddrError(
            onRetry: () =>
                ref.invalidate(customerAddressesProvider(customerId)),
          ),
          data: (addresses) => _AddressesCard(
            addresses: addresses,
            customerId: customerId,
          ),
        ),
      ],
    );
  }
}

class _AddressesCard extends StatelessWidget {
  const _AddressesCard({
    required this.addresses,
    required this.customerId,
  });
  final List<CustomerAddress> addresses;
  final String customerId;

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
          for (var i = 0; i < addresses.length; i++) ...[
            _AddressRow(
              address: addresses[i],
              customerId: customerId,
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: c.border1.withValues(alpha: 0.5),
            ),
          ],
          _AddAddressRow(customerId: customerId),
        ],
      ),
    );
  }
}

class _AddressRow extends ConsumerWidget {
  const _AddressRow({required this.address, required this.customerId});
  final CustomerAddress address;
  final String customerId;

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final c = context.colors;
    final notifier =
        ref.read(customerAddressesProvider(customerId).notifier);
    final messenger = ScaffoldMessenger.of(context);

    final action = await showModalBottomSheet<_AddrAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final sc = sheetCtx.colors;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sc.surface0,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!address.isDefault)
                  ListTile(
                    leading: Icon(Icons.star_outline, color: sc.fg1),
                    title: const Text('Définir par défaut'),
                    onTap: () => Navigator.of(sheetCtx)
                        .pop(_AddrAction.setDefault),
                  ),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: sc.fg1),
                  title: const Text('Modifier'),
                  onTap: () =>
                      Navigator.of(sheetCtx).pop(_AddrAction.edit),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: sc.red),
                  title: Text(
                    'Supprimer',
                    style: TextStyle(color: sc.red),
                  ),
                  onTap: () =>
                      Navigator.of(sheetCtx).pop(_AddrAction.delete),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;
    try {
      switch (action) {
        case _AddrAction.setDefault:
          await notifier.setDefault(address.id);
          break;
        case _AddrAction.edit:
          if (!context.mounted) return;
          await showAddressSheet(
            context: context,
            customerId: customerId,
            existing: address,
          );
          break;
        case _AddrAction.delete:
          await notifier.delete(address.id);
          break;
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: c.red,
          content: const Text('Échec de l\'opération. Réessayer.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final labelText = (address.label ?? '').isNotEmpty
        ? address.label!
        : 'Adresse';
    final secondary = '${address.addressLine}, ${address.city} · '
        '${address.governorate}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.surface2,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.location_on_outlined, size: 16, color: c.fg2),
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        labelText,
                        style: context.typography.h4.copyWith(color: c.fg1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (address.isDefault) ...[
                      SizedBox(width: context.spacing.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: c.brandTealTint08,
                          borderRadius: BorderRadius.circular(
                              context.radius.radiusChip),
                        ),
                        child: Text(
                          'Par défaut',
                          style: context.typography.label
                              .copyWith(color: c.brandTeal),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  secondary,
                  style:
                      context.typography.bodySmall.copyWith(color: c.fg3),
                ),
                if (address.deliveryNotes != null &&
                    address.deliveryNotes!.isNotEmpty) ...[
                  SizedBox(height: context.spacing.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      address.deliveryNotes!,
                      style: context.typography.bodySmall
                          .copyWith(color: c.fg2),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _ScaleTap(
            pressedScale: 0.92,
            onTap: () => _openMenu(context, ref),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.more_horiz, size: 16, color: c.fg2),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAddressRow extends StatelessWidget {
  const _AddAddressRow({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () => showAddressSheet(
        context: context,
        customerId: customerId,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.brandTealTint08,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 18, color: c.brandTeal),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Text(
                'Ajouter une adresse',
                style:
                    context.typography.h4.copyWith(color: c.brandTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddrSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
    );
  }
}

class _AddrError extends StatelessWidget {
  const _AddrError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.coralTint12,
        border: Border.all(color: c.coralFg.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Impossible de charger les adresses.',
              style: context.typography.bodyMd.copyWith(color: c.coralFg),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: context.typography.button.copyWith(color: c.coralFg),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AddrAction { setDefault, edit, delete }

// ════════════════════════════════════════════════════════════
// At-risk banner (Section 8)
// ════════════════════════════════════════════════════════════
class _AtRiskBanner extends StatelessWidget {
  const _AtRiskBanner({
    required this.daysSilent,
    required this.avgCadence,
    required this.ratio,
    required this.channel,
  });
  final int daysSilent;
  final int avgCadence;
  final double ratio;
  final ContactChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratioLabel = ratio >= 10
        ? '${ratio.toStringAsFixed(0)}×'
        : '${ratio.toStringAsFixed(1)}×';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.coralTint12,
        border: Border(bottom: BorderSide(color: c.coral, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.coral,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.warning_amber_rounded,
                size: 18, color: c.surface0),
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ce client n\'a pas commandé depuis $daysSilent jours',
                  style: context.typography.h4.copyWith(color: c.coralFg),
                ),
                SizedBox(height: 2),
                Text(
                  'Sa moyenne est $avgCadence jours · $ratioLabel au-dessus',
                  style: context.typography.bodySmall.copyWith(
                    color: c.coralFg.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacing.space2),
          _ContactPill(channel: channel),
        ],
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.channel});
  final ContactChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, bg) = _styleFor(c, channel);
    return InkWell(
      onTap: () {
        // url_launcher not in pubspec — stub with snackbar (consistent
        // with F7 / F9 / channel pill in chips file).
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien direct bientôt disponible.')),
        );
      },
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c.surface0),
            SizedBox(width: context.spacing.space2),
            Text(
              'Contacter',
              style: context.typography.button.copyWith(color: c.surface0),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _styleFor(dynamic c, ContactChannel ch) {
    switch (ch) {
      case ContactChannel.whatsapp:
        return (Icons.chat_outlined, c.whatsappGreen);
      case ContactChannel.sms:
        return (Icons.sms_outlined, c.brandTeal);
      case ContactChannel.call:
        return (Icons.call_outlined, c.fg1);
      case ContactChannel.instagramDm:
        return (Icons.camera_alt_outlined, c.fg1);
      case ContactChannel.facebookDm:
        return (Icons.facebook_outlined, c.fg1);
    }
  }
}

// ════════════════════════════════════════════════════════════
// Lifetime KPIs strip (Section 2) — replaces old _StatsRow.
// ════════════════════════════════════════════════════════════
class _LifetimeKpisStrip extends StatelessWidget {
  const _LifetimeKpisStrip({required this.stats});
  final CustomerStats stats;

  @override
  Widget build(BuildContext context) {
    final lastOrder = stats.lastOrderDate;
    String lastLabel;
    if (lastOrder == null) {
      lastLabel = '—';
    } else {
      final days = stats.daysSinceLastOrder;
      if (days == 0) {
        lastLabel = "aujourd'hui";
      } else if (days == 1) {
        lastLabel = 'il y a 1 j';
      } else if (days < 30) {
        lastLabel = 'il y a $days j';
      } else if (days < 365) {
        final months = (days / 30).round();
        lastLabel = 'il y a $months mois';
      } else {
        final years = (days / 365).round();
        lastLabel = 'il y a $years an${years > 1 ? 's' : ''}';
      }
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.0,
      children: [
        _KpiTile(
          label: 'Total dépensé',
          value: MillimesFormatter.format(stats.totalSpent),
          numeric: true,
        ),
        _KpiTile(
          label: 'Commandes',
          value: stats.totalOrders.toString(),
          numeric: true,
        ),
        _KpiTile(
          label: 'Panier moyen',
          value: MillimesFormatter.format(stats.avgOrderValue),
          numeric: true,
        ),
        _KpiTile(
          label: 'Dernière commande',
          value: lastLabel,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    this.numeric = false,
  });
  final String label;
  final String value;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: context.typography.caption.copyWith(color: c.fg3),
          ),
          SizedBox(height: context.spacing.space2),
          Text(
            value,
            style: (numeric
                    ? context.typography.numberLg
                    : context.typography.h4)
                .copyWith(color: c.fg1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// COD success bar (Section 3 lower half).
// ════════════════════════════════════════════════════════════
class _CodSuccessBar extends StatelessWidget {
  const _CodSuccessBar({
    required this.accepted,
    required this.total,
    required this.codEnabled,
  });
  final int accepted;
  final int total;
  final bool codEnabled;

  static const _threshold = 0.7;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = total == 0 ? 0.0 : accepted / total;
    final belowThreshold = ratio < _threshold;
    final barColor = belowThreshold ? c.red : c.greenFg;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Livraisons COD acceptées',
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$accepted',
                      style: context.typography.numberLg
                          .copyWith(color: c.fg1),
                    ),
                    TextSpan(
                      text: ' / $total',
                      style: context.typography.bodySmall
                          .copyWith(color: c.fg3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(height: 6, color: c.surface2),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(height: 6, color: barColor),
                ),
              ],
            ),
          ),
          if (belowThreshold && !codEnabled) ...[
            SizedBox(height: context.spacing.space3),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.redTint12,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: c.redFg),
                  SizedBox(width: context.spacing.space2),
                  Text(
                    'COD désactivé automatiquement',
                    style: context.typography.label.copyWith(color: c.redFg),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Tags section (Section 5)
// ════════════════════════════════════════════════════════════
class _TagsSection extends ConsumerWidget {
  const _TagsSection({required this.customer});
  final CustomerDetail customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tags = customer.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: context.typography.h4.copyWith(color: c.fg1),
        ),
        SizedBox(height: context.spacing.space2),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              _TagChip(
                label: tag,
                onRemove: () async {
                  try {
                    final next = [...tags]..remove(tag);
                    await ref
                        .read(customerDetailProvider(customer.id).notifier)
                        .setProfile(tags: next);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: c.red,
                        content: const Text(
                            'Impossible de supprimer le tag.'),
                      ),
                    );
                  }
                },
              ),
            _AddTagChip(
              onTap: () => showTagPickerSheet(
                context: context,
                customer: customer,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.typography.button.copyWith(color: c.fg1),
          ),
          SizedBox(width: context.spacing.space2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              child: Icon(Icons.close, size: 12, color: c.fg3),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTagChip extends StatelessWidget {
  const _AddTagChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: _DashedBorder(
            color: c.border2,
            strokeWidth: 1,
            dashLength: 4,
            gapLength: 3,
            radius: 9999,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: c.fg2),
            SizedBox(width: context.spacing.space2),
            Text(
              'Ajouter',
              style: context.typography.button.copyWith(color: c.fg2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorder extends ShapeBorder {
  const _DashedBorder({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final outline = getOuterPath(rect.deflate(strokeWidth / 2));
    for (final metric in outline.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final segment =
            metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  ShapeBorder scale(double t) => this;
}

// ════════════════════════════════════════════════════════════
// Informations section (Section 7): Birthday + Addresses.
// ════════════════════════════════════════════════════════════
class _InformationsSection extends ConsumerWidget {
  const _InformationsSection({required this.customer});
  final CustomerDetail customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: context.typography.h4.copyWith(color: c.fg1),
        ),
        SizedBox(height: context.spacing.space2),
        _BirthdayRow(customer: customer),
        SizedBox(height: context.spacing.space3),
        _CustomerAddressesSection(customerId: customer.id),
      ],
    );
  }
}

class _BirthdayRow extends ConsumerWidget {
  const _BirthdayRow({required this.customer});
  final CustomerDetail customer;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: customer.birthday ?? DateTime(now.year - 25, 6, 15),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      locale: const Locale('fr', 'TN'),
    );
    if (picked == null || !context.mounted) return;
    try {
      await ref
          .read(customerDetailProvider(customer.id).notifier)
          .setProfile(birthday: picked);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text("Impossible d'enregistrer l'anniversaire."),
        ),
      );
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Effacer l'anniversaire ?"),
        content: const Text('La date sera supprimée du profil client.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref
          .read(customerDetailProvider(customer.id).notifier)
          .setProfile(clearBirthday: true);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text("Impossible d'effacer l'anniversaire."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final upcoming = customer.isBirthdaySoon;
    final birthday = customer.birthday;
    final days = customer.daysUntilBirthday;
    String sub;
    if (birthday == null) {
      sub = 'Ajouter une date';
    } else {
      final base = DateFormatter.short(birthday);
      if (upcoming && days != null) {
        sub = days == 0
            ? "$base · aujourd'hui"
            : days == 1
                ? '$base · demain'
                : '$base · dans $days jours';
      } else {
        sub = base;
      }
    }
    return InkWell(
      onTap: () => _pick(context, ref),
      onLongPress: birthday == null ? null : () => _clear(context, ref),
      borderRadius: BorderRadius.circular(context.radius.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface0,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: upcoming ? c.coralTint12 : c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.cake_outlined,
                size: 18,
                color: upcoming ? c.coralFg : c.fg1,
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anniversaire',
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  SizedBox(height: 2),
                  Text(
                    sub,
                    style: context.typography.bodySmall.copyWith(
                      color: upcoming ? c.coralFg : c.fg3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.fg3),
          ],
        ),
      ),
    );
  }
}
