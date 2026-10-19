import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/providers/user_name_provider.dart';
import '../../../boutiques/presentation/boutique_providers.dart';
import '../../../orders/domain/order_models.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../stock/presentation/providers/stock_provider.dart';
import '../providers/dashboard_provider.dart';

/// Number of recent orders to surface on the home screen.
const _recentOrdersOnHome = 3;

enum _BadgeKind { nouvelle, aRelancer }

/// Maps an [OrderLean] → optional badge for the recent-orders card.
/// PENDING within 24h → "Nouvelle"; PENDING beyond 3 days → "À relancer".
_BadgeKind? _badgeForOrder(OrderLean o) {
  if (o.status != 'PENDING') return null;
  final ageHours = DateTime.now().difference(o.createdAt).inHours;
  if (ageHours <= 24) return _BadgeKind.nouvelle;
  if (ageHours >= 72) return _BadgeKind.aRelancer;
  return null;
}

String _relativeTime(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return 'il y a ${(diff.inDays / 7).floor()} sem';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userNameProvider);
    final userInitial = userAsync.maybeWhen(
      data: (name) => name.isNotEmpty ? name[0].toUpperCase() : 'M',
      orElse: () => 'M',
    );

    return Scaffold(
      backgroundColor: context.colors.surface0,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.spacing.screenEdge,
            context.spacing.space4,
            context.spacing.screenEdge,
            96,
          ),
          children: [
            _Header(userInitial: userInitial),
            SizedBox(height: context.spacing.space6),
            Text(
              'Aujourd\'hui',
              style: context.typography.h1.copyWith(color: context.colors.fg1),
            ),
            SizedBox(height: context.spacing.space6),
            // Attention strip (À RELANCER) hidden until a relancer/follow-up
            // provider exists. Was previously a hardcoded "4 clients en
            // attente" with no real source.
            const _SectionLabel('VUE D\'ENSEMBLE'),
            SizedBox(height: context.spacing.space4),
            _TileGrid(),
            SizedBox(height: context.spacing.sectionGap),
            const _SectionLabel('COMMANDES RÉCENTES'),
            SizedBox(height: context.spacing.space4),
            const _RecentOrdersCard(),
            SizedBox(height: context.spacing.space3),
            _SeeAllButton(
              label: 'Voir tout',
              onTap: () => context.go('/orders'),
            ),
          ],
        ),
      ),
      floatingActionButton: const _HomeFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ════════════════════════════════════════════════════════════
// Reusable: scale + haptic tap feedback (no Material ripple)
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

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) {
              _setPressed(true);
              HapticFeedback.lightImpact();
            },
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _setPressed(false);
              widget.onTap!();
            },
      onTapCancel: () => _setPressed(false),
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
// Header — boutique chip (left) + user avatar (right)
// ════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header({required this.userInitial});
  final String userInitial;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _BoutiqueChip(),
        _UserAvatar(initial: userInitial),
      ],
    );
  }
}

class _BoutiqueChip extends ConsumerWidget {
  const _BoutiqueChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final boutiqueAsync = ref.watch(currentBoutiqueProvider);
    final boutique = boutiqueAsync.valueOrNull;
    // Empty boutique → empty initial / dash. Avoid leaking placeholder
    // copy ("Boutique Sania") when the provider is loading/errored.
    final name = boutique?.name ?? '—';
    final initial = (name.isNotEmpty && name != '—')
        ? name.characters.first.toUpperCase()
        : '·';

