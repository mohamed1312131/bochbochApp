import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_scale_tap.dart';

/// Segmented control — UX_DESIGN_SYSTEM_V1.1.md §3.6 (control variant).
///
/// Typical use: 2-segment "Retirer / Ajouter" toggle on stock
/// adjust sheets. Active segment gets a surface-1 thumb with a tiny
/// drop shadow ([AppShadows.shadowSegmentedThumb]); inactive
/// segments are flat over the surface-2 outer track.
class DidoSegmented extends StatelessWidget {
  const DidoSegmented({
    super.key,
    required this.segments,
    required this.activeIndex,
    required this.onSegmentTap,
  });

  final List<String> segments;
  final int activeIndex;
  final ValueChanged<int> onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(context.radius.radiusFull),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: _Segment(
                label: segments[i],
                active: i == activeIndex,
                onTap: () => onSegmentTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: onTap,
      scale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 36,
        decoration: BoxDecoration(
          color: active ? c.surface1 : Colors.transparent,
          borderRadius: BorderRadius.circular(context.radius.radiusFull),
          boxShadow: active
              ? context.shadows.shadowSegmentedThumb
              : const <BoxShadow>[],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.typography.smallMd
              .copyWith(color: active ? c.fg1 : c.fg3),
        ),
      ),
    );
  }
}
