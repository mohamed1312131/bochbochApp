import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_scale_tap.dart';

/// List row — UX_DESIGN_SYSTEM_V1.1.md §3.5.
///
/// Single source for the list-item row pattern (settings rows,
/// customer rows, item rows). Optional thumb leading widget, up to
/// three text lines on the left, optional trailing price + chevron
/// on the right. Bottom border is on by default — pass
/// `showBottomBorder: false` for the last row in a card so the
/// card's own border isn't doubled.
class DidoListRow extends StatelessWidget {
  const DidoListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.sub2,
    this.leading,
    this.trailingText,
    this.trailingTextStyle,
    this.showChevron = false,
    this.onTap,
    this.showBottomBorder = true,
  });

  final String title;
  final String? subtitle;
  final String? sub2;
  final Widget? leading;
  final String? trailingText;
  final TextStyle? trailingTextStyle;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: showBottomBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.border1, width: 1),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.h4.copyWith(color: c.fg1),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.bodySmall
                        .copyWith(color: c.fg3),
                  ),
                ],
                if (sub2 != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub2!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        context.typography.caption.copyWith(color: c.fg3),
                  ),
                ],
              ],
            ),
          ),
          if (trailingText != null) ...[
            const SizedBox(width: 8),
            Text(
              trailingText!,
              style: (trailingTextStyle ?? context.typography.bodyMdNum)
                  .copyWith(color: c.fg1),
            ),
          ],
          if (showChevron) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 16, color: c.fg3),
          ],
        ],
      ),
    );

    if (onTap == null) return body;
    return DidoScaleTap(onTap: onTap, child: body);
  }
}
