import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Brand(Brands.google, size: 20),
        label: Text(
          'Continuer avec Google',
          style: AppTypography.bodyLarge.copyWith(
            color: context.appBrand,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: context.appSurface,
          side: BorderSide(color: context.appBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
