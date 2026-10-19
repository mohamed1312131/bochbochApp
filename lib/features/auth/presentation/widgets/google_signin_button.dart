import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../core/theme/app_theme_extension.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Brand(Brands.google, size: 20),
        label: Text(
          'Continuer avec Google',
          style: context.typography.button.copyWith(
            color: c.fg1,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surface1,
          side: BorderSide(color: c.border1, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(context.radius.radiusInput),
          ),
        ),
      ),
    );
  }
}
