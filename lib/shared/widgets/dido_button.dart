import 'package:flutter/material.dart';
import '../../core/constants/app_border_radius.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme_extension.dart';

enum _DidoButtonVariant { primary, secondary, destructive }

class DidoButton extends StatelessWidget {
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

  bool get _isInteractive => enabled && !loading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final scheme = _resolveScheme(context);
    final effectiveBg = _isInteractive
        ? scheme.background
        : scheme.background.withValues(alpha: 0.5);
    final effectiveFg = _isInteractive
        ? scheme.foreground
        : scheme.foreground.withValues(alpha: 0.5);
    final effectiveBorder = scheme.border == null
        ? null
        : (_isInteractive
            ? scheme.border!
            : scheme.border!.withValues(alpha: 0.5));

    final radius = BorderRadius.circular(AppRadius.lg);

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.spinner,
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: effectiveFg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: effectiveFg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final body = Material(
      color: effectiveBg,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: effectiveBorder == null
            ? BorderSide.none
            : BorderSide(color: effectiveBorder, width: 1.5),
      ),
      child: InkWell(
        onTap: _isInteractive ? onPressed : null,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(height: 52, child: Center(child: child)),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: body) : body;
  }

  _Scheme _resolveScheme(BuildContext context) {
    switch (_variant) {
      case _DidoButtonVariant.primary:
        return _Scheme(
          background: context.appBrand,
          foreground: AppColors.white,
          border: null,
          spinner: AppColors.white,
        );
      case _DidoButtonVariant.secondary:
        return _Scheme(
          background: Colors.transparent,
          foreground: context.appTextPrimary,
          border: context.appBorder,
          spinner: context.appBrand,
        );
      case _DidoButtonVariant.destructive:
        return _Scheme(
          background: AppColors.error,
          foreground: AppColors.white,
          border: null,
          spinner: AppColors.white,
        );
    }
  }
}

class _Scheme {
  const _Scheme({
    required this.background,
    required this.foreground,
    required this.border,
    required this.spinner,
  });
  final Color background;
  final Color foreground;
  final Color? border;
  final Color spinner;
}
