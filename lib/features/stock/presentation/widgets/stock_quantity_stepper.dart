import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';

/// Quantity stepper — FLUTTER_SPEC §6.3.
///
/// `[ - ][   value   ][ + ]` row at 44px height. Stateful so the
/// minus/plus buttons can self-disable at [min] / [max] without the
/// caller having to recompute the bounds — but the value itself is
/// owned by the parent and propagated via [onChanged].
class StockQuantityStepper extends StatefulWidget {
  const StockQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.enabled = true,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;
  final bool enabled;

  /// When `true`, the stepper sizes to its content (44+gap+56+gap+44 ≈
  /// 168 px) instead of expanding to fill its parent. Use inside Rows
  /// where the stepper should sit alongside other widgets.
  final bool compact;

  @override
  State<StockQuantityStepper> createState() => _StockQuantityStepperState();
}

class _StockQuantityStepperState extends State<StockQuantityStepper> {
  bool get _canDecrement =>
      widget.enabled && widget.value > widget.min;

  bool get _canIncrement =>
      widget.enabled && (widget.max == null || widget.value < widget.max!);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _StepButton(
        icon: Icons.remove,
        enabled: _canDecrement,
        onTap: _canDecrement
            ? () => widget.onChanged(widget.value - 1)
            : null,
      ),
      const SizedBox(width: 12),
      widget.compact
          ? SizedBox(width: 56, child: _ValueDisplay(value: widget.value))
          : Expanded(child: _ValueDisplay(value: widget.value)),
      const SizedBox(width: 12),
      _StepButton(
        icon: Icons.add,
        enabled: _canIncrement,
        onTap: _canIncrement
            ? () => widget.onChanged(widget.value + 1)
            : null,
      ),
    ];

    return SizedBox(
      height: 44,
      child: widget.compact
          ? Row(mainAxisSize: MainAxisSize.min, children: children)
          : Row(children: children),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = enabled ? c.surface1 : c.surface2;
    final iconColor = enabled ? c.fg1 : c.fg4;

    return DidoScaleTap(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: c.border1, width: 1),
          borderRadius:
              BorderRadius.circular(context.radius.radiusInput),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

class _ValueDisplay extends StatelessWidget {
  const _ValueDisplay({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1, width: 1),
        borderRadius: BorderRadius.circular(context.radius.radiusInput),
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: context.typography.bodyMd.copyWith(
          color: c.fg1,
          fontSize: 17,
          height: 22 / 17,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
