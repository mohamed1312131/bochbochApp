import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_scale_tap.dart';

/// Coral attention strip — UX_DESIGN_SYSTEM_V1.1.md §5.1.
///
/// Replaces the inlined `_AttentionStrip` on home_screen.dart. Coral
/// tint background with a leading dot, primary message + optional
/// subtitle, and a trailing action label + chevron. Tap fires
/// [onTap].
class DidoAttentionStrip extends StatelessWidget {
  const DidoAttentionStrip({
    super.key,
    required this.title,
    this.actionLabel,
    this.onTap,
    this.subtitle,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasAction = actionLabel != null;
    return DidoScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: c.coralTint12,
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c.coral,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        context.typography.bodyMd.copyWith(color: c.fg1),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: context.typography.bodySmall
                          .copyWith(color: c.fg3),
                    ),
                  ],
                ],
              ),
            ),
            if (hasAction) ...[
              const SizedBox(width: 12),
              Text(
                actionLabel!,
                style: context.typography.button.copyWith(color: c.coralFg),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: c.coralFg),
            ],
          ],
        ),
      ),
    );
  }
}
