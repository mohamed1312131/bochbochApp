import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tap feedback wrapper — UX_DESIGN_SYSTEM_V1.1.md §6.3.
///
/// Replaces the `_ScaleTap` private widget that was previously inlined
/// across every screen. Single source for the press feedback pattern:
/// scale-down on press, scale-up on release, optional haptic on tap-down.
///
/// Pass `onTap: null` to render the child without any interaction (no
/// gesture detector, no scale animation, no haptic).
class DidoScaleTap extends StatefulWidget {
  const DidoScaleTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 80),
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final bool enableHaptics;
  final HitTestBehavior behavior;

  @override
  State<DidoScaleTap> createState() => _DidoScaleTapState();
}

class _DidoScaleTapState extends State<DidoScaleTap> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) {
        _set(true);
        if (widget.enableHaptics) HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _set(false);
        widget.onTap!();
      },
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
