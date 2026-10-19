import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/order_models.dart';
import '../../domain/partial_fulfill_models.dart';
import 'partial_fulfill_confirm_screen.dart';

/// Screen 1 of the Partial Fulfillment flow (FLUTTER_SPEC §2.7).
///
/// Splits the order into "Prêt à expédier" (in-stock) and "En rupture
/// de stock" (backordered) sections. Shows a contact card for the
/// customer with a channel-colored pill button.
///
///   - Tap "Expédier maintenant (N)" → push confirm screen, which
///     submits SHIP_NOW on its primary CTA.
///   - Tap "Attendre le stock complet" → simply pop. No DB writes.
class PartialFulfillSplitScreen extends ConsumerWidget {
  const PartialFulfillSplitScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.items,
    required this.customer,
  });

  final String orderId;
  final String? orderNumber;
  final List<OrderItem> items;
  final PartialFulfillCustomer? customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final shipped = items.where((i) => !i.isBackorder).toList(growable: false);
    final backordered =
        items.where((i) => i.isBackorder).toList(growable: false);

    return Scaffold(
      backgroundColor: c.surface1,
      appBar: AppBar(title: const Text('Stock partiel')),
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
                Text(
                  'Cette commande contient des articles indisponibles. '
                  'Tu peux expédier maintenant ce qui est en stock '
                  'ou attendre tout le restock.',
                  style: context.typography.body.copyWith(color: c.fg2),
                ),
                SizedBox(height: context.spacing.space5),
                if (shipped.isNotEmpty) ...[
                  _SectionHeader(
                    iconColor: c.greenFg,
                    icon: Icons.check_circle_outline,
                    label: 'Prêt à expédier',
                    count: shipped.length,
                  ),
                  SizedBox(height: context.spacing.space2),
                  _ItemsCard(
                    leftBorderColor: c.greenFg,
                    items: shipped,
                    backorderBadge: false,
                  ),
                  SizedBox(height: context.spacing.space5),
                ],
                if (backordered.isNotEmpty) ...[
                  _SectionHeader(
                    iconColor: c.coralFg,
                    icon: Icons.error_outline,
                    label: 'En rupture de stock',
                    count: backordered.length,
                  ),
                  SizedBox(height: context.spacing.space2),
                  _ItemsCard(
                    leftBorderColor: c.coral,
                    items: backordered,
                    backorderBadge: true,
                  ),
                  SizedBox(height: context.spacing.space5),
                ],
                if (customer != null) ...[
                  Padding(
                    padding: EdgeInsets.only(left: context.spacing.space2),
                    child: Text(
                      'CONTACT CLIENT',
                      style:
                          context.typography.label.copyWith(color: c.fg3),
                    ),
                  ),
                  SizedBox(height: context.spacing.space2),
                  _ContactCard(customer: customer!),
                ],
              ],
            ),
          ),
          _Footer(
            shippedCount: shipped.length,
            backorderedCount: backordered.length,
            onShipNow: shipped.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PartialFulfillConfirmScreen(
                          orderId: orderId,
                          orderNumber: orderNumber,
                          shippedItems: shipped,
                          backorderedItems: backordered,
                        ),
                      ),
                    ),
            onWait: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: iconColor),
        ),
        SizedBox(width: context.spacing.space2),
        Expanded(
          child: Text(
            label,
            style: context.typography.h4.copyWith(color: c.fg1),
          ),
        ),
        Text(
          count > 1 ? '$count articles' : '$count article',
          style: context.typography.bodySmall.copyWith(color: c.fg2),
        ),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.leftBorderColor,
    required this.items,
    required this.backorderBadge,
  });
  final Color leftBorderColor;
  final List<OrderItem> items;
  final bool backorderBadge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border(
          top: BorderSide(color: c.border1),
          right: BorderSide(color: c.border1),
          bottom: BorderSide(color: c.border1),
          left: BorderSide(color: leftBorderColor, width: 3),
        ),
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
            _ItemRow(item: items[i], backorderBadge: backorderBadge),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.backorderBadge});
  final OrderItem item;
  final bool backorderBadge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final variant = item.attributeLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Thumbnail(url: item.primaryImageUrl),
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
                  variant.isEmpty
                      ? 'Qté ${item.quantity}'
                      : '$variant · Qté ${item.quantity}',
                  style: context.typography.bodySmall.copyWith(color: c.fg2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (backorderBadge) ...[
            SizedBox(width: context.spacing.space2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.coralTint12,
                borderRadius: BorderRadius.circular(context.radius.radiusChip),
              ),
              child: Text(
                'Backorder',
                style: context.typography.label.copyWith(color: c.coralFg),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(8),
        image: url != null
            ? DecorationImage(
                image: NetworkImage(url!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: url == null
          ? Icon(Icons.inventory_2_outlined, size: 18, color: c.fg3)
          : null,
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.customer});
  final PartialFulfillCustomer customer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final channelInfo = _channelInfo(context, customer.preferredContactChannel);
    final initials = _initials(customer.name);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.brandTealTint08,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: context.typography.h4.copyWith(color: c.brandTeal),
            ),
          ),
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: context.typography.h4.copyWith(color: c.fg1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  customer.phone != null && customer.phone!.isNotEmpty
                      ? '${customer.phone} · ${channelInfo.label}'
                      : channelInfo.label,
                  style: context.typography.bodySmall.copyWith(color: c.fg2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacing.space2),
          _ChannelPill(info: channelInfo),
        ],
      ),
    );
  }
}

