import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../domain/customer_models.dart';
import 'risk_bottom_sheet.dart';

/// FLUTTER_SPEC §3.1 — pills for RFM segment, risk level, and the
/// preferred contact channel. Rendered as a `Wrap` below the
/// name/phone block on the customer profile.

class RfmBadge extends StatelessWidget {
  const RfmBadge({super.key, required this.segment});
  final RfmSegment segment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (emoji, label, bg, fg) = _styleFor(c, segment);
    return _Pill(
      bg: bg,
      fg: fg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          SizedBox(width: context.spacing.space2),
          Text(
            label,
            style:
                context.typography.button.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  (String, String, Color, Color) _styleFor(dynamic c, RfmSegment s) {
    switch (s) {
      case RfmSegment.champion:
        return ('🏆', 'Champion', c.greenTint12, c.greenFg);
      case RfmSegment.loyal:
        return ('⭐', 'Fidèle', c.greenTint12, c.greenFg);
      case RfmSegment.promising:
        return ('🌱', 'Prometteur', c.brandTealTint08, c.brandTeal);
      case RfmSegment.atRisk:
        return ('⚠️', 'À risque', c.coralTint12, c.coralFg);
      case RfmSegment.dormant:
        return ('💤', 'Dormant', c.surface2, c.fg2);
      case RfmSegment.newCustomer:
        return ('🆕', 'Nouveau', c.surface2, c.fg2);
    }
  }
}

class RiskBadge extends StatelessWidget {
  const RiskBadge({
    super.key,
    required this.customer,
    required this.onTap,
  });
  final CustomerDetail customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (emoji, label, bg, fg) = _styleFor(c, customer.riskLevel);
    // Spec: bold reason text if present; otherwise the level label.
    final text = customer.riskReason?.trim().isNotEmpty == true
        ? customer.riskReason!.trim()
        : 'Risque ${customer.riskLevel.label.toLowerCase()}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: _Pill(
        bg: bg,
        fg: fg,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            SizedBox(width: context.spacing.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.button.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String, Color, Color) _styleFor(dynamic c, RiskLevel r) {
    switch (r) {
      case RiskLevel.green:
        return ('🟢', 'Faible', c.greenTint12, c.greenFg);
      case RiskLevel.yellow:
        return ('🟡', 'Modéré', c.coralTint12, c.coralFg);
      case RiskLevel.red:
        return ('🔴', 'Élevé', c.redTint12, c.redFg);
    }
  }
}

class ChannelPill extends StatelessWidget {
  const ChannelPill({super.key, required this.channel});
  final ContactChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final info = _styleFor(c, channel);
    return InkWell(
      onTap: () {
        // `url_launcher` is not in pubspec (consistent with F7/F9).
        // Stub with a snackbar until we get user consent to add the
        // dependency.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lien direct bientôt disponible.'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(9999),
      child: _Pill(
        bg: c.surface2,
        fg: c.fg1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, size: 14, color: info.iconColor),
            SizedBox(width: context.spacing.space2),
            Text(
              info.label,
              style: context.typography.button.copyWith(color: c.fg1),
            ),
          ],
        ),
      ),
    );
  }

  _ChannelInfo _styleFor(dynamic c, ContactChannel ch) {
    switch (ch) {
      case ContactChannel.whatsapp:
        return _ChannelInfo(
          icon: Icons.chat_outlined,
          iconColor: c.whatsappGreen,
          label: 'WhatsApp',
        );
      case ContactChannel.sms:
        return _ChannelInfo(
          icon: Icons.sms_outlined,
          iconColor: c.brandTeal,
          label: 'SMS',
        );
      case ContactChannel.call:
        return _ChannelInfo(
          icon: Icons.call_outlined,
          iconColor: c.fg1,
          label: 'Appel',
        );
      case ContactChannel.instagramDm:
        return _ChannelInfo(
          icon: Icons.camera_alt_outlined,
          iconColor: c.fg1,
          label: 'Instagram DM',
        );
      case ContactChannel.facebookDm:
        return _ChannelInfo(
          icon: Icons.facebook_outlined,
          iconColor: c.fg1,
          label: 'Facebook DM',
        );
    }
  }
}

class _ChannelInfo {
  const _ChannelInfo({
    required this.icon,
    required this.iconColor,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
}

/// Helper: open the risk bottom sheet for a customer.
Future<void> openRiskSheet({
  required BuildContext context,
  required CustomerDetail customer,
}) {
  return showRiskBottomSheet(context: context, customer: customer);
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.bg,
    required this.fg,
    required this.child,
  });
  final Color bg;
  final Color fg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: child,
    );
  }
}
