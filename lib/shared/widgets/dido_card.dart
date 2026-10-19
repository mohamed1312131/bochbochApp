import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_scale_tap.dart';

/// Bordered surface card — UX_DESIGN_SYSTEM_V1.1.md §3.5.
///
/// Single source for the bordered-card pattern previously inlined
/// across customer / order / settings / stats screens. Always
/// bordered, never elevated — v1.1 §2.5 forbids decorative shadow.
///
/// Pass `onTap` to wrap the card in [DidoScaleTap] press feedback.
class DidoCard extends StatelessWidget {
  const DidoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? c.surface1,
        border: Border.all(color: borderColor ?? c.border1, width: 1),
        borderRadius:
            BorderRadius.circular(radius ?? context.radius.radiusCard),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return DidoScaleTap(onTap: onTap, child: card);
  }
}