    return _ScaleTap(
      // No boutique-switcher screen exists yet; tap is inert. Removed
      // the haptic-only handler so users don't get feedback that
      // implies an action will follow.
      onTap: null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: c.brandTeal,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: context.typography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.surface0,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Text(
              name,
              style: context.typography.bodyMd.copyWith(color: c.fg1),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: () => context.push('/settings'),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.brandTealTint08,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: context.typography.bodySmallMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.brandTeal,
                ),
              ),
            ),
            // Unread-notification dot hidden until a notifications
            // provider exists (was previously hardcoded `true` so every
            // user always saw an unread indicator).
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Attention strip — coral alert (§3.14)
// ════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════
// Section label — uppercase fg3
// ════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.typography.label.copyWith(color: context.colors.fg3),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2x2 dashboard tile grid (§3.4) — equal-size, responsive
// ════════════════════════════════════════════════════════════
class _TileGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Tighter aspect on small phones (iPhone SE 375pt) so tiles don't get
    // squat; looser on larger phones to keep the number breathing.
    final aspect = screenWidth < 380 ? 1.4 : 1.55;

    final lowStockAsync = ref.watch(lowStockProvider);
    final stockFaibleLabel =
        lowStockAsync.valueOrNull?.length.toString() ?? '—';

    final dashboardAsync = ref.watch(dashboardProvider);
    final dashboard = dashboardAsync.valueOrNull;
    final ordersTodayLabel =
        dashboard?.today.orderCount.toString() ?? '—';
    final profitTodayLabel = dashboard != null
        ? '${MillimesFormatter.format(dashboard.today.realProfit)} TND'
        : '—';

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: context.spacing.space3,
      crossAxisSpacing: context.spacing.space3,
      childAspectRatio: aspect,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _DashboardTile(
          label: 'COMMANDES DU JOUR',
          value: ordersTodayLabel,
          onTap: () => context.go('/orders'),
        ),
        _DashboardTile(
          label: 'BÉNÉFICE DU JOUR',
          value: profitTodayLabel,
          onTap: () => context.go('/stats'),
        ),
        _DashboardTile(
          label: 'STOCK FAIBLE',
          value: stockFaibleLabel,
          onTap: () => context.go('/stock/low'),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.label,
    required this.value,
    this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1),
          borderRadius: BorderRadius.circular(context.radius.radiusTile),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: context.typography.label.copyWith(color: c.fg3),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    style: context.typography.number.copyWith(color: c.fg1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Recent orders card — list preview (§3.5)
// ════════════════════════════════════════════════════════════
class _RecentOrdersCard extends ConsumerWidget {
  const _RecentOrdersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final ordersAsync = ref.watch(orderListProvider);

    Widget shell(Widget child) => Container(
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

    return ordersAsync.when(
      loading: () => shell(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => shell(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Impossible de charger les commandes.',
            style: context.typography.bodySmall.copyWith(color: c.fg3),
          ),
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return shell(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucune commande pour le moment.',
                style: context.typography.bodySmall.copyWith(color: c.fg3),
              ),
            ),
          );
        }
        final preview = orders.take(_recentOrdersOnHome).toList();
        return shell(
          Column(
            children: [
              for (var i = 0; i < preview.length; i++) ...[
                _OrderListItem(
                  order: preview[i],
                  onTap: () => context.push('/orders/${preview[i].id}'),
                ),
                if (i < preview.length - 1)
                  Divider(height: 1, thickness: 1, color: c.border1),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OrderListItem extends StatelessWidget {
  const _OrderListItem({required this.order, required this.onTap});
  final OrderLean order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = order.customerName;
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final badge = _badgeForOrder(order);
    final amount = '${MillimesFormatter.format(order.grossRevenue)} TND';
    final relTime = _relativeTime(order.createdAt);

    return _ScaleTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.brandTealTint08,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: context.typography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.brandTeal,
                ),
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  SizedBox(height: context.spacing.space1),
                  Text(
                    order.orderNumber,
                    style: context.typography.bodySmall.copyWith(color: c.fg3),
                  ),
                  if (badge != null) ...[
                    SizedBox(height: context.spacing.space2),
                    _StatusBadge(kind: badge),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.spacing.space3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: context.typography.bodyMd.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space1),
                Text(
                  relTime,
                  style: context.typography.caption.copyWith(color: c.fg3),
                ),
              ],
            ),
            SizedBox(width: context.spacing.space2),
            Icon(Icons.chevron_right_rounded, size: 16, color: c.fg3),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.kind});
  final _BadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, label) = switch (kind) {
      _BadgeKind.nouvelle => (c.fg1, c.surface0, 'Nouvelle'),
      _BadgeKind.aRelancer => (c.coralTint12, c.coralFg, 'À relancer'),
    };
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
// "Voir tout >" text button
// ════════════════════════════════════════════════════════════
class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.typography.button.copyWith(color: c.fg1),
            ),
            SizedBox(width: context.spacing.space1),
            Icon(Icons.chevron_right_rounded, size: 16, color: c.fg1),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FAB — bottom-right floating (§3.9)
// ════════════════════════════════════════════════════════════
class _HomeFab extends StatelessWidget {
  const _HomeFab();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      pressedScale: 0.96,
      // Quick-log-sale screen doesn't exist; route the FAB to the
      // existing add-order flow instead of the placeholder snackbar.
      onTap: () => context.push('/orders/add'),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: c.fg1,
          shape: BoxShape.circle,
          boxShadow: context.shadows.shadowFab,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add_rounded, color: c.surface0, size: 26),
      ),
    );
  }
}
