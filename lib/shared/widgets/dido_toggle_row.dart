import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_toggle.dart';

/// Single row inside a "Statut du client"-style settings card.
///
/// Layout: title (titleSm) on top, optional sub line (bodySmall, fg3)
/// below; trailing [DidoToggle] on the right. 14/16 padding.
///
/// When [destructive] is true AND [value] is true, the row paints
/// with the red surface tint to signal an active blocking state
/// (NEW_FEATURES_SPEC §3.4 — "Bloquer ce client").
class DidoToggleRow extends StatelessWidget {
  const DidoToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
    this.subWhenOn,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? sub;
  final String? subWhenOn;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDestructiveOn = destructive && value;
    final bg = isDestructiveOn ? c.redTint12 : Colors.transparent;
    final labelColor = isDestructiveOn ? c.redFg : c.fg1;
    final subColor = isDestructiveOn ? c.redFg : c.fg3;

    // When ON, prefer the [subWhenOn] copy (e.g. "Commandes bloquées")
    // over the always-visible [sub]. Spec §3.4 uses this for the
    // destructive ON state.
    final activeSub =
        value && subWhenOn != null ? subWhenOn : sub;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.typography.h4.copyWith(color: labelColor),
                ),
                if (activeSub != null && activeSub.isNotEmpty) ...[
                  SizedBox(height: context.spacing.space1),
                  Text(
                    activeSub,
                    style: context.typography.bodySmall.copyWith(
                      color: subColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.spacing.space3),
          DidoToggle(
            value: value,
            onChanged: enabled ? onChanged : (_) {},
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