class _ChannelPill extends StatelessWidget {
  const _ChannelPill({required this.info});
  final _ChannelInfo info;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // url_launcher is not in pubspec — stub with a snackbar so we
        // don't add a dependency without consent. v1.x can wire the
        // real deep links: tel:, sms:, https://wa.me/<phone>,
        // https://ig.me/m/<handle>.
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Lien direct bientôt disponible.'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: info.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, size: 16, color: info.fg),
            SizedBox(width: context.spacing.space2),
            Text(
              info.cta,
              style:
                  context.typography.button.copyWith(color: info.fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelInfo {
  const _ChannelInfo({
    required this.label,
    required this.cta,
    required this.icon,
    required this.bg,
    required this.fg,
  });
  final String label;
  final String cta;
  final IconData icon;
  final Color bg;
  final Color fg;
}

_ChannelInfo _channelInfo(BuildContext context, String wire) {
  final c = context.colors;
  switch (wire) {
    case 'WHATSAPP':
      return _ChannelInfo(
        label: 'WhatsApp',
        cta: 'Écrire',
        icon: Icons.chat_outlined,
        bg: c.whatsappGreen,
        fg: c.surface0,
      );
    case 'SMS':
      return _ChannelInfo(
        label: 'SMS',
        cta: 'Envoyer',
        icon: Icons.sms_outlined,
        bg: c.brandTeal,
        fg: c.surface0,
      );
    case 'CALL':
      return _ChannelInfo(
        label: 'Appel',
        cta: 'Appeler',
        icon: Icons.call_outlined,
        bg: c.fg1,
        fg: c.surface0,
      );
    case 'INSTAGRAM':
      return _ChannelInfo(
        label: 'Instagram',
        cta: 'Écrire',
        icon: Icons.camera_alt_outlined,
        bg: c.fg1,
        fg: c.surface0,
      );
    case 'FACEBOOK':
      return _ChannelInfo(
        label: 'Facebook',
        cta: 'Écrire',
        icon: Icons.facebook_outlined,
        bg: c.fg1,
        fg: c.surface0,
      );
    default:
      return _ChannelInfo(
        label: wire,
        cta: 'Contacter',
        icon: Icons.chat_outlined,
        bg: c.brandTeal,
        fg: c.surface0,
      );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.elementAt(1).substring(0, 1))
      .toUpperCase();
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.shippedCount,
    required this.backorderedCount,
    required this.onShipNow,
    required this.onWait,
  });
  final int shippedCount;
  final int backorderedCount;
  final VoidCallback? onShipNow;
  final VoidCallback onWait;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DidoButton.primary(
              label: 'Expédier maintenant ($shippedCount)',
              icon: Icons.local_shipping_outlined,
              enabled: onShipNow != null,
              onPressed: onShipNow,
            ),
            SizedBox(height: context.spacing.space2),
            DidoButton.secondary(
              label: 'Attendre le stock complet',
              onPressed: onWait,
            ),
          ],
        ),
      ),
    );
  }
}
