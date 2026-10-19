import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme_extension.dart';

/// Custom toggle switch — UX_DESIGN_SYSTEM_V1.1.md §3.6 (control variant).
///
/// Replaces Material/Cupertino switches with a fully token-driven
/// implementation. Track 44×26, thumb 20×20 with [AppShadows.shadowToggle].
/// Off track is `border2`; on track is `fg1` — no teal in the on-state
/// per v1.1 (teal is logo-only).
class DidoToggle extends StatelessWidget {
  const DidoToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final trackColor = value ? c.fg1 : c.border2;

    final widget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onChanged(!value);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(context.radius.radiusFull),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              top: 3,
              left: value ? 21 : 3,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: c.surface1,
                  shape: BoxShape.circle,
                  boxShadow: context.shadows.shadowToggle,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: widget,
    );
  }
}
