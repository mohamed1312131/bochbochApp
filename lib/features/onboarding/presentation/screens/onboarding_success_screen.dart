import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extension.dart';

class OnboardingSuccessScreen extends StatefulWidget {
  const OnboardingSuccessScreen({super.key});

  @override
  State<OnboardingSuccessScreen> createState() =>
      _OnboardingSuccessScreenState();
}

class _OnboardingSuccessScreenState extends State<OnboardingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _redirect;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    HapticFeedback.mediumImpact();

    _redirect = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _redirect?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.surface0,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _ctrl,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: c.greenTint12,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.check_rounded, size: 40, color: c.greenFg),
              ),
            ),
            SizedBox(height: context.spacing.space4),
            Text(
              'Tout est prêt',
              style: context.typography.h1.copyWith(color: c.fg1),
            ),
            SizedBox(height: context.spacing.space2),
            Text(
              'Bienvenue sur DIDO',
              style: context.typography.bodyMd.copyWith(color: c.fg3),
            ),
          ],
        ),
      ),
    );
  }
}
