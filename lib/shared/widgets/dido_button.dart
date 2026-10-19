import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme_extension.dart';

enum _DidoButtonVariant { primary, secondary, destructive }

/// DIDO primary action button — UX_DESIGN_SYSTEM_V1.1.md §3.1, §3.2, §3.3.
///
/// Three variants, all token-driven:
/// - `.primary`     — `fg-1` bg, `surface-0` text, no border. The single
///                    primary action per screen (Rule 6).
/// - `.secondary`   — `surface-1` bg, `fg-1` text, 1px `border-1` border.
/// - `.destructive` — `red` bg, `surface-0` text. Reserved for confirmed
///                    destructive operations (delete, cancel order).
///
/// All buttons use 8px radius (`radius-input`), 48px min height, and the
/// scale + haptic press feedback from §6.3 — no Material InkWell ripple.
class DidoButton extends StatefulWidget {
  const DidoButton._({
    super.key,
    required this.label,
    required this.onPressed,
    required _DidoButtonVariant variant,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.enabled = true,
  }) : _variant = variant;

  const DidoButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool fullWidth = true,
    bool enabled = true,
  }) : this._(
          key: key,
          label: label,
          onPressed: onPressed,
          variant: _DidoButtonVariant.primary,
          icon: icon,
          loading: loading,
          fullWidth: fullWidth,
          enabled: enabled,
        );

  const DidoButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool fullWidth = true,
    bool enabled = true,
  }) : this._(
          key: key,
          label: label,
          onPressed: onPressed,
          variant: _DidoButtonVariant.secondary,
          icon: icon,
          loading: loading,
          fullWidth: fullWidth,
          enabled: enabled,
        );

  const DidoButton.destructive({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
    bool fullWidth = true,
    bool enabled = true,
  }) : this._(
          key: key,
          label: label,
          onPressed: onPressed,
          variant: _DidoButtonVariant.destructive,
          icon: icon,
          loading: loading,
          fullWidth: fullWidth,
          enabled: enabled,
        );

  final String label;
  final VoidCallback? onPressed;
  final _DidoButtonVariant _variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final bool enabled;

  @override
  State<DidoButton> createState() => _DidoButtonState();
}

class _DidoButtonState extends State<DidoButton> {
  bool _pressed = false;

  /// Taps fire only when explicitly enabled, not loading, and a real
  /// callback was provided.
  bool get _isInteractive =>
      widget.enabled && !widget.loading && widget.onPressed != null;

  /// Use disabled colors only when explicitly disabled AND not loading.
  /// Loading-with-disabled keeps the enabled colors (spinner takes priority
  /// per the spec — the user should see active styling under the spinner).
  bool get _useDisabledColors => !widget.enabled && !widget.loading;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  _Scheme _resolveScheme(BuildContext context) {
    final c = context.colors;
    switch (widget._variant) {
      case _DidoButtonVariant.primary:
        return _Scheme(
          background: c.fg1,
          foreground: c.surface0,
          border: null,
          spinner: c.surface0,
          disabledBackground: c.fg4,
          disabledForeground: c.surface0,
        );
      case _DidoButtonVariant.secondary:
        return _Scheme(
          background: c.surface1,
          foreground: c.fg1,
          border: c.border1,
          spinner: c.fg1,
          disabledBackground: c.surface1,
          disabledForeground: c.fg4,
        );
      case _DidoButtonVariant.destructive:
        return _Scheme(
          background: c.red,
          foreground: c.surface0,
          border: null,
          spinner: c.surface0,
          disabledBackground: c.fg4,
          disabledForeground: c.surface0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _resolveScheme(context);
    final bg = _useDisabledColors ? scheme.disabledBackground : scheme.background;
    final fg = _useDisabledColors ? scheme.disabledForeground : scheme.foreground;
    final radius = BorderRadius.circular(context.radius.radiusInput);

    final content = widget.loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.spinner,
            ),
          )
        : Row(
            mainAxisSize:
                widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: fg),
                SizedBox(width: context.spacing.space2),
              ],
              Text(
                widget.label,
                style: context.typography.button.copyWith(color: fg),
              ),
            ],
          );

    final body = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: scheme.border == null
            ? null
            : Border.all(color: scheme.border!, width: 1),
      ),
      alignment: Alignment.center,
      child: content,
    );

    final scaled = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: context.motion.tap,
      curve: context.motion.easeOut,
      child: body,
    );

    final sized =
        widget.fullWidth ? SizedBox(width: double.infinity, child: scaled) : scaled;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _isInteractive
          ? (_) {
              _setPressed(true);
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: _isInteractive
          ? (_) {
              _setPressed(false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _setPressed(false),
      child: sized,
    );
  }
}

class _Scheme {
  const _Scheme({
    required this.background,
    required this.foreground,
    required this.border,
    required this.spinner,
    required this.disabledBackground,
    required this.disabledForeground,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final Color spinner;
  final Color disabledBackground;
  final Color disabledForeground;
}
