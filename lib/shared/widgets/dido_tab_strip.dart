import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_scale_tap.dart';

/// Underline tab strip — UX_DESIGN_SYSTEM_V1.1.md §3.4.
///
/// Replaces the ad-hoc tab strip implementations in orders list /
/// stats / customer detail. Each tab is independent (no shared
/// underline rail) — color crossfade between tabs gives a clean
/// transition without needing widget-tree measurement. A true
/// position-slide would require GlobalKeys per tab and a single
/// Positioned underline; current approach is the simplest option
/// listed in the task spec.
class DidoTabStrip extends StatelessWidget {
  const DidoTabStrip({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabTap,
    this.underlineColor,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabTap;
  final Color? underlineColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final activeColor = underlineColor ?? c.fg1;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border1, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            _Tab(
              label: tabs[i],
              active: i == activeIndex,
              activeColor: activeColor,
              onTap: () => onTabTap(i),
            ),
            if (i != tabs.length - 1) const SizedBox(width: 24),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              style: context.typography.tab.copyWith(
                color: active ? c.fg1 : c.fg3,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 2,
            width: _approxLabelWidth(label, context),
            color: active ? activeColor : Colors.transparent,
          ),
        ],
      ),
    );
  }

  /// Rough width estimate so the underline matches the rendered label.
  /// Uses tab typography fontSize as the per-glyph multiplier — close
  /// enough for Inter at 15/500 across French tab labels.
  double _approxLabelWidth(String label, BuildContext context) {
    final fontSize = context.typography.tab.fontSize ?? 15;
    return label.length * (fontSize * 0.55);
  }
}
